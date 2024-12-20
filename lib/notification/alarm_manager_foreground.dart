import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:workmanager/workmanager.dart';
import '../utils/helper.dart';
import '../utils/partialWakeLock.dart';

String _formatTime(int seconds) {
  final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
  final secs = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$secs';
}

class PomodoroAlarmManager {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isPaused = false;
  DateTime? _alarmTime;
  final int _notificationId = 0;
  Timer? timer;
  final CountDownController _clockController = CountDownController();

  PomodoroAlarmManager() {
    _initialize();
  }

  Future<void> _initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification clicked with payload: ${response.payload}');
        if (response.payload == 'alarm') {
          _handleAlarm();
        }
      },
    );

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Pomodoro Timer',
        channelDescription: 'Timer running in the background',
        onlyAlertOnce: true,
        playSound: false,
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  Future<void> startForegroundTask(DateTime alarmTime) async {
    if (await FlutterForegroundTask.isRunningService) {
      debugPrint('Foreground task is already running.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alarm_time', alarmTime.toIso8601String());

    FlutterForegroundTask.startService(
      notificationTitle: 'Pomodoro Timer',
      notificationText: 'Time left: ${_formatTime(alarmTime.difference(DateTime.now()).inSeconds)}',
      callback: _foregroundTaskCallback,
    );
    debugPrint('WorkManager: Time left for alarm: ${_formatTime(alarmTime.difference(DateTime.now()).inSeconds)}');
  }

  Future<void> stopForegroundTask() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
      debugPrint('Foreground task stopped.');
    }
  }

  Future<void> schedulePomodoroAlarm({
    required int durationInSeconds,
    String alarmTitle = 'Pomodoro Complete',
    String alarmBody = 'Time to take a break!',
  }) async {
    _alarmTime = DateTime.now().add(Duration(seconds: durationInSeconds));

    await _saveAlarmTime(_alarmTime!);

    await flutterLocalNotificationsPlugin.cancel(_notificationId);

    const androidDetails = AndroidNotificationDetails(
      'pomodoro_channel_id',
      'Pomodoro Notifications',
      channelDescription: 'Notifications for Pomodoro timer completion',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification'),
      playSound: true,
      silent: false,
    );

    const platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      _notificationId,
      alarmTitle,
      alarmBody,
      tz.TZDateTime.from(_alarmTime!, tz.local),
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'alarm',
    );

    await startForegroundTask(_alarmTime!);
  }

  Future<void> cancelPomodoroAlarm() async {
    _alarmTime = null;
    _isPaused = false;
    await stopForegroundTask();

    if (await Vibration.hasVibrator() == true) {
      Vibration.cancel();
    }

    await flutterLocalNotificationsPlugin.cancel(_notificationId);
    await _clearAlarmTime();
    stopTimer();
    WakeLockManager.releaseWakeLock();
  }

  Future<void> _handleAlarm() async {
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(pattern: [0, 1000, 500, 1000]);
    }
    await stopForegroundTask();
  }

  Future<void> _saveAlarmTime(DateTime alarmTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("alarm_time", alarmTime.toIso8601String());
  }

  Future<void> _clearAlarmTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("alarm_time");
  }

  static void _foregroundTaskCallback() {
    FlutterForegroundTask.setTaskHandler(_PomodoroTaskHandler());
  }

  void startTimer(CountDownController userClockController) async {
    timer?.cancel();

    final prefs = await SharedPreferences.getInstance();
    String? alarmTimeStr = prefs.getString('alarm_time');

    if (alarmTimeStr != null) {
      _alarmTime = DateTime.parse(alarmTimeStr);
      final remainingTime = _alarmTime!.difference(DateTime.now()).inSeconds;
      if (remainingTime > 0) {
        Workmanager().registerPeriodicTask(
          "pomodoro_timer_task",
          "pomodoro_timer",
          frequency: const Duration(minutes: 15),
          existingWorkPolicy: ExistingWorkPolicy.replace,
        );
        debugPrint('WorkManagerCallBack: Alarm time $alarmTimeStr');
      } else {
        debugPrint('Alarm time is in the past.');
      }
    } else {
      debugPrint('No alarm time found.');
    }

    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final now = DateTime.now();
      final remainingTime = _alarmTime!.difference(now).inSeconds;

      if (remainingTime > 0) {
        checkAndUpdateClockController(remainingTime, userClockController);
        final updatedMinutes = remainingTime ~/ 60;
        final updatedSeconds = remainingTime % 60;

        final formattedTime = '${updatedMinutes.toString().padLeft(2, '0')}:${updatedSeconds.toString().padLeft(2, '0')}';

        // Update notification
        await updateNotification('Time Remaining: $formattedTime');

        if (userClockController.isPaused.value) {
          timer.cancel(); // Stop the timer if it's paused
          debugPrint("Timer paused by user.");
          return; // Exit early from the periodic callback
        }
      } else {
        // Time has ended
        timer.cancel();
        await flutterLocalNotificationsPlugin.cancel(1);
        FlutterForegroundTask.stopService();
      }
    });
  }

  void checkAndUpdateClockController(int remainingTime, CountDownController userClockController) {
    final int remainingTimeInSeconds = parseTimeStringToSeconds(userClockController.getTime());
    final currentSeconds = remainingTimeInSeconds;

    if ((currentSeconds - remainingTime).abs() > 2) {
      userClockController.restart(duration: remainingTime);
      debugPrint("ClockController updated with remaining time: $remainingTime seconds");
    }
  }

  Future<void> updateNotification(String message) async {
    const androidDetails = AndroidNotificationDetails(
      'timer_channel',
      'Timer Notifications',
      channelDescription: 'Updates for the countdown timer',
      importance: Importance.max,
      priority: Priority.high,
      onlyAlertOnce: false,
      silent: true,
      enableVibration: false,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      1, // Notification ID
      'Pomodoro Timer',
      message,
      notificationDetails,
    );
  }

  void stopTimer() async {
    await Workmanager().cancelByUniqueName("pomodoro_timer_task");

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('alarm_time');
    timer?.cancel();
    await flutterLocalNotificationsPlugin.cancel(1);
    FlutterForegroundTask.stopService();
  }
}

class _PomodoroTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final prefs = await SharedPreferences.getInstance();
    String? alarmTimeStr = prefs.getString('alarm_time');
    if (alarmTimeStr != null) {
      DateTime alarmTime = DateTime.parse(alarmTimeStr);
      int remainingTime = alarmTime.difference(DateTime.now()).inSeconds;
      FlutterForegroundTask.updateService(
        notificationTitle: 'Pomodoro Timer',
        notificationText: 'Time left: ${_formatTime(remainingTime)}',
      );
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    String? alarmTimeStr = prefs.getString('alarm_time');
    if (alarmTimeStr != null) {
      DateTime alarmTime = DateTime.parse(alarmTimeStr);
      int remainingTime = alarmTime.difference(DateTime.now()).inSeconds;

      if (remainingTime > 0) {
        prefs.setString('alarm_time', alarmTime.toIso8601String());
        FlutterForegroundTask.updateService(
          notificationTitle: 'Pomodoro Timer',
          notificationText: 'Time left: ${_formatTime(remainingTime)}',
        );
      } else {
        FlutterForegroundTask.stopService();
      }
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}

  @override
  void onReceiveData(Object data) {}
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("Background task executed: $task");
    final prefs = await SharedPreferences.getInstance();
    String? alarmTimeStr = prefs.getString('alarm_time');
    if (alarmTimeStr != null) {
      DateTime alarmTime = DateTime.parse(alarmTimeStr);
      int remainingTime = alarmTime.difference(DateTime.now()).inSeconds;

      if (remainingTime > 0) {
        prefs.setString('alarm_time', alarmTime.toIso8601String());
        FlutterForegroundTask.updateService(
          notificationTitle: 'Pomodoro Timer',
          notificationText: 'Time left: ${_formatTime(remainingTime)}',
        );
      } else {
        debugPrint("Pomodoro timer stopped.");
        await FlutterForegroundTask.stopService();
      }
    }
    return Future.value(true);
  });
}
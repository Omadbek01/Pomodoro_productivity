import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import '../utils/helper.dart';
import 'package:workmanager/workmanager.dart';


class PomodoroAlarmManager {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  bool _isPaused = false;
  int? _remainingTime; // Remaining time in seconds when paused
  int? _originalDuration; // Original duration of the timer
  int _notificationId = 0; // Unique ID for each notification
  Timer? timer;
  final CountDownController _clockController = CountDownController();

  PomodoroAlarmManager() {
    _initialize();
  }

  Future<void> _initialize() async {
    tz.initializeTimeZones();

    // Android and iOS initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        print('Notification clicked with payload: ${response.payload}');
        if (response.payload == 'alarm') {
          _handleAlarm();
        }
      },
    );

    // Initialize Flutter Foreground Task
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
        eventAction: ForegroundTaskEventAction.repeat(1000), // 1-second interval
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    debugPrint('Flutter foreground task initialized.');
  }

  Future<void> startForegroundTask(int durationInSeconds) async {
    if (await FlutterForegroundTask.isRunningService) {
      print('Foreground task is already running.');
      return;
    }

    // Save remaining time to SharedPreferences for the background handler
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('remaining_time', durationInSeconds);

    debugPrint('Flutter Foreground TASK Checkpoint.');
    FlutterForegroundTask.startService(
      notificationTitle: 'Pomodoro Timer',
      notificationText: 'Time left: ${_formatTime(durationInSeconds)}',
      callback: () {
        debugPrint('Foreground task callback is about to be invoked.');
        _foregroundTaskCallback();
      },
    );
    debugPrint('Flutter foreground task has started.');
  }

  Future<void> stopForegroundTask() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
      print('Foreground task stopped.');
    }
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  Future<void> schedulePomodoroAlarm({
    required int durationInSeconds,
    String alarmTitle = 'Pomodoro Complete',
    String alarmBody = 'Time to take a break!',
  }) async {
    _originalDuration = durationInSeconds;
    _remainingTime = durationInSeconds;

    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = now.add(Duration(seconds: durationInSeconds));
    await _saveAlarmTime(scheduledTime);
    flutterLocalNotificationsPlugin.cancel(_notificationId);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'pomodoro_channel_id',
      'Pomodoro Notifications',
      channelDescription: 'Notifications for Pomodoro timer completion',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification'),
      playSound: true,
      silent: false,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      _notificationId,
      alarmTitle,
      alarmBody,
      scheduledTime,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'alarm',
    );


    await startForegroundTask(durationInSeconds);

    print('Pomodoro alarm scheduled for: $scheduledTime');
  }

  Future<void> cancelPomodoroAlarm() async {
    _remainingTime = null;
    _originalDuration = null;
    _isPaused = false;
    await stopForegroundTask();
    if (await Vibration.hasVibrator() == true) {
      Vibration.cancel();
    }
    await flutterLocalNotificationsPlugin.cancel(_notificationId);
    await _clearAlarmTime();
    stopTimer();
    print('Pomodoro alarm reset.');
  }

  Future<void> _handleAlarm() async {
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(pattern: [0, 1000, 500, 1000]);
    }
    await stopForegroundTask();
  }

  Future<void> _saveAlarmTime(DateTime alarmTime) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("alarmTime", alarmTime.toIso8601String());
    print('Alarm time saved: $alarmTime');
  }

  Future<void> _clearAlarmTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("alarmTime");
    print('Alarm time cleared.');
  }

  static void _foregroundTaskCallback() {
    debugPrint('Foreground task callback invoked.');
    FlutterForegroundTask.setTaskHandler(_PomodoroTaskHandler());
  }

  Future<void> startForegroundService(CountDownController clockController) async {
    startTimer(clockController);
    // Configure the foreground service
    await FlutterForegroundTask.startService(
      notificationTitle: 'Countdown Timer',
      notificationText: 'Timer is running...',
    );
  }

  void startTimer(CountDownController clockController) {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {


      var remainingTimeStr = clockController.getTime() ?? '00:00';

      // Handle cases where the format is just seconds (e.g., "59")
      if (!remainingTimeStr.contains(':')) {
        remainingTimeStr = '00:$remainingTimeStr';
      }

      final parts = remainingTimeStr.split(':');
      if (parts.length == 2) {
        final minutes = int.tryParse(parts[0]) ?? 0;
        final seconds = int.tryParse(parts[1]) ?? 0;
        var remainingTime = minutes * 60 + seconds;

        if (remainingTime > 0) {

          // Recalculate minutes and seconds
          final updatedMinutes = remainingTime ~/ 60;
          final updatedSeconds = remainingTime % 60;

          final formattedTime =
              '${updatedMinutes.toString().padLeft(2, '0')}:${updatedSeconds.toString().padLeft(2, '0')}';

          // Update notification
          await updateNotification('Time Remaining: $formattedTime');

          if (clockController.isPaused) {
            timer.cancel(); // Stop the timer if it's paused
            debugPrint("Timer paused by user.");
            return; // Exit early from the periodic callback
          }
        } else {
          // Time has ended
          timer.cancel();
          FlutterForegroundTask.stopService();
        }
      } else {
        // Invalid time format
        debugPrint('Invalid time format: $remainingTimeStr');
        timer.cancel();
      }
    });
  }

  Future<void> updateNotification(String message) async {
    const androidDetails = AndroidNotificationDetails(
      'timer_channel',
      'Timer Notifications',
      channelDescription: 'Updates for the countdown timer',
      importance: Importance.max,
      priority: Priority.high,
      onlyAlertOnce: true,
      silent: true,
      enableVibration: false,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      1, // Notification ID
      'Countdown Timer',
      message,
      notificationDetails,
    );
  }

  void stopTimer() async {
    //await flutterLocalNotificationsPlugin.cancel(1);
    timer?.cancel();
    FlutterForegroundTask.stopService();
  }

}

class _PomodoroTaskHandler extends TaskHandler {
  int remainingTime = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    remainingTime = prefs.getInt('remaining_time') ?? 0;
    debugPrint('Foreground task started.');
  }

  @override
  void onRepeatEvent(DateTime timestamp) async
  {
    debugPrint('Repeat event triggered at: ${timestamp.toIso8601String()}');
    if (remainingTime > 0) {
      remainingTime--;
      FlutterForegroundTask.updateService(
        notificationTitle: 'Pomodoro Timer',
        notificationText: 'Time left: ${_formatTime(remainingTime)}',
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setInt('remaining_time', remainingTime);
      debugPrint('Remaining time after decrement: $remainingTime');
    } else {
      debugPrint('Timer completed. Stopping service.');
      FlutterForegroundTask.stopService();
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('Foreground task destroyed.');
  }

  @override
  void onReceiveData(Object data) {}

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }
}

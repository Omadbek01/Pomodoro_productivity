import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class PomodoroAlarmManager {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  bool _isPaused = false;
  int? _remainingTime; // Remaining time in seconds when paused
  int? _originalDuration; // Original duration of the timer
  int _notificationId = 0; // Unique ID for each notification

  PomodoroAlarmManager() {
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize Timezone and Notifications
    tz.initializeTimeZones();

    // Android and iOS initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    // Initialize the notification plugin
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
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    debugPrint('Flutter foreground task initialized.');
  }

  Future<void> startForegroundTask() async {
    if (await FlutterForegroundTask.isRunningService) {
      print('Foreground task is already running.');
      return;
    }

    await FlutterForegroundTask.startService(
      notificationTitle: 'Pomodoro Timer',
      notificationText: 'Timer is running...',
      callback: _foregroundTaskCallback,
    );
    debugPrint('Flutter foreground task has started.');
  }

  Future<void> stopForegroundTask() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
      print('Foreground task stopped.');
    }
  }

  Future<void> schedulePomodoroAlarm({
    required int durationInSeconds,
    String alarmTitle = 'Pomodoro Complete',
    String alarmBody = 'Time to take a break!',
  }) async {
    // Store original duration
    _originalDuration = durationInSeconds;
    _remainingTime = durationInSeconds;

    // Calculate and save alarm time
    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = now.add(Duration(seconds: durationInSeconds));
    await _saveAlarmTime(scheduledTime);

    // Notification details
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'pomodoro_channel_id',
      'Pomodoro Notifications',
      channelDescription: 'Notifications for Pomodoro timer completion',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification'),
      playSound: true,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    // Schedule the notification
    await flutterLocalNotificationsPlugin.zonedSchedule(
      _notificationId,
      alarmTitle,
      alarmBody,
      scheduledTime,
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'alarm', // Payload to identify the notification callback
    );

    // Start the foreground service
    await startForegroundTask();

    print('Pomodoro alarm scheduled for: $scheduledTime');
  }

  Future<void> cancelPomodoroAlarm() async {
    // Cancel the current notification and reset the timer
    _remainingTime = null;
    _originalDuration = null;
    _isPaused = false;
    await stopForegroundTask();
    if (await Vibration.hasVibrator() == true) {
      Vibration.cancel();
    }
    await flutterLocalNotificationsPlugin.cancel(_notificationId);
    await _clearAlarmTime();
    print('Pomodoro alarm reset.');
  }

  /// Handle the alarm (vibration + stop foreground task)
  Future<void> _handleAlarm() async {
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(pattern: [0, 1000, 500, 1000]);
    }

    // Stop the foreground task once the timer ends
    await stopForegroundTask();
  }

  /// Save the alarm time to shared preferences
  Future<void> _saveAlarmTime(DateTime alarmTime) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("alarmTime", alarmTime.toIso8601String());
    print('Alarm time saved: $alarmTime');
  }

  /// Clear the saved alarm time
  Future<void> _clearAlarmTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("alarmTime");
    print('Alarm time cleared.');
  }

  /// Calculate the remaining time dynamically based on saved alarm time
  Future<int> calculateRemainingTime(int defaultDuration) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? alarmTimeString = prefs.getString("alarmTime");

    if (alarmTimeString != null) {
      DateTime alarmTime = DateTime.parse(alarmTimeString);
      DateTime now = DateTime.now();

      if (now.isAfter(alarmTime)) {
        // Timer has completed, reset to default
        await _clearAlarmTime();
        return defaultDuration;
      } else {
        // Timer is still running, calculate remaining time
        return alarmTime.difference(now).inSeconds;
      }
    } else {
      return defaultDuration; // No saved alarm time, return default
    }
  }

  // Callback for the foreground task
  @pragma('vm:entry-point')
  static void _foregroundTaskCallback() {
    FlutterForegroundTask.setTaskHandler(_PomodoroTaskHandler());
  }
}

class _PomodoroTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('Foreground task started.');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    print('Foreground task running: ${timestamp.toIso8601String()}');
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print('Foreground task stopped.');
  }

  @override
  void onReceiveData(Object data) {}
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
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
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    // Initialize the notification plugin
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        print('Notification clicked with payload: ${response.payload}');
      },
    );
  }

  Future<void> schedulePomodoroAlarm({
    required int durationInSeconds, // Duration in seconds for the Pomodoro session
    String alarmTitle = 'Pomodoro Complete', // Default notification title
    String alarmBody = 'Time to take a break!', // Default notification body
  }) async {
    // Store original duration
    _originalDuration = durationInSeconds;
    _remainingTime = durationInSeconds;

    // Calculate the time when the alarm should trigger
    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = now.add(Duration(seconds: durationInSeconds));

    // Notification details
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'pomodoro_channel_id', // Channel ID
      'Pomodoro Notifications', // Channel name
      channelDescription: 'Notifications for Pomodoro timer completion',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification'), // Custom sound
      playSound: true,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    // Schedule the notification
    await flutterLocalNotificationsPlugin.zonedSchedule(
      _notificationId, // Notification ID
      alarmTitle, // Notification title
      alarmBody, // Notification body
      scheduledTime, // Scheduled time
      platformChannelSpecifics, // Notification details
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );

    // Schedule vibration when the alarm triggers
    Future.delayed(Duration(seconds: durationInSeconds), () async {
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(pattern: [0, 1000, 500, 1000]); // Vibrate with pattern
      }
    });

    print('Pomodoro alarm scheduled for: $scheduledTime');
  }



  Future<void> cancelPomodoroAlarm() async {
    // Cancel the current notification and reset the timer
    _remainingTime = null;
    _originalDuration = null;
    _isPaused = false;
    await Future.delayed(Duration(seconds: 2));
    if (await Vibration.hasVibrator() == true) {
      Vibration.cancel(); // Stop ongoing vibration
    }
    await flutterLocalNotificationsPlugin.cancel(_notificationId);

    print('Pomodoro alarm reset.');
  }
}

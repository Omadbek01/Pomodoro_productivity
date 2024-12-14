import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

void testAlarmManager() async {
  // Initialize Timezone and Notifications
  tz.initializeTimeZones();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

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

  // Schedule the alarm 10 seconds from now
  final now = tz.TZDateTime.now(tz.local);
  final scheduledTime = now.add(const Duration(seconds: 10));

  // Notification details
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
    'test_channel_id', // Channel ID
    'Test Channel', // Channel name
    channelDescription: 'This is a test channel for alarms',
    importance: Importance.max,
    priority: Priority.high,
    sound: RawResourceAndroidNotificationSound('notification'), // Custom alarm sound
    playSound: true,
  );
  const NotificationDetails platformChannelSpecifics =
  NotificationDetails(android: androidPlatformChannelSpecifics);

  // Schedule the notification
  await flutterLocalNotificationsPlugin.zonedSchedule(
    0, // Notification ID
    'Pomodoro Alarm', // Notification title
    'This is your Pomodoro alarm!', // Notification body
    scheduledTime, // Scheduled time
    platformChannelSpecifics, // Notification details
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
    UILocalNotificationDateInterpretation.absoluteTime,
  );

  print('Alarm scheduled for: $scheduledTime');
}

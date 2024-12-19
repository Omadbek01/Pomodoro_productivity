import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:workmanager/workmanager.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final prefs = await SharedPreferences.getInstance();
    String? alarmTimeStr = prefs.getString('alarm_time');

    if (alarmTimeStr == null) {
      // No alarm time set; stop the service.
      debugPrint('No alarm time found. Check the execution sequence.');
      await FlutterForegroundTask.stopService();
      return Future.value(false);
    }

    final alarmTime = DateTime.parse(alarmTimeStr);
    final now = DateTime.now();

    // Calculate remaining time in seconds
    int remainingTime = alarmTime.difference(now).inSeconds;

    if (remainingTime > 0) {
      // Update remaining time notification
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
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
        'Time left: ${formatTime(remainingTime)}',
        notificationDetails,
      );

      // Timer continues to run
      return Future.value(true);
    } else {
      // Time is up; stop service
      await FlutterForegroundTask.stopService();
      return Future.value(false);
    }
  });
}

// Helper: Formats time in seconds as MM:SS
String formatTime(int seconds) {
  final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
  final secs = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$secs';
}
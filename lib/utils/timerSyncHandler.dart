import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimerSyncHandler {
  /// Save the alarm end time to shared preferences.
  Future<void> saveAlarmTime(DateTime alarmTime) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("alarmTime", alarmTime.toIso8601String());
  }

  /// Calculate the remaining time dynamically.
  Future<int> calculateRemainingTime(int defaultDuration) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? alarmTimeString = prefs.getString("alarmTime");

    if (alarmTimeString != null) {
      DateTime alarmTime = DateTime.parse(alarmTimeString);
      DateTime now = DateTime.now();

      if (now.isAfter(alarmTime)) {
        // Timer has completed, reset to default
        await clearTimerState();
        return defaultDuration; // Reset timer
      } else {
        // Timer is still running, calculate remaining time
        int remainingTime = alarmTime.difference(now).inSeconds;
        return remainingTime > 0 ? remainingTime : defaultDuration;
      }
    } else {
      return defaultDuration; // No saved alarm time, return default
    }
  }

  /// Clear saved alarm time from shared preferences.
  Future<void> clearTimerState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("alarmTime");
  }
}

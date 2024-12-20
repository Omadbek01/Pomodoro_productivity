import 'package:flutter/services.dart';

class WakeLockManager {
  static const platform = const MethodChannel('com.au.simptechsolutions.pomodoro_productivity/wakelock');

  static Future<void> acquireWakeLock() async {
    try {
      await platform.invokeMethod('acquireWakeLock');
      print("Wake lock acquired"); // Add logging here
    } on PlatformException catch (e) {
      print("Failed to acquire wake lock: '${e.message}'.");
    }
  }

  static Future<void> releaseWakeLock() async {
    try {
      await platform.invokeMethod('releaseWakeLock');
      print("Wake lock released"); // Add logging here
    } on PlatformException catch (e) {
      print("Failed to release wake lock: '${e.message}'.");
    }
  }
}
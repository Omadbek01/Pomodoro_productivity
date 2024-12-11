import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  // Focus Time (in minutes)
  static Future<int> getFocusTime() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      print(preferences.getKeys());
      return preferences.getInt('focusTime') ?? 25;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> setFocusTime(int value) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      debugPrint('focus time set to $value');
      await preferences.setInt('focusTime', value);
    } catch (e) {
      rethrow;
    }
  }

  // Break Time (in minutes)
  static Future<int> getBreakTime() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getInt('breakTime') ?? 5;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> setBreakTime(int value) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setInt('breakTime', value);
    } catch (e) {
      rethrow;
    }
  }

  // Vibration
  static Future<bool> isVibrationEnabled() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getBool('vibration') ?? true;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> setVibrationEnabled(bool value) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool('vibration', value);
    } catch (e) {
      rethrow;
    }
  }

  // Melody
  static Future<bool> isMelodyEnabled() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getBool('melody') ?? true;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> setMelodyEnabled(bool value) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool('melody', value);
    } catch (e) {
      rethrow;
    }
  }

  // Dark Mode
  static Future<bool> isDarkModeEnabled() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getBool('darkMode') ?? false;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> setDarkModeEnabled(bool value) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool('darkMode', value);
    } catch (e) {
      rethrow;
    }
  }
}

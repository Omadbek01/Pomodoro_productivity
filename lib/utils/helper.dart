import 'package:flutter/material.dart';

int parseTimeStringToSeconds(String? timeString) {
  if (timeString == null || timeString.isEmpty) {
    return 0;
  }

  try {
    final parts = timeString.split(':');
    if (parts.length == 2) {
      final minutes = int.parse(parts[0]);
      final seconds = int.parse(parts[1]);
      return (minutes * 60) + seconds;
    } else if (parts.length == 1) {
      // Handle case where only seconds are provided
      final seconds = int.parse(parts[0]);
      return seconds;
    }
  } catch (e) {
    debugPrint('Error parsing time string: $e');
  }

  return 0; // Return 0 if parsing fails
}
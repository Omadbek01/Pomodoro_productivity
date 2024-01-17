import 'package:flutter/material.dart';
import 'home_page.dart';

void main() => runApp(Pomodoro());

class Pomodoro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF2A2B4D),
        primaryColor: Color(0xFF2A2B4D),
        fontFamily: 'Quicksand-Variable',
      ),
      home: HomePage(),
    );
  }
}

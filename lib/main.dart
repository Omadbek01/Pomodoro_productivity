import 'package:flutter/material.dart';
import 'screens/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(Pomodoro());
}


class Pomodoro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF2A2B4D),
        primaryColor: const Color(0xFF2A2B4D),
        fontFamily: 'Quicksand-Variable',
      ),
      home: HomePage(),
    );
  }
}

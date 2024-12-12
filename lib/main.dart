import 'package:flutter/material.dart';
import 'screens/home_page.dart';



void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Pomodoro());
}


class Pomodoro extends StatelessWidget {
  const Pomodoro({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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

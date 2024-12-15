import 'package:flutter/material.dart';

class DialogActionButton extends StatelessWidget {
  final bool isBreakTime;

  const DialogActionButton({
    Key? key,
    required this.isBreakTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 15.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 300),
          tween: Tween<double>(begin: 14.0, end: 24.0),
          builder: (context, fontSize, child) {
            return Text(
              isBreakTime ? "Start Break" : "Start Focus",
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          },
        ),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

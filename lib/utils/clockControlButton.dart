import 'package:flutter/material.dart';

class ClockControlButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;
  final IconData icon;
  final double width;

  const ClockControlButton({
    Key? key,
    required this.onTap,
    required this.color,
    required this.icon,
    required this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width / 2.5,
        height: 50.0,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: 40.0),
        ),
      ),
    );
  }
}

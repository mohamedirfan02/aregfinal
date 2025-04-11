import 'package:flutter/material.dart';

class CustomBackground extends StatelessWidget {
  final Widget child; // Pass content inside this widget

  const CustomBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.white,
        ),
        Positioned(
          top: -80,
          left: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF94B447), // ✅ Light green circle
            ),
          ),
        ),
        child, // ✅ This will be the screen content
      ],
    );
  }
}

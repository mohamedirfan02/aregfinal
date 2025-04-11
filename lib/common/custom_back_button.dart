import 'package:flutter/material.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String iconPath; // ✅ Custom image path

  const CustomBackButton({
    super.key,
    required this.onPressed,
    this.iconPath = "assets/icon/back.png", // ✅ Default back icon
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Image.asset(
        iconPath,
        width: 24, // Adjust size as needed
        height: 24,
      ),
      onPressed: onPressed,
    );
  }
}

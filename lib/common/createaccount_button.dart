import 'package:flutter/material.dart';

class CreateAccountButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String buttonText;

  const CreateAccountButton({
    super.key,
    this.onPressed,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 50,
        width: screenWidth,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFF5D6E1E), // ✅ Updated Button Color
          borderRadius: BorderRadius.circular(30.0),
          boxShadow: [
            const BoxShadow(
              color: Colors.black38, // Outer Shadow
              blurRadius: 6,
              offset: Offset(2, 3),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.2), // Inner Shadow Effect
              blurRadius: 8,
              offset: const Offset(-2, -2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            buttonText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              fontFamily: "Inter",
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class CustomLoginButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String buttonText;

  const CustomLoginButton({
    super.key,
    this.onPressed,
    required this.buttonText,
  });

  @override
  State<CustomLoginButton> createState() => _CustomLoginButtonState();
}

class _CustomLoginButtonState extends State<CustomLoginButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 50,
        width: screenWidth,
        margin: const EdgeInsets.all(3),
        transform: Matrix4.translationValues(0, _isPressed ? 2 : 0, 0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF7FBF08),
              Color(0xFF6FA006),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isPressed
              ? [
            const BoxShadow(
              color: Color(0xFF4C6A01),
              offset: Offset(2, 3),
              blurRadius: 6,
            )
          ]
              : const [
            BoxShadow(
              color: Color(0xFF4C6A01),
              offset: Offset(4, 6),
              blurRadius: 10,
            ),
            BoxShadow(
              color: Color(0xFFFFFFFF),
              offset: Offset(-2, -2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.buttonText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: "Inter",
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

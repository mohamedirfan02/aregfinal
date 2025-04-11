import 'package:flutter/material.dart';

class CustomSubmitButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String buttonText;

  const CustomSubmitButton({
    super.key,
    this.onPressed,
    required this.buttonText,
  });

  @override
  State<CustomSubmitButton> createState() => _CustomSubmitButtonState();
}

class _CustomSubmitButtonState extends State<CustomSubmitButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 50,
        width: 200,
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isPressed
                ? [Color(0xFF6FA006), Color(0xFF5A8B04)]
                : [Color(0xFF7FBF08), Color(0xFF6FA006)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30.0),
          boxShadow: _isPressed
              ? []
              : const [
            BoxShadow(
              color: Color(0xFF4C6A01),
              offset: Offset(4, 6),
              blurRadius: 10,
            ),
            BoxShadow(
              color: Colors.white,
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

import 'package:flutter/material.dart';

class CustomSubmitButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String buttonText;
  final bool isLoading;

  const CustomSubmitButton({
    super.key,
    this.onPressed,
    required this.buttonText,
    this.isLoading = false,
  });

  @override
  State<CustomSubmitButton> createState() => _CustomSubmitButtonState();
}

class _CustomSubmitButtonState extends State<CustomSubmitButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isLoading) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isLoading) {
      setState(() => _isPressed = false);
      widget.onPressed?.call();
    }
  }

  void _handleTapCancel() {
    if (!widget.isLoading) {
      setState(() => _isPressed = false);
    }
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
                ? [const Color(0xFF6FA006), const Color(0xFF5A8B04)]
                : [const Color(0xFF7FBF08), const Color(0xFF6FA006)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30.0),
          boxShadow: _isPressed || widget.isLoading
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
          child: widget.isLoading
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
          )
              : Text(
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

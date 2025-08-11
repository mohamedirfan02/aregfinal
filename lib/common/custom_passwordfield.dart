import 'package:flutter/material.dart';

class CustomPasswordField extends StatefulWidget {
  final String? hintText;
  final IconData? icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextEditingController? controller;
  final Function(String)? onChanged;

  const CustomPasswordField({
    Key? key,
    this.hintText,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = true,
    this.validator,
    this.controller,
    this.onChanged,
  }) : super(key: key);

  @override
  _CustomPasswordFieldState createState() => _CustomPasswordFieldState();
}

class _CustomPasswordFieldState extends State<CustomPasswordField> {
  bool _obscureText = true;

  // void _toggleVisibility() {
  //   setState(() {
  //     _obscureText = !_obscureText;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: _obscureText,
      controller: widget.controller,
      onChanged: widget.onChanged,
      validator: widget.validator,
      textAlign: TextAlign.center, // ✅ Center the text
      style: const TextStyle(
        color: Colors.green, // ✅ Green text
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF006D04), // Green text color
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white, // ✅ White background
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide( color: Color(0xFF006D04),), // ✅ Green border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide( color: const Color(0xFF6FA006),), // ✅ Green border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide( color: const Color(0xFF6FA006), width: 1.5),
        ),
      ),
    );
  }
}

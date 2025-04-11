import 'package:flutter/material.dart';

class ConfirmPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;

  const ConfirmPasswordField({
    super.key,
    this.controller,
    required this.hintText,
  });

  @override
  _ConfirmPasswordFieldState createState() => _ConfirmPasswordFieldState();
}

class _ConfirmPasswordFieldState extends State<ConfirmPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0), // Rounded corners
        // Remove the boxShadow and add the border
        border: Border.all(
          color: Colors.grey, // Border color in pinkAccent
          width: 0.4, // Border thickness
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              child: Icon(
                Icons.lock_outline_rounded,
                color: Colors.grey,
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: widget.controller,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

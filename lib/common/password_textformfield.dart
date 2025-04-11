import 'package:flutter/material.dart';

class CustomPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;

  const CustomPasswordField({
    super.key,
     this.controller,
    required this.hintText,
  });

  @override
  _CustomPasswordFieldState createState() => _CustomPasswordFieldState();
}

class _CustomPasswordFieldState extends State<CustomPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    double screenwidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenwidth,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0), // Rounded corners
        // Remove the boxShadow and add the border
        border: Border.all(
          color: Colors.grey, // Border color in pinkAccent
          width: 0.5, // Border thickness
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5.0), // Add padding around the field
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Icon(
                Icons.lock_outline_rounded, // Lock icon
                color: Colors.grey,
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: widget.controller,
                obscureText: _obscureText, // Hide or show password
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: InputBorder.none, // No border
                  contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility, // Toggle icon
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText; // Toggle password visibility
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

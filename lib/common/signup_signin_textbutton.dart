import 'package:flutter/material.dart';

class SignUpTextButton extends StatelessWidget {
  final VoidCallback onSignUpPressed;
  final String promptText;
  final String buttontext;// Renamed variable to avoid conflict

  const SignUpTextButton({
    super.key,
    required this.onSignUpPressed,
    required this.promptText,
    required this.buttontext, // Use the renamed variable here
  });

  @override
  Widget build(BuildContext context) {
    double screenwidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenwidth,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Center the text
        children: [
          Text(
            promptText , // Use the promptText if provided, otherwise fallback to default
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16.0,
            ),
          ),
          TextButton(
            onPressed: onSignUpPressed, // Action for the Sign-Up button
            child:  Text(
              buttontext,
              style: TextStyle(
                color: Colors.grey, // Change color to blue or as per your design
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

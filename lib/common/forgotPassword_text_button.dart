import 'package:flutter/material.dart';

class CustomForgotPasswordButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const CustomForgotPasswordButton(
      {super.key,
        required this.text,
        required this.onPressed});

  @override
  Widget build(BuildContext context) {
    double screenwidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenwidth,
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
              decoration: TextDecoration.underline,
              fontFamily: "Inter",
              color: Colors.black,
              decorationColor: Colors.black26,
              decorationThickness: 1),
        ),
      ),
    );
  }
}

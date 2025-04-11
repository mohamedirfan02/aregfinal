import 'package:flutter/material.dart';

class CustomElevatedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color textColor;

  const CustomElevatedButton(
      {super.key,
        required this.text,
        required this.onPressed,
        this.textColor = Colors.white
      });

  @override
  Widget build(BuildContext context) {
    double screenwidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenwidth,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(text,style: TextStyle(color: textColor,fontSize: 15)),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 18,horizontal: 10),
            backgroundColor: Colors.red[200]
        ),
      ),
    );
  }
}

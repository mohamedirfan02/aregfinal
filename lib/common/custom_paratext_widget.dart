import 'package:flutter/material.dart';

import 'app_colors.dart';

class CustomText extends StatelessWidget {
  final String boldText;
  final String text;
  final String subtext;

  const CustomText({super.key, required this.boldText, required this.text, required this.subtext});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Reset Password" text in bold and Inter font
        Align(
          alignment: Alignment.center,
          child: Text(
            boldText,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter', // Use Inter font
              color: AppColors.secondaryColor, // Customize as needed
            ),
          ),
        ),
        //SizedBox(height: 8), // Spacing between the two texts
        // Instructional text in normal weight
        Align(
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.normal,
              fontFamily: 'Inter', // Use Inter font
              color:  AppColors.primaryColor, // Customize as needed
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Text(
            subtext,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.normal,
              fontFamily: 'Inter', // Use Inter font
              color: Colors.black, // Customize as needed
            ),  textAlign: TextAlign.center, // this aligns both lines of subtext
          ),
        )
      ],
    );
  }
}

import 'package:flutter/material.dart';

class CustomImageWidget extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;
  final double top;
  final double right;

  const CustomImageWidget({
    Key? key,
    required this.imagePath,
    this.width = 250,
    this.height = 250,
    this.top = 40,
    this.right = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      child: Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }
}
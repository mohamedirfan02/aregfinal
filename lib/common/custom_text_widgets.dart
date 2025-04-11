import 'package:flutter/material.dart';
class TextWidget extends StatefulWidget {
  final String text;
  final FontWeight? fontWeight;
  final Color? textColor;
  final TextAlign? textAlign;
  final double? textSize;

  const TextWidget(
      {super.key,
        required this.text,
        this.fontWeight,
        this.textColor,
        this.textSize,
        this.textAlign});

  @override
  State<TextWidget> createState() => _TextWidgetState();
}

class _TextWidgetState extends State<TextWidget> {
  @override
  Widget build(BuildContext context) {
    return Text(widget.text,
        style: TextStyle(
          fontFamily: "Poppins",
          color: widget.textColor,
          fontWeight: widget.fontWeight,
          fontSize: widget.textSize,
        ),
    );

  }
}

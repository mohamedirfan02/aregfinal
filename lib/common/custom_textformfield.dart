import 'package:flutter/material.dart';

class CustomTextFormField extends StatefulWidget {
  final String hintText;
  final TextInputType keyboardType;
  final Function(String)? onChanged;
  final IconData? iconData;
  final String? Function(String?)? validator;
  final TextEditingController controller;

  const CustomTextFormField({
    super.key,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.iconData,
    this.validator,
    required this.controller,
  });

  @override
  _CustomTextFormFieldState createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  bool isHintVisible = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() {
        isHintVisible = widget.controller.text.isEmpty;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth,
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: const Color(0xFF6FA006), // Green border
          width: 1.0,
        ),
      ),
      child: Center(
        child: TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          style: const TextStyle(
            color: Color(0xFF006D04), // Green text color
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: isHintVisible ? widget.hintText : null,
            hintStyle: const TextStyle(
              color: Color(0xFF006D04),
              fontWeight: FontWeight.w600,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          validator: widget.validator,
        ),
      ),
    );
  }
}

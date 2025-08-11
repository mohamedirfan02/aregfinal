import 'package:flutter/material.dart';

class CustomTextFormField extends StatefulWidget {
  final String hintText;
  final TextInputType keyboardType;
  final Function(String)? onChanged;
  final IconData? iconData;
  final String? Function(String?)? validator;
  final TextEditingController controller;
  final bool isPassword;

  const CustomTextFormField({
    super.key,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.iconData,
    this.validator,
    required this.controller,
    this.isPassword = false,
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  bool _obscurePassword = true;
  String? errorText;
  bool isHintVisible = true;

  @override
  void initState() {
    super.initState();
    _obscurePassword = widget.isPassword;

    widget.controller.addListener(() {
      final isEmpty = widget.controller.text.isEmpty;
      if (isHintVisible != isEmpty) {
        setState(() {
          isHintVisible = isEmpty;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: const Color(0xFF6FA006),
                  width: 1.0,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(
                controller: widget.controller,
                keyboardType: widget.keyboardType,
                onChanged: (value) {
                  if (widget.onChanged != null) {
                    widget.onChanged!(value);
                  }
                  if (widget.validator != null) {
                    setState(() {
                      errorText = widget.validator!(value);
                    });
                  }
                },
                style: const TextStyle(
                  color: Color(0xFF006D04),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                obscureText: widget.isPassword ? _obscurePassword : false,
                textAlign: TextAlign.start,
                decoration: InputDecoration(
                  hintText: null, // Always null here because we handle it manually
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 45.0, vertical: 18.0),
                  prefixIcon: widget.iconData != null
                      ? Icon(widget.iconData, color: Color(0xFF006D04))
                      : null,
                  suffixIcon: widget.isPassword
                      ? IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                      : null,
                ),
              ),
            ),
            if (isHintVisible)
              IgnorePointer(
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    widget.hintText,
                    style: const TextStyle(
                      color: Color(0xFF006D04),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 12.0),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

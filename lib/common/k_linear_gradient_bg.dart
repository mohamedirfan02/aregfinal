import 'package:flutter/material.dart';

class KLinearGradientBg extends StatelessWidget {
  final List<Color> gradientColor;
  final Widget child;

  const KLinearGradientBg({
    super.key,
    required this.child,
    required this.gradientColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColor,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}

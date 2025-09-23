import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class KSvg extends StatelessWidget {
  final double? height;
  final double? width;
  final BoxFit? boxFit;
  final String svgPath;
  final Color? color;

  const KSvg({
    super.key,
    this.height,
    this.width,
    this.boxFit,
    required this.svgPath,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      svgPath,
      height: height,
      width: width,
      fit: BoxFit.cover,
      color: color,
    );
  }
}

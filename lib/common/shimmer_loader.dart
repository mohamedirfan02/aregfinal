import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class ShimmerLoader extends StatelessWidget {
  final double height;
  final double width;

  const ShimmerLoader({super.key, this.height = 20, this.width = double.infinity});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      duration: const Duration(seconds: 2), // ✅ Shimmer animation speed
      interval: const Duration(milliseconds: 500), // ✅ Delay before repeating
      color: Colors.grey.shade300, // ✅ Shimmer color
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.grey.shade200, // ✅ Background color of shimmer
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

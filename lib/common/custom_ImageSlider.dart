import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class ImageSlider extends StatelessWidget {
  final List<String> imagePaths;

  const ImageSlider({super.key, required this.imagePaths});

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      items: imagePaths.map((imagePath) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(25),
          // ✅ Rounded corners
          child: Image.asset(imagePath, fit: BoxFit.cover, width: double.infinity),
        );
      }).toList(),
      options: CarouselOptions(
        height: 130, // ✅ Adjusted height
        autoPlay: true, // ✅ Auto-slide enabled
        autoPlayInterval: const Duration(seconds: 3),
        enlargeCenterPage: false, // ✅ Disabled zoom effect
        viewportFraction: 1.0, // ✅ No extra spacing on sides
      ),
    );
  }
}

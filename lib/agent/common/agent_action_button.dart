import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback? onTap;

  const ActionButton({
    super.key,
    required this.title,
    required this.imagePath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: 30,
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10, // Smaller size for fitting inside button
                fontWeight: FontWeight.w900,
                color: const Color(0xFF006D04),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



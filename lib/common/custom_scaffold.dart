import 'package:flutter/material.dart';
import 'custom_GradientContainer.dart';

class CustomScaffold extends StatelessWidget {
  final Widget child;

  const CustomScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientContainer(
        child: child, // ✅ Only child remains, image properties removed
      ),
    );
  }
}

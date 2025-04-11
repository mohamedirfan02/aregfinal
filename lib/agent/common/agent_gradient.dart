import 'package:flutter/material.dart';

class AgentGradientContainer extends StatelessWidget {
  final Widget child;

  const AgentGradientContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFCBE54E), // Given color
            Colors.white // Slightly darker for depth
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }
}

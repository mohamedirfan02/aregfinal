import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const ActionButton({super.key, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell( // ✅ Detect taps
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
/////////agent home page colour

class AgentHomeGradientContainer extends StatelessWidget {
  final Widget child;

  const AgentHomeGradientContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFCBE54E).withOpacity(0.9), // Reduce intensity
            Colors.white.withOpacity(0.7),
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
      child: child,
    );
  }
}


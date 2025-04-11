import 'package:flutter/material.dart';

class CustomCircularIndicator extends StatelessWidget {
  final double value;
  final String label;
  final String amount;

  const CustomCircularIndicator({
    Key? key,
    required this.value,
    required this.label,
    required this.amount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: CircularProgressIndicator(
            value: value,
            backgroundColor: Colors.grey.shade300,
            color: const Color(0xFF86BC23),
            strokeWidth: 8,
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

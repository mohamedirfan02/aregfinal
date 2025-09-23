// widgets/empty_data_widget.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class EmptyDataWidget extends StatelessWidget {
  const EmptyDataWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset("assets/animations/empty.json", width: 200),
          const SizedBox(height: 10),
          const Text(
            "No Data Available",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          const Text("There is no sales data available for this month."),
        ],
      ),
    );
  }
}
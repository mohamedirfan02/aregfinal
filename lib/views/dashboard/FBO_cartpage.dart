import 'package:flutter/material.dart';
import '../../common/custom_GradientContainer.dart'; // ✅ Import GradientContainer
import '../../common/custom_appbar.dart'; // ✅ Import CustomAppBar

class FboAcknowledgmentScreen extends StatelessWidget {
  const FboAcknowledgmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Scaffold(
        backgroundColor: Colors.transparent, // ✅ Ensure transparency for gradient
        appBar: CustomAppBar(),// ✅ Use CustomAppBar
        body: const Center(
          child: Text(
            "Your Cart is Empty!",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

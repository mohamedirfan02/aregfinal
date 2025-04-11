import 'package:flutter/material.dart';
import '../../common/app_colors.dart';
import 'chatbot_screen.dart'; // ✅ Import ChatBotScreen

class AiChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            double screenHeight = constraints.maxHeight;
            double screenWidth = constraints.maxWidth;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ✅ Welcome Title
                  Text(
                    "Welcome\nYour AI Assistant",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: screenWidth * 0.07, // ✅ Responsive Font Size
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  // ✅ Description
                  Text(
                    "Using this software, you can ask questions and receive articles using an AI assistant.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: screenWidth * 0.045, // ✅ Responsive Font Size
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),

                  // ✅ AI Robot Image (Flexible to Avoid Overflow)
                  Flexible(
                    flex: 3,
                    child: Image.asset(
                      "assets/image/ai1.png",
                      width: screenWidth * 0.7,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05),

                  // ✅ Continue Button (Fixed Size)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        // ✅ Navigate to ChatBotScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChatbotScreen()),
                        );
                      },
                      child: const Text(
                        "Continue",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02), // ✅ Spacing for Small Screens
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

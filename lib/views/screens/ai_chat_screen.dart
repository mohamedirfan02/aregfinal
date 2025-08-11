import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../agent/common/common_appbar.dart';
import '../../common/app_colors.dart';
import 'chatbot_screen.dart'; // ✅ Import ChatBotScreen

class AiChatScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: CommonAppbar(title: "Chat with Ai"),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenHeight = constraints.maxHeight;
          double screenWidth = constraints.maxWidth;

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: screenHeight),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.08),

                    // Welcome Title
                    Text(
                      "Welcome\nYour AI Assistant",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.07,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : AppColors.darkGreen,
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    // Description
                    Text(
                      "Using this software, you can ask questions and receive articles using an AI assistant.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.04),

                    // AI Robot Animation
                    Lottie.asset(
                      'assets/animations/bot_wait.json',
                      width: screenWidth * 0.7,
                      fit: BoxFit.contain,
                    ),

                    SizedBox(height: screenHeight * 0.05),

                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6FA006),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
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

                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),
              ),
            ),
          );
        },
      ),

      backgroundColor: isDarkMode ? Colors.black : Colors.white, // Optional: background color
    );
  }

}

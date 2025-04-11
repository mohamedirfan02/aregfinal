import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../common/custom_GradientContainer.dart';
import '../../config/api_config.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();

  Future<void> _changePassword() async {
    //const String apiUrl = 'http://192.168.0.219:8000/api/auth/reset-password';

    try {
      final prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');
      String? token = prefs.getString('token');

      print("📌 Debug - Email: $email");
      print("📌 Debug - Token: $token");

      if (email == null || token == null) {
        _showPopup('Authentication error. Please log in again.', Colors.red);
        return;
      }

      if (oldPasswordController.text.isEmpty || newPasswordController.text.isEmpty) {
        _showPopup('Please fill in all fields.', Colors.red);
        return;
      }

      final requestData = {
        "email": email,
        "new_password": newPasswordController.text,
        "old_password": oldPasswordController.text,
      };

      final response = await http.post(
        Uri.parse(ApiConfig.resetPassword), // ✅ Use API Config
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestData),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        // ✅ Clear text fields after success
        oldPasswordController.clear();
        newPasswordController.clear();

        // ✅ Show popup dialog
        _showPopup(responseData['message'], Colors.green);
      } else {
        _showPopup(responseData['message'] ?? 'Something went wrong.', Colors.red);
      }
    } catch (e) {
      _showPopup('Error: $e', Colors.red);
    }
  }

  // Function to show popup messages
  void _showPopup(String message, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          color == Colors.green ? "Success" : "Error",
          style: TextStyle(color: color),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
      //GradientContainer(
     SingleChildScrollView(  // Wrap the entire Column with SingleChildScrollView
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Back Button
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Image.asset(
                    "assets/icon/back.png", // ✅ Custom back button image
                    width: 24,
                    height: 24,
                  ),
                ),

                const SizedBox(height: 40),

                // Title
                const Center(
                  child: Text(
                    "Change Password",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 90),

                // Illustration
                Center(
                  child: Image.asset("assets/image/login.png", width: 250),
                ),

                const SizedBox(height: 20),

                // Password Fields
                CustomTextField(label: "Old Password", controller: oldPasswordController),
                const SizedBox(height: 15),
                CustomTextField(label: "New Password", controller: newPasswordController),

                const SizedBox(height: 130),

                // Submit Button
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5D6E1E), // ✅ Updated button color
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _changePassword, // ✅ Call change password function
                      child: const Text(
                        "Submit",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
     // ),
    );
  }

}

// Reusable TextField Widget
class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const CustomTextField({super.key, required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: true, // ✅ Hide password input
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

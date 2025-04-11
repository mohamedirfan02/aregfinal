import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../common/custom_back_button.dart';
import '../common/custom_button.dart';
import '../common/custom_paratext_widget.dart';
import '../common/custom_passwordfield.dart';
import '../common/custom_scaffold.dart';

class NewPassword extends StatefulWidget {
  final String email; // ✅ Get email from previous screen

  const NewPassword({super.key, required this.email});

  @override
  _NewPasswordState createState() => _NewPasswordState();
}

class _NewPasswordState extends State<NewPassword> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("https://87df-103-186-120-91.ngrok-free.app/api/auth/change-password"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "email": widget.email,
          "new_password": _newPasswordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password changed successfully!", style: TextStyle(color: Colors.green))),
        );
        context.go('/login'); // ✅ Navigate to login after success
      } else {
        _showError(data["message"] ?? "Failed to reset password.");
      }
    } catch (e) {
      _showError("Server error: $e");
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(color: Colors.red))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // imageTop: 40,
      // imageRight: 20,
      // imageSizeFactor: 0.4,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 90),

                    // Illustration
                    Center(
                      child: SizedBox(
                        width: 250,
                        height: 250,
                        child: Lottie.asset(
                          'assets/animations/new.json',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // ✅ Title
                    const CustomText(
                      boldText: 'Reset Password',
                      text: 'Enter your new password',
                      subtext: 'Your new password must be different\nfrom previous used password',
                    ),
                    const SizedBox(height: 20),

                    // ✅ New Password Field
                    const Text("New Password", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
                    const SizedBox(height: 8),
                    CustomPasswordField(
                      hintText: 'Enter New Password',
                      controller: _newPasswordController,
                      onChanged: (value) {
                        setState(() {}); // ✅ Update UI when typing
                      },
                    ),

                    const SizedBox(height: 20),

                    // ✅ Confirm Password Field
                    const Text("Confirm Password", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
                    const SizedBox(height: 8),
                    CustomPasswordField(
                      hintText: 'Enter Confirm Password',
                      controller: _confirmPasswordController,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Confirm your password';

                        String newPassword = _newPasswordController.text.trim();
                        String confirmPassword = value.trim(); // ✅ Trim input

                        if (confirmPassword != newPassword) return 'Passwords do not match'; // ✅ Check after trimming
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {}); // ✅ Triggers UI rebuild when typing
                      },
                    ),

                    const SizedBox(height: 30),

                    // ✅ Submit Button
                    Center(
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : CustomSubmitButton(
                        onPressed: _changePassword,
                        buttonText: 'Continue',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ✅ Back Button
          Positioned(
            top: 40,
            left: 10,
            child: CustomBackButton(
              onPressed: () {
                context.go('/reset-password');
              },
            ),
          ),
        ],
      ),
    );
  }
}

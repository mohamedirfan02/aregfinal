import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../common/custom_button.dart';
import '../../config/api_config.dart';
import '../../theme/size_config.dart';
import '../dashboard/restaurant_bottom_navigation.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();

  Future<void> _changePassword() async {
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
        "username": email,
        "new_password": newPasswordController.text,
        "old_password": oldPasswordController.text,
      };

      // 👉 Add this line to debug the URL
      print("📌 Reset Password URL: ${ApiConfig.resetPassword}");
      print("📌 Reset Password URL: ${requestData}");

      final client = http.Client();
      final request = http.Request('POST', Uri.parse(ApiConfig.resetPassword));
      request.headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      request.body = json.encode(requestData);

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      print("📌 Manual Status Code: ${response.statusCode}");
      print("📌 Manual Response: ${response.body}");


      print("📌 Status Code: ${response.statusCode}");
      print("📌 Response Body: ${response.body}");

      if (response.headers['content-type']?.contains('application/json') == true) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (response.statusCode == 200 && responseData['status'] == 'success') {
          oldPasswordController.clear();
          newPasswordController.clear();
          _showPopup(responseData['message'], Colors.green);
        } else {
          _showPopup(responseData['message'] ?? 'Something went wrong.', Colors.red);
        }
      } else {
        _showPopup("Unexpected server response. Please try again later.", Colors.red);
      }
    } catch (e) {
      _showPopup('Error: $e', Colors.red);
    }
  }


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
            onPressed: () {
              Navigator.pop(context); // Close dialog
              if (color == Colors.green) {
                // Wait for the dialog to fully close before navigating
                Future.delayed(Duration(milliseconds: 100), () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => BottomNavigation(userDetails: {}),
                    ),
                        (route) => false,
                  );
                });
              }
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.w(5)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: SizeConfig.h(5)),

              // Back Button
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Image.asset(
                  "assets/icon/back.png",
                  width: SizeConfig.w(6),
                  height: SizeConfig.h(3),
                ),
              ),

              SizedBox(height: SizeConfig.h(5)),

              // Title
              Center(
                child: Text(
                  "Change Password",
                  style: TextStyle(
                    fontSize: SizeConfig.ts(22),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(height: SizeConfig.h(10)),

              // Illustration
              Center(
                child: Image.asset(
                  "assets/image/login.png",
                  width: SizeConfig.w(60),
                ),
              ),

              SizedBox(height: SizeConfig.h(3)),

              // Password Fields
              CustomTextField(
                hintText: "Old Password",
                controller: oldPasswordController,
              ),

              SizedBox(height: SizeConfig.h(2)),
              CustomTextField(
                hintText: "New Password",
                controller: newPasswordController,
              ),
              SizedBox(height: SizeConfig.h(10)),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: SizeConfig.h(8.5),
                  child: CustomSubmitButton(
                    buttonText: "Submit",
                    onPressed: _changePassword,
                  ),
                ),
              ),

              SizedBox(height: SizeConfig.h(5)),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable TextField Widget

class CustomTextField extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool isHintVisible = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_checkHintVisibility);
  }

  void _checkHintVisibility() {
    setState(() {
      isHintVisible = widget.controller.text.isEmpty;
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_checkHintVisibility);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context); // ✅ Initialize SizeConfig

    return Container(
      width: double.infinity,
      height: SizeConfig.h(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: const Color(0xFF6FA006),
          width: 1.0,
        ),
      ),
      child: Center(
        child: TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          validator: widget.validator,
          obscureText: true, // Optional: remove this if not all fields are passwords
          style: TextStyle(
            color: const Color(0xFF006D04),
            fontWeight: FontWeight.w600,
            fontSize: SizeConfig.ts(14),
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: isHintVisible ? widget.hintText : null,
            hintStyle: TextStyle(
              color: const Color(0xFF006D04),
              fontWeight: FontWeight.w600,
              fontSize: SizeConfig.ts(14),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}


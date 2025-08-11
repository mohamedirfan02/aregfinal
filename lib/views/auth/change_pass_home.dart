import 'dart:convert';
import 'package:areg_app/config/api_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../common/custom_button.dart';
import '../../common/custom_textformfield.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _inputController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSending = false;
  String? verificationId; // Stores Firebase verification ID

  // ✅ Function to Determine if Input is Email or Phone
  bool _isEmail(String input) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$").hasMatch(input);
  }

  bool _isPhone(String input) {
    return RegExp(r'^\d{10}$').hasMatch(input);
  }

  // ✅ Function to Send OTP (Both Email & SMS)
  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
    });

    String input = _inputController.text.trim();
    String? email;
    String? phoneNumber;

    try {
      if (_isEmail(input)) {
        // ✅ Send Email OTP via Laravel API
        final response = await http.post(
          Uri.parse(ApiConfig.sendOtp),
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
          body: jsonEncode({"email": email}),
        );

        final data = jsonDecode(response.body);

        if (response.statusCode == 200) {
          print("✅ Email OTP Sent Successfully!");
        } else {
          _showError(data["message"] ?? "Failed to send Email OTP.");
        }

        // ✅ Navigate with email
        context.go('/ChangePassOtpScreen', extra: {
          "email": email,
          "phone": null,
          "verificationId": null
        });

      } else if (_isPhone(input)) {
        // ✅ Send SMS OTP via Firebase
        phoneNumber = "+91$input";
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (PhoneAuthCredential credential) async {
            print("✅ Auto Verification Completed");
          },
          verificationFailed: (FirebaseAuthException e) {
            print("❌ Phone Verification Failed: ${e.message}");
            _showError("❌ ${e.message}");
          },
          codeSent: (String verificationId, int? resendToken) {
            print("✅ SMS OTP Sent!");
            setState(() {
              this.verificationId = verificationId;
            });

            // ✅ Navigate to OTP Verification Screen (Phone)
            context.go('/ChangePassOtpScreen', extra: {
              "email": email,
              "phone": phoneNumber,  // ✅ Ensure phone is passed
              "verificationId": verificationId,
            });


          },
          codeAutoRetrievalTimeout: (String verificationId) {
            print("⏳ Auto Retrieval Timeout: $verificationId");
          },
        );
      } else {
        _showError("❌ Enter a valid 10-digit Phone Number.");
      }
    } catch (e) {
      _showError("❌ OTP Sending Failed: $e");
    }

    setState(() {
      _isSending = false;
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
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 100),

                    // Illustration
                    Center(
                      child: SizedBox(
                        width: 250,
                        height: 250,
                        child: Lottie.asset(
                          'assets/animations/forget.json',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const Text(
                      "Change Password",
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold,color: Color(0xFF006D04),),
                    ),
                    const SizedBox(height: 18),

                    const Text(
                      "Enter your phone number\nto receive the OTP",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15),
                    ),

                    const SizedBox(height: 30),

                    // ✅ Email/Phone Input Field
                    CustomTextFormField(
                      controller: _inputController,
                      hintText: 'Enter Phone Number',
                      iconData: Icons.mail_outline,
                      keyboardType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an phone number';
                        }
                        if (!_isEmail(value) && !_isPhone(value)) {
                          return 'Enter a valid 10-digit phone number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 35),

                    _isSending
                        ? const CircularProgressIndicator()
                        : CustomSubmitButton(
                      buttonText: 'Submit',
                      onPressed: _sendOtp,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

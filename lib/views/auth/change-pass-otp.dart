import 'dart:async';
import 'dart:convert';
import 'package:areg_app/common/app_colors.dart';
import 'package:areg_app/config/api_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../common/custom_back_button.dart';
import '../../common/custom_button.dart';

class ChangePassOtpScreen extends StatefulWidget {
  final String email;
  final String phone;  // ✅ Store phone in class
  final String verificationId;  // ✅ Store verificationId in class

  const ChangePassOtpScreen({
    super.key,
    required this.email, required this.phone, required this.verificationId,
  });

  @override
  _ChangePassOtpScreenState createState() => _ChangePassOtpScreenState();
}

class _ChangePassOtpScreenState extends State<ChangePassOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int countdown = 30;
  Timer? timer;
  bool _resendEnabled = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown > 0) {
        setState(() {
          countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _resendEnabled = true;
        });
      }
    });
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isVerifying = true;
    });

    String otpCode = _controllers.map((controller) => controller.text).join();

    if (otpCode.length != 6) {
      _showError("Please enter a valid 6-digit OTP.");
      setState(() {
        _isVerifying = false;
      });
      return;
    }

    bool emailVerified = false;
    bool phoneVerified = false;

    try {
      // ✅ Step 1: Verify Email OTP via Laravel API (if email exists)
      if (widget.email.isNotEmpty) {
        final emailResponse = await http.post(
          Uri.parse(ApiConfig.verifyOtp),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"email": widget.email, "otp": otpCode}),
        );

        if (emailResponse.statusCode == 200) {
          emailVerified = true;
          print("✅ Email OTP Verified!");
        }
      }

      // ✅ Step 2: Verify Phone OTP via Firebase (if phone exists)
      if (widget.phone.isNotEmpty) {
        try {
          PhoneAuthCredential credential = PhoneAuthProvider.credential(
            verificationId: widget.verificationId,
            smsCode: otpCode,
          );

          await FirebaseAuth.instance.signInWithCredential(credential);
          phoneVerified = true;
          print("✅ Phone OTP Verified!");
        } catch (e) {
          print("❌ Firebase OTP Verification Failed: ${e.toString()}");
        }
      }

      // ✅ Step 3: If either OTP is valid, navigate to the next screen
      if (emailVerified || phoneVerified) {
        context.go('/ForgotPasswordScreen', extra: widget.email);
      } else {
        _showError("❌ Incorrect OTP. Please try again.");
      }
    } catch (e) {
      _showError("❌ OTP Verification Failed: ${e.toString()}");
    }

    setState(() {
      _isVerifying = false;
    });
  }



  Future<void> _resendOTP() async {
    if (!_resendEnabled) return;

    setState(() {
      countdown = 30;
      _resendEnabled = false;
    });
    startTimer();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.sendOtp),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"email": widget.email}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("New OTP sent to your email.", style: TextStyle(color: Colors.green))),
        );
      } else {
        _showError("Failed to resend OTP.");
      }
    } catch (e) {
      _showError("Server error: $e");
    }
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
              padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.04),
              child: Column(
                children: [
                  // const SizedBox(height: 90),
                  // Illustration
                  Center(
                    child: SizedBox(
                      width: 250,
                      height: 250,
                      child: Lottie.asset(
                        'assets/animations/otp.json',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // ✅ Title
                  const Text(
                    "OTP Verification",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,color: AppColors.primaryColor),
                  ),
                  const SizedBox(height: 10),

                  // ✅ Subtitle
                  const Text(
                    "Please enter the 6-digit code that\nwas sent to your email address",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w400, color: Colors.black54),
                  ),

                  const SizedBox(height: 30),

                  // ✅ OTP Input Fields (6 Digits)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      6,
                          (index) => buildCodeField(_controllers[index], _focusNodes[index]),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ✅ Resend OTP Section
                  const Text(
                    "Didn't receive the code?",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  GestureDetector(
                    onTap: _resendEnabled ? _resendOTP : null,
                    child: Text(
                      countdown > 0 ? "Resend in 0:$countdown" : "Resend Code",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _resendEnabled ? Colors.blue : Colors.grey),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ✅ Verify Button
                  _isVerifying
                      ? const CircularProgressIndicator()
                      : CustomSubmitButton(
                    buttonText: 'Verify and Proceed',
                    onPressed: _verifyOtp,
                  ),
                ],
              ),
            ),
          ),

          // ✅ Custom Back Button
          Positioned(
            top: 40,
            left: 10,
            child: CustomBackButton(
              onPressed: () {
                context.go('/change-password');
              },
            ),
          ),
        ],
      ),
    );
  }

  // ✅ OTP Field Widget (6 Digits)
  Widget buildCodeField(TextEditingController controller, FocusNode focusNode) {
    return SizedBox(
      width: 45,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: "",
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primaryColor, width: 3),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            FocusScope.of(context).nextFocus();
          }
        },
      ),
    );
  }
}

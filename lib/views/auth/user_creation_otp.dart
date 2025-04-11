import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import '../../common/custom_button.dart';
import '../../common/custom_scaffold.dart';

class UserCreationOTP extends StatefulWidget {
  final String email;
  final String phone;
  final String verificationId; // ✅ Accept verification ID from Firebase

  const UserCreationOTP({
    super.key,
    required this.email,
    required this.phone,
    required this.verificationId,
  });

  @override
  _UserCreationOTPState createState() => _UserCreationOTPState();
}

class _UserCreationOTPState extends State<UserCreationOTP> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
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

  Future<void> _verifyOTP() async {
    setState(() {
      _isVerifying = true;
    });

    String otpCode = _controllers.map((controller) => controller.text).join();

    if (otpCode.length < 6) {
      _showError("❌ Please enter a valid 6-digit OTP.");
      setState(() {
        _isVerifying = false;
      });
      return;
    }

    try {
      if (widget.email.isNotEmpty) {
        // ✅ Verify Email OTP via Laravel API
        final response = await http.post(
          Uri.parse("https://abd3-152-59-220-104.ngrok-free.app/api/verify-otp"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"email": widget.email, "otp": otpCode}),
        );

        if (response.statusCode == 200) {
          print("✅ Email OTP Verified!");
        } else {
          _showError("❌ Incorrect Email OTP.");
          setState(() {
            _isVerifying = false;
          });
          return;
        }
      }

      if (widget.phone.isNotEmpty) {
        // ✅ Verify Phone OTP via Firebase
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: widget.verificationId,
          smsCode: otpCode,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
        print("✅ Phone OTP Verified!");
      }

      // ✅ Navigate to Login Screen
      context.go('/login');

    } catch (e) {
      _showError("❌ Verification Failed: $e");
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
      // ✅ Resend Email OTP via Laravel
      final response = await http.post(
        Uri.parse("https://abd3-152-59-220-104.ngrok-free.app/api/send-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": widget.email}),
      );

      if (response.statusCode == 200) {
        print("✅ Email OTP Resent!");
      } else {
        _showError("❌ Failed to resend Email OTP.");
      }

      // ✅ Resend SMS OTP via Firebase
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: "+91${widget.phone}",
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {},
        verificationFailed: (FirebaseAuthException e) {
          print("❌ Phone Verification Failed: ${e.message}");
        },
        codeSent: (String verificationId, int? resendToken) {
          print("✅ SMS OTP Resent!");
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      _showError("❌ Failed to resend OTP: $e");
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
                  const SizedBox(height: 200),

                  // ✅ Title
                  const Text(
                    "OTP Verification",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // ✅ Subtitle
                  Text(
                    "Enter the 6-digit code sent to your email & phone\nEmail: ${widget.email}\nPhone: +91${widget.phone}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w400, color: Colors.black54),
                  ),
                  const SizedBox(height: 30),

                  // ✅ OTP Input Fields
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
                    onPressed: _verifyOTP,
                  ),
                ],
              ),
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
            borderSide: const BorderSide(color: Colors.green, width: 3),
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

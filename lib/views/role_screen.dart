import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../common/custom_back_button.dart';
import '../common/custom_login_button.dart';

class RoleScreen extends StatefulWidget {
  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> {
  bool isLottieLoaded = false;

  @override
  void initState() {
    super.initState();
    _preloadLottie();
  }

  Future<void> _preloadLottie() async {
    await Future.delayed(const Duration(milliseconds: 300)); // Yield frame
    setState(() {
      isLottieLoaded = true;
    });
  }

  Future<void> _navigateTo(String route, {Map<String, dynamic>? extra}) async {
    await Future.delayed(const Duration(milliseconds: 50)); // Avoid blocking UI thread
    if (!mounted) return;
    context.go(route, extra: extra);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 250,
                      height: 250,
                      child: isLottieLoaded
                          ? Lottie.asset(
                        'assets/animations/start.json',
                        fit: BoxFit.contain,
                      )
                          : const CircularProgressIndicator(),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Choose Your Role",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006D04),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Select the role that best fits\nyou and get started!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    const SizedBox(height: 30),
                    CustomLoginButton(
                      buttonText: 'FBO',
                      onPressed: () => context.push('/UserCreation', extra: {'role': 'user'}),
                    ),
                    const SizedBox(height: 40),
                    CustomLoginButton(
                      buttonText: 'Agent',
                      onPressed: () => context.push('/VendorCreation', extra: {'role': 'vendor'}),
                    ),
                    const SizedBox(height: 40),
                    CustomLoginButton(
                      buttonText: 'Collection Point',
                      onPressed: () => context.push('/login'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 10,
            child: CustomBackButton(
              onPressed: () => _navigateTo('/start'),
            ),
          ),
        ],
      ),
    );
  }
}

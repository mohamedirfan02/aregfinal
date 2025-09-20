import 'package:areg_app/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../common/custom_login_button.dart';

class StartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: SizedBox(
                  width: 250,
                  height: 250,
                  child: Lottie.asset(
                    'assets/animations/start.json',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Let's",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondaryColor,
                ),
              ),
              const Text(
                "Get Started",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondaryColor,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "Everything starts from here",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 50),
              /// ✅ Login Button
              CustomLoginButton(
                buttonText: 'Login',
                onPressed: () {
                  context.push('/login');
                },
              ),
              const SizedBox(height: 20),
              CustomLoginButton(
                buttonText: 'Create Account',
                onPressed: () {
                  context.push('/RoleScreen');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

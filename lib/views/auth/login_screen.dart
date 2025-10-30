import 'dart:ui';

import 'package:areg_app/common/app_colors.dart';
import 'package:areg_app/common/k_linear_gradient_bg.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loading_indicator/loading_indicator.dart'; // ✅ Import loading indicator package
import '../../common/custom_back_button.dart';
import '../../common/custom_button.dart';
import '../../common/custom_textformfield.dart';
import '../../common/forgotPassword_text_button.dart';
import '../../fbo_services/UserAuthentication.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false; // ✅ Track loading state

  void _showTopSnackbar(
    String message, {
    Color backgroundColor = Colors.black87,
    Color textColor = Colors.white,
    Widget? icon,
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).viewPadding.top + 16,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: backgroundColor.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      icon,
                      SizedBox(width: 10),
                    ],
                    Expanded(
                      // THIS is the fix
                      child: Text(
                        message,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2))
        .then((_) => overlayEntry.remove());
  }

  Future<void> _storeLoginData(
      String token, String email, String userId, String role) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setString('token', token);
    await prefs.setString('email', email);
    await prefs.setString('userId', userId);
    await prefs.setString('role', role);

    if (role == 'vendor') {
      await prefs.setString('vendor_id', userId);
      print("✅ Vendor ID stored: $userId");
    } else if (role == 'user') {
      await prefs.setString('restaurant_user_id', userId);
      print("✅ Restaurant User ID stored: $userId");
    } else if (role == 'agent') {
      await prefs.setString('agent_id', userId);
      print("✅ Agent ID stored: $userId");
    }
    print("✅ User ID stored: $userId");
    print("✅ Token stored: $token");
    print("✅ Email stored: $email");
    print("✅ Role stored: $role");
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true); // ✅ Show loading indicator

      var username = _emailController.text.trim();
      var password = _passwordController.text.trim();

      final user = await UserAuthentication.loginUser(username, password);
      print("🔹 API Response: $user");

      setState(
          () => _isLoading = false); // ✅ Hide loading indicator after API call

      if (user.containsKey('token')) {
        String token = user['token'];
        String role = user['role'];
        String userId = "";
        Map<String, dynamic> userDetails = {};

        if (user['details'] is Map) {
          userDetails = user['details'];
          userId = userDetails['id'].toString();
        } else {
          print("⚠️ Warning: 'details' field is empty or not a map.");
        }

        await _storeLoginData(token, username, userId, role);

        Future.delayed(Duration(milliseconds: 500), () {
          if (role == 'vendor') {
            context.go('/VendorPage', extra: userDetails);
          } else if (role == 'user') {
            context.go('/UserHome', extra: {
              "role": user['role'], // e.g., "agent"
              "details": user['details'], // full map
            });
          } else if (role == 'agent') {
            context.go('/AgentPage', extra: {
              "role": user['role'], // e.g., "agent"
              "details": user['details'], // full map
            });
          } else {
            _showTopSnackbar(
              "Invalid role associated with your account",
              backgroundColor: Colors.white60,
              textColor: Colors.black,
              icon: Image.asset(
                'assets/icon/error.png',
                height: 24,
                width: 24,
              ),
            );
          }
        });
      } else {
        _showTopSnackbar(
          "Invalid email or password",
          backgroundColor: Colors.white60,
          textColor: Colors.black,
          icon: Image.asset(
            'assets/icon/error.png',
            height: 24,
            width: 24,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double padding = size.width * 0.05;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6A9600),
              Color(0xFF7FBF08),
              Color(0xFF2D8E11),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background circles
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFFC3E029).withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFF8BC34A).withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.3,
              right: -80,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            // Main content
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: padding,
                        vertical: size.height * 0.05,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: size.height * 0.08),

                            // Logo section with glow effect
                            Hero(
                              tag: 'app_logo',
                              child: Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.3),
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    ),
                                    BoxShadow(
                                      color: AppColors.primaryColor.withOpacity(0.4),
                                      blurRadius: 40,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/icon/enzopik.png',
                                  width: size.width * 0.25,
                                  height: size.width * 0.25,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),

                            SizedBox(height: 24),

                            // Welcome text
                            Text(
                              'Welcome Back',
                              style: TextStyle(
                                fontSize: size.width * 0.08,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.1),
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Sign in to continue your journey',
                              style: TextStyle(
                                fontSize: size.width * 0.04,
                                color: Colors.white.withOpacity(0.95),
                                letterSpacing: 0.3,
                              ),
                            ),

                            SizedBox(height: 40),

                            // Login form card with glassmorphism
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.98),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 30,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Email field with modern design
                                  Text(
                                    'Email Address',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.secondaryColor,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.primaryColor.withOpacity(0.2),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: CustomTextFormField(
                                      controller: _emailController,
                                      hintText: 'Enter your email',
                                      iconData: Icons.mail_outline_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),

                                  SizedBox(height: 20),

                                  // Password field
                                  Text(
                                    'Password',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.secondaryColor,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.primaryColor.withOpacity(0.2),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: CustomTextFormField(
                                      controller: _passwordController,
                                      hintText: 'Enter your password',
                                      iconData: Icons.lock_outline_rounded,
                                      keyboardType: TextInputType.visiblePassword,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your password';
                                        }
                                        return null;
                                      },
                                      isPassword: true,
                                    ),
                                  ),

                                  SizedBox(height: 12),

                                  // Forgot password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        context.push('/reset-password');
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.primaryColor,
                                        padding: EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                      child: Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 24),

                                  // Login button with app gradient
                                  _isLoading
                                      ? Center(
                                    child: Container(
                                      height: 56,
                                      width: 56,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primaryColor.withOpacity(0.2),
                                            AppColors.secondaryColor.withOpacity(0.2),
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: SizedBox(
                                          height: 30,
                                          width: 30,
                                          child: LoadingIndicator(
                                            indicatorType: Indicator.ballSpinFadeLoader,
                                            colors: [
                                              AppColors.primaryColor,
                                              AppColors.secondaryColor,
                                              AppColors.fboColor,
                                            ],
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                      : Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primaryColor,
                                          AppColors.loginColor,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryColor.withOpacity(0.4),
                                          blurRadius: 20,
                                          offset: Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _login,
                                        borderRadius: BorderRadius.circular(16),
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Log in',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(
                                                Icons.arrow_forward_rounded,
                                                color: Colors.white,
                                                size: 22,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 16),

                                  // Alternative login divider (optional)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.transparent,
                                                Colors.grey.shade300,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          'Secure Login',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.grey.shade300,
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 40),

                            // Powered by text with app colors
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.copyright_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Powered By Thikse Software Solutions',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Back button with app theme colors
            Positioned(
              top: 45,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      context.go('/start');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

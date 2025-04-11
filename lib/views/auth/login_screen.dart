import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loading_indicator/loading_indicator.dart'; // ✅ Import loading indicator package
import '../../common/custom_back_button.dart';
import '../../common/custom_button.dart';
import '../../common/custom_scaffold.dart';
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


  Future<void> _storeLoginData(String token, String email, String userId, String role) async {
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

      setState(() => _isLoading = false); // ✅ Hide loading indicator after API call

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
            context.go('/UserHome', extra: userDetails);
          } else if (role == 'agent') {
            context.go('/AgentPage', extra: userDetails);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid role associated with your account')),
            );
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email or password')),
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
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding, vertical: size.height * 0.07),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Center(
                            child: SizedBox(
                              width: 250,
                              height: 250,
                              child: Lottie.asset(
                                'assets/animations/login.json',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Log in',
                                  style: TextStyle(
                                    fontSize: size.width * 0.09,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF006D04),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Login to your account',
                                  style: TextStyle(
                                    fontSize: size.width * 0.05,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          CustomTextFormField(
                            controller: _emailController,
                            hintText: 'Email or PhoneNo',
                            iconData: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter valid PhoneNo or email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextFormField(
                            controller: _passwordController,
                            hintText: 'Your Password',
                            iconData: Icons.lock_outline_rounded,
                            keyboardType: TextInputType.visiblePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your valid password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: CustomForgotPasswordButton(
                              text: 'Forgot Password?',
                              onPressed: () {
                                context.push('/reset-password');
                              },
                            ),
                          ),
                          const SizedBox(height: 30),
                          _isLoading
                              ? const SizedBox(
                            height: 50,
                            width: 50,
                            child: LoadingIndicator(
                              indicatorType: Indicator.ballSpinFadeLoader,
                              colors: [Colors.blue, Colors.green, Colors.red],
                              strokeWidth: 2,
                            ),
                          )
                              : CustomSubmitButton(
                            buttonText: 'Submit',
                            onPressed: _login,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 40,
            left: 10,
            child: CustomBackButton(
              onPressed: () {
                context.go('/start');
              },
            ),
          ),
        ],
      ),
    );
  }

}

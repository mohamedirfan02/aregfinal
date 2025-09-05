import 'dart:async';
import 'package:areg_app/common/k_linear_gradient_bg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'common/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>  with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

 // Timer? _timer;
  String? userId;
  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return; // ✅ prevent use after dispose
      context.go('/intro');
    });
    _checkLoginStatus();
    _loadData();
    _fetchUserData();
  }
  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (!mounted) return; // Check if the widget is still mounted
    setState(() {
      this.userId = userId;
    });
  }
  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('token');
    return userId != null && token != null;
  }
  Future<void> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (!mounted) return; // Check if the widget is still mounted
    setState(() {
      this.userId = userId;
    });
  }



  Future<void> _checkLoginStatus() async {
    print('Checking login status...');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');
    final userId = prefs.getString('userId');
    print("🔍 Retrieved Token: $token");
    print("🔍 Retrieved Role: $role");
    print("🔍 Retrieved User ID: $userId");
    await Future.delayed(const Duration(seconds: 2)); // Optional splash delay

    if (!mounted) return;

    if (token != null && role != null && userId != null) {
      print("✅ Login found. Navigating to respective home page...");
      if (role == 'vendor') {
        context.go('/VendorPage');
      } else if (role == 'user') {
        context.go('/UserHome');
      } else if (role == 'agent') {
        context.go('/AgentPage');
      } else {
        context.go('/login');
      }
    } else {
      // ❌ No login found
      print("🚫 Token or User ID is null. Redirecting to intro screen.");
      context.go('/intro'); // Or '/login' if not first-time
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: Colors.white,
      body: KLinearGradientBg(
        gradientColor: AppColors.GradientColor,
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Image.asset(
              'assets/icon/enzopik.png',
              width: 250.w,
              height: 250.h,
            ),
          ),
        ),
      ),
    );
  }

}

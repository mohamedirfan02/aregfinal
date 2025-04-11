import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
 // Timer? _timer;
  String? userId;
  @override
  void initState() {
    super.initState();
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
    final userId = prefs.getString('user_id');
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

  // @override
  // void dispose() {
  //   _timer?.cancel();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/image/newsplash.png',
          width: 250.w,
          height: 250.h,
        ),
      ),
    );
  }
}

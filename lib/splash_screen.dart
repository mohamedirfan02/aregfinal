import 'dart:async';
import 'package:areg_app/common/k_linear_gradient_bg.dart';
import 'package:areg_app/views/screens/widgets/k_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'common/app_colors.dart';
import 'core/storage/app_assets_constant.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

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

    // Wait for animation to complete, then check navigation
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      _determineRoute();
    });
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

  Future<void> _determineRoute() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');
    final role = prefs.getString('role');
    final userId = prefs.getString('userId');
    final hasCompletedIntro = prefs.getBool('intro_completed') ?? false;
    final hasSeenNotificationPrompt = prefs.getBool('notification_prompt_shown') ?? false;
    final hasSeenLocationPrompt = prefs.getBool('location_prompt_shown') ?? false;

    if (!mounted) return;

    if (token != null && role != null && userId != null) {
      // User logged in
      if (role == 'vendor') {
        context.go('/VendorPage');
      } else if (role == 'user') {
        context.go('/UserHome');
      } else if (role == 'agent') {
        context.go('/AgentPage');
      } else {
        context.go('/start');
      }
    } else {
      // User not logged in - check onboarding flow
      if (!hasCompletedIntro) {
        context.go('/intro');
      } else if (!hasSeenNotificationPrompt) {
        context.go('/turnOnNotification');
      } else if (!hasSeenLocationPrompt) {
        context.go('/location-permission');
      } else {
        context.go('/start');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
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
          child: KSvg(
            svgPath: AppAssetsConstants.splashLogo,
            height: 250.h,
            width: 250.w,
            boxFit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
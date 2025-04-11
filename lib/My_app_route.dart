import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'agent/agent_home_screen.dart';
import 'agent/agent_screen/CartPage.dart';
import 'main.dart';
import 'splash_screen.dart';
import 'vendor_app/vendor_screen/vendor_bottombar.dart';
import 'vendor_app/vendor_screen/vendor_cart.dart';
import 'views/agent_home.dart';
import 'views/auth/create_account.dart';
import 'views/auth/create_account_users.dart';
import 'views/auth/create_account_vendor.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/user_creation_otp.dart';
import 'views/auth/vendor_creation_otp.dart';
import 'views/dashboard/agent_Bottom_Navigation_bar.dart';
import 'views/dashboard/restaurant_bottom_navigation.dart';
import 'views/intro_screen.dart';
import 'views/new_password_view.dart';
import 'views/otpscreen.dart';
import 'views/resetpass.dart';
import 'views/role_screen.dart';
import 'views/start_screen.dart';
import 'views/vendor_home.dart';
import 'package:provider/provider.dart';


class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }
  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        _showError("❌ Location permissions are permanently denied.");
        return;
      }
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      _getCurrentLocation();
    }
  }


  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          timeLimit: const Duration(seconds: 10), // Optional timeout
        ),
      );
      print("📍 Location: ${position.latitude}, ${position.longitude}");
    } catch (e) {
      _showError("❌ Error getting location: $e");
    }
  }


  void _showError(String message) {
    final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(color: Colors.red))),
    );
  }




  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthStateNotifier>(context);

    final GoRouter _router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
        GoRoute(path: '/intro', builder: (context, state) => const IntroScreen()),
        GoRoute(path: '/start', builder: (context, state) => StartScreen()),
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(
          path: '/UserHome',
          builder: (context, state) {
            final userDetails = state.extra as Map<String, dynamic>? ?? {};
            return BottomNavigation(userDetails: userDetails);
          },
        ),
        GoRoute(path: '/VendorPage', builder: (context, state) => const VendorBottomNavigation()),
        GoRoute(path: '/AgentPage', builder: (context, state) => const AgentBottomNavigation()),
        GoRoute(path: '/RoleScreen', builder: (context, state) => RoleScreen()),
        GoRoute(path: '/CreateAccount', builder: (context, state) => const CreateAccount()),
        GoRoute(path: '/UserCreation', builder: (context, state) => const UserCreation()),
        GoRoute(path: '/VendorCreation', builder: (context, state) => const VendorCreation()),
        //   GoRoute(path: '/chatbot', builder: (context, state) => const ChatbotScreen()),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) => const ResetPasswordScreen(),
        ),
        GoRoute(
          path: '/otp-verification',
          builder: (context, state) {
            final data = state.extra as Map<String, dynamic>?;
            if (data == null || (!data.containsKey('email') && !data.containsKey('phone'))) {
              throw Exception("Email or Phone is required for OTP verification.");
            }
            return OtpVerificationScreen(
              email: data["email"]?.toString() ?? "",
              phone: data["phone"]?.toString() ?? "",
              verificationId: data["verificationId"]?.toString() ?? "",
            );
          },
        ),
        GoRoute(
          path: '/new-password',
          builder: (context, state) {
            final email = state.extra as String?;
            return email == null ? LoginPage() : NewPassword(email: email);
          },
        ),
        GoRoute(
          path: '/OTPVerificationScreen',
          builder: (context, state) {
            final extraData = state.extra as Map<String, dynamic>? ?? {};
            return OTPVerificationScreen(
              email: extraData["email"] ?? "",
              phone: extraData["phone"] ?? "",
              verificationId: extraData["verificationId"] ?? "",
            );
          },
        ),
        GoRoute(
          path: '/VendorPage',
          builder: (context, state) {
            final vendorDetails = state.extra as Map<String, dynamic>? ?? {};
            return VendorPage(vendorDetails: vendorDetails);
          },
        ),
        GoRoute(path: '/cart', builder: (context, state) => const AgentCartPage()),
        GoRoute(path: '/Vendor_cart', builder: (context, state) => const VendorCartPage()),
        GoRoute(
          path: '/AgentHomeScreen',
          builder: (context, state) {
            final String token = state.extra as String? ?? "token";
            return AgentHomeScreen(token: token);
          },
        ),

        GoRoute(path: '/VendorCartPage', builder: (context, state) => const VendorCartPage()),
      ],
    );


    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X base size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
          scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
          theme: ThemeData(
            scaffoldBackgroundColor: Colors.white,
            useMaterial3: true,
            fontFamily: 'Rajdhani',
            textTheme: TextTheme(
              bodyLarge: TextStyle(fontFamily: 'Rajdhani', fontSize: 16.sp),
              bodyMedium: TextStyle(fontFamily: 'Rajdhani', fontSize: 14.sp),
              headlineLarge: TextStyle(
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.bold,
                fontSize: 24.sp,
              ),
            ),
          ),
        );

      },
    );
  }

}

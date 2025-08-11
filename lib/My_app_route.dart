import 'package:areg_app/go_routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'theme/ThemeNotifier.dart';

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
        locationSettings: const LocationSettings(timeLimit: Duration(seconds: 10)),
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
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: appRouter, // 🆕 Use separated router here
          scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
          theme: ThemeData(
            scaffoldBackgroundColor: Colors.white,
            useMaterial3: true,
            brightness: Brightness.light,
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
          darkTheme: ThemeData.dark().copyWith(
            useMaterial3: true,
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
          themeMode: themeNotifier.themeMode,
        );
      },
    );
  }
}

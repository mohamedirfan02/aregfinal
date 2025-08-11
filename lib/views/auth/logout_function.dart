import 'dart:convert';
import 'dart:ui'; // Import for ImageFilter
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../config/api_config.dart';

Future<void> logout(BuildContext context) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    Map<String, dynamic> deviceInfo = await _getDeviceInfo();

    if (token != null && fcmToken != null) {
      // 🔹 Notify the server to revoke the FCM token and delete device info
      final response = await http.post(
        Uri.parse(ApiConfig.logout), // ✅ API Endpoint for Logout
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "fcm_token": fcmToken,
          "device_info": deviceInfo,
        }),
      );

      print("🔹 Logout API Response: ${response.body}");

      if (response.statusCode == 200) {
        // ✅ Remove FCM Token from Firebase
        await FirebaseMessaging.instance.deleteToken();
        print("✅ FCM Token Deleted from Firebase");

        // ✅ Clear stored session data
        await prefs.clear();
        print("✅ All user data cleared from SharedPreferences");

        _showTopSnackbar(
          context,
          'Logout successful',
          backgroundColor: Colors.white38,
          textColor: Colors.black,
        );
        // 🔹 Navigate to login screen
        context.go('/login');
      } else {
        _showTopSnackbar(
          context,
          'Logout failed. Please try again',
          backgroundColor: Colors.white38,
          textColor: Colors.black,
        );
      }
    } else {
      _showTopSnackbar(
        context,
        'No token found. Please log in again',
        backgroundColor: Colors.white38,
        textColor: Colors.black,
      );
    }
  } catch (e) {
    print("❌ Error during logout: $e");
    _showTopSnackbar(
      context,
      ' Error during logout: pleas turn the network on and try again.',
      backgroundColor: Colors.white38,
      textColor: Colors.black,
    );
  }
}

// ✅ Function to Get Device Info
Future<Map<String, dynamic>> _getDeviceInfo() async {
  final deviceInfoPlugin = DeviceInfoPlugin();
  final packageInfo = await PackageInfo.fromPlatform();
  String deviceName = "Unknown";
  String os = "Unknown";
  String osVersion = "Unknown";

  try {
    if (await deviceInfoPlugin.androidInfo != null) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      deviceName = androidInfo.model;
      os = "Android";
      osVersion = androidInfo.version.release;
    } else if (await deviceInfoPlugin.iosInfo != null) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      deviceName = iosInfo.utsname.machine;
      os = "iOS";
      osVersion = iosInfo.systemVersion;
    }
  } catch (e) {
    print("❌ Error fetching device info: $e");
  }

  final deviceInfo = {
    "device_name": deviceName,
    "os": os,
    "os_version": osVersion,
    "app_version": packageInfo.version
  };

  print("✅ Device Info: $deviceInfo"); // 🔹 Print Device Info in Console

  return deviceInfo;
}

// Custom snackbar implementation that shows at the top with blur effect and black text
void _showTopSnackbar(
    BuildContext context,
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
  Future.delayed(const Duration(seconds: 2)).then((_) => overlayEntry.remove());
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:areg_app/config/api_config.dart'; // ✅ Import API Config
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UserAuthentication {
  // ✅ Get Device Info
  static Future<Map<String, dynamic>> _getDeviceInfo() async {
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

    return {
      "device_name": deviceName,
      "os": os,
      "os_version": osVersion,
      "app_version": packageInfo.version
    };
  }

  // ✅ Get FCM Token
  static Future<String?> _getFCMToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? fcmToken = await messaging.getToken();

    if (fcmToken != null) {
      print("✅ FCM Token: $fcmToken");
    } else {
      print("❌ Failed to generate FCM Token");
    }

    return fcmToken;
  }

  // ✅ Login Function (Now Includes FCM Token Before Login)
  static Future<Map<String, dynamic>> loginUser(String username, String password) async {
    print("🔹 Logging in with username: $username");

    try {
      // ✅ Generate FCM Token BEFORE making login request
      String? fcmToken = await _getFCMToken();
      if (fcmToken == null) {
        return {"error": "Failed to generate FCM token"};
      }

      final deviceInfo = await _getDeviceInfo();

      final response = await http.post(
        Uri.parse(ApiConfig.login), // ✅ Use APIConfig here
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'username': username,
          'password': password,
          'fcm_token': fcmToken, // ✅ Now sending FCM token in login request
          'device_info': deviceInfo
        }),
      );

      print("🔹 Response Status Code: ${response.statusCode}");
      print("🔹 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ Login Successful: $data");

        if (data.containsKey("role")) {
          return {
            "success": true,
            "role": data["role"],
            "token": data["token"],
            "details": data["details"],
          };
        } else {
          return {"error": "Role validation failed"};
        }
      } else {
        return {"error": "Invalid email or password"};
      }
    } catch (e) {
      print("❌ Server Error: $e");
      return {"error": "Server error: $e"};
    }
  }
}

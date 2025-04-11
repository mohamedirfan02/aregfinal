import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UserRegistration {
  static const String baseUrl = "https://enzopik.thikse.in/api/register"; // ✅ API for registration
  static const String sendOtpUrl = "https://enzopik.thikse.in/api/send-otp"; // ✅ API to send OTP
  static const String verifyOtpUrl = "https://enzopik.thikse.in/api/verify-otp"; // ✅ API to verify OTP

  static Future<Map<String, String>> _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

    String deviceName = "Unknown";
    String os = "Unknown";
    String osVersion = "Unknown";

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceName = androidInfo.model;
        os = "Android";
        osVersion = androidInfo.version.release;
      } else if (Platform.isIOS) {
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
    return await messaging.getToken();
  }

  // ✅ Register User with FCM Token & Device Info
  static Future<Map<String, dynamic>> registerUser(
      Map<String, String> userData, File licenseImage, File restaurantImage) async {
    try {
      // 🚀 Fetch FCM Token & Device Info
      String? fcmToken = await _getFCMToken();
      Map<String, String> deviceInfo = await _getDeviceInfo();

      // ✅ Add FCM Token to userData
      userData["fcm_token"] = fcmToken ?? "unknown_token";

      // ✅ Add Device Info as Separate Fields
      userData.addAll(deviceInfo);

      print("🔥 Final User Data: $userData"); // Debugging

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("https://enzopik.thikse.in/api/register"),
      );

      // ✅ **Add form-data text fields**
      userData.forEach((key, value) {
        request.fields[key] = value;
      });

      // ✅ **Attach image files**
      request.files.add(await http.MultipartFile.fromPath("license_url", licenseImage.path));
      request.files.add(await http.MultipartFile.fromPath("restaurant_url", restaurantImage.path));

      // ✅ **Add Headers**
      request.headers.addAll({
        "Accept": "application/json",
        "Content-Type": "multipart/form-data",
      });

      // ✅ **Send request and get response**
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // 🔥 **Debug API Response**
      debugPrint("📩 Response Status Code: ${response.statusCode}");
      debugPrint("📩 Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {"error": "Failed to register: ${response.body}"};
      }
    } catch (e) {
      return {"error": "Error: $e"};
    }
  }


  static Future<Map<String, dynamic>> registerVendor(Map<String, String> userData) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json", // ✅ Prevent Laravel from returning HTML
        },
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {"error": "Failed to register: ${response.body}"};
      }
    } catch (e) {
      return {"error": "Error: $e"};
    }
  }
  // ✅ Send OTP
  static Future<Map<String, dynamic>> sendOTP(String email) async {
    try {
      final response = await http.post(
        Uri.parse(sendOtpUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"email": email}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"error": "Failed to send OTP: ${response.body}"};
      }
    } catch (e) {
      return {"error": "Error: $e"};
    }
  }

  // ✅ Verify OTP
  static Future<Map<String, dynamic>> verifyOTP(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse(verifyOtpUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"email": email, "otp": otp}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"error": "Invalid OTP: ${response.body}"};
      }
    } catch (e) {
      return {"error": "Error: $e"};
    }
  }
}

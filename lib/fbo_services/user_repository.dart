import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart';

import '../config/api_config.dart';

class UserRegistration {

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
      Map<String, String> userData,
      File licenseImage,
      File restaurantImage,
      {required List<Map<String, dynamic>> branches}) async {
    try {
      // 🚀 Get device info and FCM
      String? fcmToken = await _getFCMToken();
      Map<String, String> deviceInfo = await _getDeviceInfo();
      userData["fcm_token"] = fcmToken ?? "unknown_token";
      userData.addAll(deviceInfo);

      var request = http.MultipartRequest(
        "POST",
        Uri.parse(ApiConfig.register),
      );

      // ✅ Add fields
      userData.forEach((key, value) {
        request.fields[key] = value;
      });

      // ✅ Convert branch metadata to JSON without images
      List<Map<String, String>> branchMetadata = [];
      for (int i = 0; i < branches.length; i++) {
        final branch = branches[i];
        branchMetadata.add({
          "branch_name": branch["branchName"],
          "branch_address": branch["branchAddress"],
          "branch_fassai_no": branch["fassaiNo"],
        });

        if (branch["image"] != null && branch["image"] is File) {
          File imageFile = branch["image"];

          // ✅ Print image file path to console
          print("📸 Branch $i Image Path: ${imageFile.path}");

          request.files.add(await http.MultipartFile.fromPath(
            "branches[$i][branch_images]", imageFile.path,
          ));
        } else {
          print("⚠️ Branch $i has no image.");
        }
      }


      for (int i = 0; i < branches.length; i++) {
        final branch = branches[i];
        request.fields["branches[$i][branch_name]"] = branch["branchName"];
        request.fields["branches[$i][branch_address]"] = branch["branchAddress"];
        request.fields["branches[$i][branch_fassai_no]"] = branch["fassaiNo"];

        if (branch["image"] != null && branch["image"] is File) {
          File imageFile = branch["image"];
          print("📸 Branch $i Image Path: ${imageFile.path}");

          request.files.add(await http.MultipartFile.fromPath(
            "branches[$i][license]", imageFile.path,
          ));
        } else {
          print("⚠️ Branch $i has no image.");
        }
      }



      // ✅ Attach main images
      request.files.add(await http.MultipartFile.fromPath("license_url", licenseImage.path));
      request.files.add(await http.MultipartFile.fromPath("restaurant_url", restaurantImage.path));


      // ✅ Headers
      request.headers.addAll({
        "Accept": "application/json",
        "Content-Type": "multipart/form-data",
      });

      // ✅ Send
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint("📩 Response Status Code: ${response.statusCode}");
      debugPrint("📩 Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {"error": "Failed to register Please Try again"};
      }
    } catch (e) {
      return {"error": "Error: $e"};
    }
  }

  static Future<Map<String, dynamic>> registerVendor(
      Map<String, String> userData, File? imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.register));

      userData.forEach((key, value) {
        request.fields[key] = value;
      });

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'profile', // This must match your Laravel controller field name
          imageFile.path,
          filename: basename(imageFile.path),
        ));
      }

      request.headers.addAll({
        "Accept": "application/json",
      });

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(responseBody);
      } else {
        return {"error": "Failed to register: $responseBody"};
      }
    } catch (e) {
      return {"error": "Error: $e"};
    }
  }


  // ✅ Send OTP
  static Future<Map<String, dynamic>> sendOTP(String email) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.sendOtp),
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
  static Future<Map<String, dynamic>> verifyOTP(
      String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.verifyOtp),
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

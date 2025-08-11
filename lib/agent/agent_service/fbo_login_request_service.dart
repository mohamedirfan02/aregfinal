import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../models/restaurant_model.dart';

Future<List<Fbo>> fetchFboRequests() async {
  final url = Uri.parse(ApiConfig.getNewFbo);
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');

  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token', // ✅ Include Bearer Token
    },
  );

  debugPrint("📩 Status Code: ${response.statusCode}");
  debugPrint("📩 Response Body: ${response.body}");

  if (response.statusCode == 200) {
    final decodedResponse = json.decode(response.body);
    if (decodedResponse.containsKey('data') && decodedResponse['data'] is List) {
      return decodedResponse['data'].map<Fbo>((json) => Fbo.fromJson(json)).toList();
    } else {
      throw Exception("Invalid API response format");
    }
  } else {
    throw Exception('Failed to load FBO requests: ${response.body}');
  }
}

// ✅ Function to Approve or Reject FBO Request
Future<void> updateFboStatus(
    BuildContext context,
    int fboId,
    String status, {
      required String agent,
      required String amount,
      String? reason,
    }) async {
  final url = ApiConfig.fboApproval(fboId);
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');

  final Map<String, dynamic> payload = {
    "status": status,
    "assigned_agent": agent,
    "agreed_price": amount,
    if (reason != null) "reason": reason,
  };

  print("📤 API Request: $url");
  print("📤 Sending Data: ${jsonEncode(payload)}");

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(payload),
    );

    print("📩 Status Code: ${response.statusCode}");
    print("📩 Response Body: ${response.body}");

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ FBO $status Successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❗ Your Action is completed but failed on backend")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Error: internal server error but action completed")),
    );
    print("❌ Exception: $e");
  }
}

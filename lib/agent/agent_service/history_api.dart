import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';

class OrderApi {
  static const String baseUrl = ApiConfig.getOrderDetails;

  /// Fetch Orders with dynamic role, ID, and token from SharedPreferences
  Future<List<dynamic>> fetchOrders() async {
    try {
      // Retrieve values dynamically from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? role = prefs.getString("role");
      String? id = prefs.getString("user_id");
      String? token = prefs.getString("token"); // Ensure correct key name

      // Ensure values are not null
      if (role == null || id == null || token == null) {
        throw Exception("❌ Role, ID, or Token is missing");
      }

      // 🔹 Debugging: Log values before making request
      debugPrint("📢 Fetching Orders with:");
      debugPrint("🔹 Role: $role");
      debugPrint("🔹 User ID: $id");
      debugPrint("🔹 Token: $token");

      final Uri url = Uri.parse(ApiConfig.getOrderDetails);

      final response = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
          "Content-Type": "application/json", // ✅ Required for JSON body
        },
        body: jsonEncode({
          "role": role,
          "id": int.parse(id), // ✅ Ensure it's properly parsed as an integer
        }),
      );

      debugPrint("🌐 Response Status: ${response.statusCode}");
      debugPrint("📄 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body)["data"] ?? [];
      } else {
        throw Exception("❌ Failed to load orders: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching orders: $e");
      return [];
    }
  }
}

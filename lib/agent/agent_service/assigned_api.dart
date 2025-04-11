import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AssignedApi {
  static const String baseUrl =
      "https://enzopik.thikse.in/api/get-order-details";

  /// Fetch Orders by status (e.g., 'assigned', 'completed')
  Future<List<dynamic>> fetchOrdersByStatus(String status) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? role = prefs.getString("role");
      String? id = prefs.getString("user_id");
      String? token = prefs.getString("token");

      if (role == null || id == null || token == null) {
        throw Exception("❌ Role, ID, or Token is missing");
      }

      debugPrint("📢 Fetching $status Orders with:");
      debugPrint("🔹 Role: $role");
      debugPrint("🔹 User ID: $id");
      debugPrint("🔹 Token: $token");

      final Uri url = Uri.parse(baseUrl);

      final response = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "role": role,
          "id": int.parse(id),
          "status": status, // 🔑 Dynamic status
        }),
      );

      debugPrint("🌐 Response Status: ${response.statusCode}");
      debugPrint("📄 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        List<dynamic> orders = jsonDecode(response.body)["data"] ?? [];
        return orders.where((order) => order["status"] == status).toList();
      } else {
        throw Exception("❌ Failed to load $status orders: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching $status orders: $e");
      return [];
    }
  }
}

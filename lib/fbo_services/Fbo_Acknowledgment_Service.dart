import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class FboAcknowledgmentService {
  /// ✅ Fetch Completed Orders
  static Future<List<Map<String, dynamic>>?> fetchCompletedOrders()
  async {
    const String apiUrl = ApiConfig.getOrderDetails;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? userId = prefs.getString('user_id');
      String? role = prefs.getString('role'); // ✅ Fetch role dynamically

      if (token == null || userId == null || role == null) {
        print("❌ Missing token, user ID, or role.");
        return null;
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "role": role,  // ✅ Dynamically fetched role
          "id": int.parse(userId),
          "status": "completed", // ✅ Include status filter
        }),
      );

      print("🔹 API Response: ${response.statusCode}");
      print("🔹 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["status"] == "success" && data["data"] != null) {
          return List<Map<String, dynamic>>.from(data["data"]);
        }
      }

      print("❌ Error fetching completed orders.");
      return null;
    } catch (e) {
      print("❌ Exception while fetching orders: $e");
      return null;
    }
  }

  /// ✅ Acknowledge Order for FBO or Vendor
  static Future<bool> acknowledgeOrder(int orderId) async {
    const String apiUrl = ApiConfig.addVoucher;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? role = prefs.getString('role'); // 👈 Fetch role

      if (token == null || role == null) {
        print("❌ Missing token or role.");
        return false;
      }

      // 🔁 Determine the correct acknowledgment field based on role
      String acknowledgementField = role == "vendor"
          ? "collector_acknowledgement"
          : "FBO_acknowledgement";

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "order_id": orderId.toString(),
          acknowledgementField: "acknowledged", // 👈 Dynamic field key
        }),
      );

      print("🔹 Acknowledge API Response: ${response.statusCode}");
      print("🔹 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data["status"] == "success";
      }

      return false;
    } catch (e) {
      print("❌ Exception while acknowledging order: $e");
      return false;
    }
  }

}

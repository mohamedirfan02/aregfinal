import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FboAcknowledgmentService {
  static const String _baseUrl = "https://enzopik.thikse.in/api";

  /// ✅ Fetch Completed Orders
  static Future<List<Map<String, dynamic>>?> fetchCompletedOrders(String userId, String token) async {
    const String apiUrl = "$_baseUrl/get-user-oil-completed-sale";

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

  /// ✅ Acknowledge Order
  static Future<bool> acknowledgeOrder(int orderId) async {
    const String apiUrl = "$_baseUrl/add-voucher";

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        print("❌ Missing authentication token.");
        return false;
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "order_id": orderId.toString(),
          "FBO_acknowledgement": "acknowledged",
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

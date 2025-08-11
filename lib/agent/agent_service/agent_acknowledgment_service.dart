import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';

class AgentAcknowledgmentService {
  Future<List<Map<String, dynamic>>?> fetchAcknowledgmentDetails(
      String token, int userId) async {
    const String apiUrl = ApiConfig.getOrderDetails;

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "role": "agent",
          "id": userId, // Dynamic ID
          "status": "completed",
        }),
      );

      print("🔹 Response Status Code: ${response.statusCode}");
      print("🔹 Raw Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["status"] == "success" && data["data"] is List) {
          return List<Map<String, dynamic>>.from(data["data"]);
        } else {
          print("❌ Unexpected API response format.");
          return null;
        }
      } else {
        print("❌ API Request Failed with Status Code: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("🚨 Error fetching acknowledgment data: $e");
      return null;
    }
  }



  /// ✅ Acknowledge Order
  Future<bool> acknowledgeOrder(int orderId) async {
    const String postUrl = ApiConfig.addVoucher;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        print("❌ Authentication Token Missing");
        return false;
      }

      final response = await http.post(
        Uri.parse(postUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "order_id": orderId.toString(),
          "collector_acknowledgement": "acknowledged",
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print("📩 Acknowledgment Response: $responseData");
        return responseData["status"] == "success";
      } else {
        print("❌ Acknowledge API Request Failed: $e");
        return false;
      }
    } catch (e) {
      print("❌ Exception while acknowledging order: $e");
      return false;
    }
  }
}

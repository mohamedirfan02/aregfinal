import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class OilRequestService {

  /// ✅ Submit oil request
  static Future<Map<String, dynamic>?> submitOilRequest({
    required String type,
    required String quantity,
    required String paymentMethod,
    String? reason,
    String? dateRange,
    String? address,
    String? counter_unit_price,
    String? remarks,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? userId = prefs.getString('userId'); // Get stored user ID

      if (token == null || userId == null) {
        print("❌ Token or User ID is missing.");
        return {"error": "Authentication error. Please log in again."};
      }

      double perKgPrice = 50.0; // ✅ Fixed unit price per kg
      double totalPrice = (double.tryParse(quantity) ?? 0) * perKgPrice; // ✅ Calculate total price

      final requestData = {
        "type": type,
        "quantity": quantity,
        "user_id": userId,
        "payment_method": paymentMethod,
        "reason": paymentMethod == "cash" ? reason : null,
        "proposed_unit_price": perKgPrice.toString(), // Convert to String
        "counter_unit_price": counter_unit_price != null && counter_unit_price.isNotEmpty
            ? counter_unit_price
            : null, // ✅ FIXED: Prevent null.toString() error
        "total_price": totalPrice.toString(),
        "dateRange": dateRange.toString(),//
        "address": address.toString(),
        "remarks": remarks,
      };

      print("🔹 Sending Oil Request: $requestData");

      final response = await http.post(
        Uri.parse(ApiConfig.RequestOil),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode(requestData),
      );

      print("🔹 API Response Status: ${response.statusCode}");
      print("🔹 API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data; // ✅ Return API response
      } else {
        final errorData = json.decode(response.body);
        return {"error": errorData["message"] ?? "Request failed. Try again."};
      }
    } catch (e) {
      print("❌ Exception while submitting oil request: $e");
      return {"error": "Something went wrong. Please try again."};
    }
  }

}

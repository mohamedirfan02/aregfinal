import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class OilSaleService {
  /// ✅ Fetch oil sale data based on logged-in user
  static Future<Map<String, dynamic>?> fetchOilSaleData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? userId = prefs.getString('userId');
      print("✅ Loaded User ID: $userId");
      if (token == null || userId == null) {
        print("❌ Token or User ID is missing.");
        return null;
      }

      final response = await http.get(
        Uri.parse(ApiConfig.getOilSale(userId)),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      print("🔹 API Response Status: ${response.statusCode}");
      print("🔹 API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is! Map || !data.containsKey("data")) {
          print("⚠️ Unexpected API response format.");
          return null;
        }
        return data["data"];
      } else if (response.statusCode == 401) {
        print("❌ Unauthorized: Token may have expired.");
        return {"error": "Unauthorized. Please log in again."};
      } else if (response.statusCode == 404) {
        print("❌ Route Not Found: Check API path.");
        return {"error": "API route not found."};
      } else {
        print("❌ Error fetching oil sale data: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Exception while fetching oil sale data: $e");
      return null;
    }
  }
}

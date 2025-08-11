import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class ApiService {

  Future<Map<String, dynamic>?> fetchRestaurantDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('restaurant_user_id');
    String? token = prefs.getString('token');

    print("🔹 Retrieved User ID: $userId");
    print("🔹 Retrieved Token: $token");

    if (userId == null || token == null) {
      print("❌ Missing User ID or Token");
      return null;
    }

    final String apiUrl = ApiConfig.getOilSale(userId);

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("🔹 API Status Code: ${response.statusCode}");
      print("🔹 API Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("🔹 Parsed JSON: $data");

        if (data.containsKey('data')) {
          return data['data'];
        } else {
          print("❌ Missing 'data' key in API response");
        }
      } else {
        throw Exception("Failed to load restaurant data");
      }
    } catch (e) {
      print("❌ Error fetching restaurant details: $e");
    }
    return null;
  }
}

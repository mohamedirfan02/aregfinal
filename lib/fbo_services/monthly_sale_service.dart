import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MonthlySaleService {
  static Future fetchMonthlyData(int month) async {
    final prefs = await SharedPreferences.getInstance();

    // Fetch the stored user ID dynamically
    final String? userId = prefs.getString('restaurant_user_id');
    final String? authToken = prefs.getString('token'); // Fetch token

    if (authToken == null || userId == null) {
      print("❌ Missing Authentication Token or User ID");
      return null;
    }

    final String apiUrl = "https://enzopik.thikse.in/api/get-monthly-oil-sale/$userId/$month";

    print("📡 Requesting API: $apiUrl");

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $authToken",
          "Content-Type": "application/json",
        },
      );

      print("🔄 Response Code: ${response.statusCode}");
      print("🔄 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("❌ API Error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Network Error: $e");
      return null;
    }
  }
}

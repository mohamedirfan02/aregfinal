import 'dart:convert';
import 'package:http/http.dart' as http;

class VendorRegistration {
  static Future<Map<String, dynamic>> registerVendor(Map<String, String> vendorData) async {
    const String apiUrl = "https://enzopik.thikse.in/api/register"; // Use local Laravel server

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(vendorData),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body); // Success response
      } else {
        return {"error": jsonDecode(response.body)['message'] ?? "Registration failed"};
      }
    } catch (error) {
      return {"error": "Something went wrong. Please try again."};
    }
  }
}

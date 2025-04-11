import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatbotService {
  static const String apiUrl = "https://87df-103-186-120-91.ngrok-free.app/api/chatbot_reposes";

  /// ✅ Fetch user ID from SharedPreferences
  static Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  /// ✅ Send user message & get AI response
  static Future<String> sendMessage(String question) async {
    String? userId = await getUserId();
    if (userId == null || userId.isEmpty) {
      return "❌ User ID not found. Please log in.";
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"question": question, "user_id": userId}),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData["status"] == "success") {
          return jsonData["message"];
        } else {
          return "❌ Invalid response from server";
        }
      } else {
        return "❌ Failed to fetch response. Status Code: ${response.statusCode}";
      }
    } catch (e) {
      return "❌ Error: $e";
    }
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class ChatbotService {
  static const String apiUrl = ApiConfig.chatBot;

  static Future<String> sendMessage(String userMessage) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? id = prefs.getString('userId');
    String? role = prefs.getString('role');

    if (token == null || id == null || role == null) {
      print("❌ Auth error: Missing token, userId, or role.");
      return "❌ User not authenticated. Please log in.";
    }

    try {
      print("📤 Sending message to chatbot → $userMessage");
      print("🧾 Payload: role=$role, id=$id");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "role": role,
          "id": int.tryParse(id),
          "message": userMessage,
        }),
      );

      print("📥 Response Status: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final chatResponse = jsonData["chat_response"];

        if (chatResponse != null && chatResponse["response"] != null) {
          print("✅ Chatbot Response: ${chatResponse["response"]}");
          return chatResponse["response"];
        } else {
          print("⚠️ Chatbot 'chat_response' or 'response' missing.");
          return "❌ No response from chatbot.";
        }

      } else {
        print("❌ Chatbot API error: ${response.body}");
        return "❌ Server error: ${response.statusCode} → ${response.body}";
      }
    } catch (e) {
      print("⚠️ Exception during chatbot request: $e");
      return "❌ Error: Something went wrong while contacting the chatbot.";
    }
  }
}

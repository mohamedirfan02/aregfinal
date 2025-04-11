// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';
//
// class ApiService {
//   static const String baseUrl = "http://10.0.2.2:8000/api/update-oil-sale/1";
//
//   // ✅ Update Oil Sale Status
//   static Future<bool> updateOilSale({
//     required int orderId,
//     required String paymentMethod,
//     required String amount,
//     required int agentId,
//     required BuildContext context,
//   }) async {
//     final String apiUrl = "$baseUrl/update-oil-sale/$orderId";
//
//     final Map<String, dynamic> requestData = {
//       "payment_method": paymentMethod,
//       "agent_id": agentId,
//       "amount": amount,
//       "status": "confirmed",
//     };
//
//     try {
//       String token = "your_access_token"; // Replace with actual token retrieval logic
//
//       print("🔹 Sending Request to API: $apiUrl");
//       print("📦 Request Body: ${jsonEncode(requestData)}");
//
//       final response = await http.post(
//         Uri.parse(apiUrl),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode(requestData),
//       );
//
//       print("🔹 API Response Status Code: ${response.statusCode}");
//       print("📩 API Response Body: ${response.body}");
//
//       if (response.statusCode == 200) {
//         final responseData = jsonDecode(response.body);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(responseData["message"])),
//         );
//         return true;
//       } else {
//         print("❌ API Error: ${response.body}");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Error: ${response.body}")),
//         );
//         return false;
//       }
//     } catch (e) {
//       print("❌ Exception Occurred: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Failed to update order: $e")),
//       );
//       return false;
//     }
//   }
// }

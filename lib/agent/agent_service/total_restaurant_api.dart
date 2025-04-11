import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<List<Restaurant>> fetchRestaurants() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString("token");

  const String apiUrl = 'https://enzopik.thikse.in/api/fbo/all';

  debugPrint("🔹 Token: $token");

  final response = await http.get(
    Uri.parse(apiUrl),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  debugPrint("🔹 Response Status: ${response.statusCode}");
  debugPrint("🔹 Raw Response Body: ${response.body}");

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body)['data'];
    debugPrint("🔹 Parsed Data Count: ${data.length}");
    for (var item in data) {
      debugPrint("🔹 Restaurant Item: $item");
    }
    return data.map((json) => Restaurant.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load restaurants');
  }
}

class Restaurant {
  final int id;
  final String fullName;
  final String restaurantName;
  final String category;
  final String countryCode;
  final String contactNumber;
  final String email;
  final String licenseNumber;
  final String address;
  final String licenseUrl;
  final String restaurantUrl;
  final String status;

  Restaurant({
    required this.id,
    required this.fullName,
    required this.restaurantName,
    required this.category,
    required this.countryCode,
    required this.contactNumber,
    required this.email,
    required this.licenseNumber,
    required this.address,
    required this.licenseUrl,
    required this.restaurantUrl,
    required this.status,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      fullName: json['full_name'],
      restaurantName: json['restaurant_name'],
      category: json['category'],
      countryCode: json['country_code'],
      contactNumber: json['contact_number'],
      email: json['email'],
      licenseNumber: json['license_number'],
      address: json['address'],
      licenseUrl: json['license_url'],
      restaurantUrl: json['restaurant_url'],
      status: json['status'],
    );
  }
}

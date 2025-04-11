import 'dart:convert';

class Fbo {
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
  final DateTime createdAt;
  final DateTime updatedAt;

  Fbo({
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
    required this.createdAt,
    required this.updatedAt,
  });

  factory Fbo.fromJson(Map<String, dynamic> json) {
    return Fbo(
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
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

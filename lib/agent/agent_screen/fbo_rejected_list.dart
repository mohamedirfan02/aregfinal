import 'dart:convert';
import 'package:areg_app/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FboRejectedList extends StatelessWidget {
  const FboRejectedList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : const Color(0xFF006D04),
        centerTitle: true,
        elevation: 4,
        title: Text(
          'Rejected FBOs',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.white, // Keep white for consistency
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FutureBuilder<List<Fbo>>(
        future: ApiService.fetchRejectedFbos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No rejected FBOs found.'));
          } else {
            final fbos = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: fbos.length,
              itemBuilder: (context, index) {
                final fbo = fbos[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.black.withOpacity(0.1),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fbo.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow('User ID', fbo.userId),
                      _buildDetailRow('Restaurant Name', fbo.restaurantName),
                      _buildDetailRow('Category', fbo.category),
                      _buildDetailRow('Contact Number', fbo.contactNumber),
                      _buildDetailRow('Email', fbo.email),
                      _buildDetailRow('License Number', fbo.licenseNumber),
                      _buildDetailRow('Address', fbo.address),
                      _buildDetailRow('Bank Name', fbo.bankName),
                      _buildDetailRow('Account No', fbo.accountNo),
                      _buildDetailRow('Status', fbo.status),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Flexible(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("License Image",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  if (fbo.licenseUrl.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        // Navigate to full-screen image view
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                FullScreenImage(
                                                    imageUrl: fbo.licenseUrl),
                                          ),
                                        );
                                      },
                                      child: Image.network(
                                        fbo.licenseUrl,
                                        height: 150,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Icon(Icons.error,
                                              size: 50, color: Colors.red);
                                        },
                                      ),
                                    ),
                                ]),
                          ),
                          const SizedBox(width: 16),
                          Flexible(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Restaurant Image",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  if (fbo.restaurantUrl.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        // Navigate to full-screen image view
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                FullScreenImage(
                                                    imageUrl:
                                                        fbo.restaurantUrl),
                                          ),
                                        );
                                      },
                                      child: Image.network(
                                        fbo.restaurantUrl,
                                        height: 150,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Icon(Icons.error,
                                              size: 50, color: Colors.red);
                                        },
                                      ),
                                    ),
                                ]),
                          )
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Color(0xFF006D04)),
            ),
          ),
        ],
      ),
    );
  }
}
// api_service.dart

class ApiService {
  static const String apiUrl = ApiConfig.getRejectedFbo;

  static Future<List<Fbo>> fetchRejectedFbos() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      if (token == null || token.isEmpty) {
        throw Exception('Token is missing');
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = json.decode(response.body);
        final List<dynamic> data =
            jsonBody['data']; // Adjust key based on actual response
        return data.map((json) => Fbo.fromJson(json)).toList();
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("Exception caught in fetchRejectedFbos: $e");
      rethrow;
    }
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Full Screen Image')),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}

// fbo_model.dart

class Fbo {
  final int id;
  final String userId;
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
  final String bankName;
  final String accountNo;
  final String createdAt;
  final String updatedAt;

  Fbo({
    required this.id,
    required this.userId,
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
    required this.bankName,
    required this.accountNo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Fbo.fromJson(Map<String, dynamic> json) {
    return Fbo(
      id: json['id'],
      userId: json['user_id'],
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
      bankName: json['bank_name'],
      accountNo: json['account_no'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

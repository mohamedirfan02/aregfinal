import 'dart:convert';
import 'package:areg_app/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';

// Updated Vendor model with 'location' field
class Vendor {
  final int id;
  final String fullName;
  final String dob;
  final String age;
  final String gender;
  final String countryCode;
  final String contactNumber;
  final String email;
  final String createdAt;
  final String updatedAt;
  final String location;
  final String licenseNumber;
  final String pincode;
  final String address;
  final String profile;

  Vendor({
    required this.id,
    required this.fullName,
    required this.dob,
    required this.age,
    required this.gender,
    required this.countryCode,
    required this.contactNumber,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    required this.location,
    required this.licenseNumber,
    required this.pincode,
    required this.address,
    required this.profile,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      dob: json['dob'] ?? '',
      age: json['age'] ?? '',
      gender: json['gender'] ?? '',
      countryCode: json['country_code'] ?? '',
      contactNumber: json['contact_number'] ?? '',
      email: json['email'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      location: json['location'] ?? 'Unknown',
      licenseNumber: json['license_number'] ?? 'N/A',
      pincode: json['pincode'] ?? 'N/A',
      address: json['address'] ?? 'N/A',
      profile: json['profile'] ?? '',
    );
  }
}


// API fetch
Future<List<Vendor>> fetchVendors() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString("token");
  const String apiUrl = ApiConfig.AllAgent;

  final response = await http.get(
    Uri.parse(apiUrl),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  debugPrint("🔹 Response Status: ${response.statusCode}");
  debugPrint("🔹 Raw Response Body: ${response.body}");

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);
    debugPrint("✅ Decoded Response: $decoded");

    if (decoded['data'] != null && decoded['data'] is List) {
      final List<dynamic> data = decoded['data'];
      debugPrint("📦 Vendor Count: ${data.length}");
      return data.map((json) => Vendor.fromJson(json)).toList();
    } else {
      debugPrint("⚠️ Unexpected data format: ${decoded.runtimeType}");
      return [];
    }
  } else {
    debugPrint("❌ Failed to load vendors: ${response.statusCode}");
    throw Exception('Failed to load vendors');
  }
}


// Main widget 192.168.0.156:8000
class VendorList extends StatefulWidget {
  const VendorList({super.key});

  @override
  State<VendorList> createState() => _VendorListState();
}

class _VendorListState extends State<VendorList> {
  late Future<List<Vendor>> futureVendors;
  List<Vendor> allVendors = [];
  List<Vendor> filteredVendors = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    futureVendors = fetchVendors();
    _searchController.addListener(_filterVendors);
  }

  void _filterVendors() {
    String search = _searchController.text.toLowerCase();
    setState(() {
      filteredVendors = allVendors.where((vendor) {
        return vendor.fullName.toLowerCase().contains(search) ||
            vendor.location.toLowerCase().contains(search);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F4F8),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : AppColors.secondaryColor,
        centerTitle: true,
        elevation: 4,
        title: Text(
          'Agents List',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FutureBuilder<List<Vendor>>(
        future: futureVendors,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('❌ Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No Agent found'));
          } else {
            allVendors = snapshot.data!;
            if (_searchController.text.isEmpty) {
              filteredVendors = allVendors;
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Search by name or location...',
                      labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                      prefixIcon: Icon(Icons.search, color: isDark ? Colors.white70 : Colors.black54),
                      filled: true,
                      fillColor: isDark ? Colors.grey[850] : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredVendors.length,
                    itemBuilder: (context, index) {
                      final v = filteredVendors[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: isDark ? Colors.grey[900] : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.transparent
                                  : Colors.grey.shade300,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundImage: v.profile.isNotEmpty
                                        ? NetworkImage(v.profile)
                                        : null,
                                    backgroundColor: AppColors.secondaryColor,
                                    child: v.profile.isEmpty
                                        ? const Icon(Icons.person, color: Colors.white)
                                        : null,
                                  ),

                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      v.fullName,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              InfoRow(label: 'DOB', value: v.dob),
                              InfoRow(label: 'Age', value: v.age),
                              InfoRow(label: 'Gender', value: v.gender),
                              InfoRow(label: 'Email', value: v.email),
                              InfoRow(label: 'Phone', value: '${v.countryCode} ${v.contactNumber}'),
                              InfoRow(label: 'License No', value: v.licenseNumber),
                              InfoRow(label: 'Pincode', value: v.pincode),
                              InfoRow(label: 'Address', value: v.address),
                              InfoRow(label: 'Created At', value: v.createdAt),
                              InfoRow(label: 'Updated At', value: v.updatedAt),

                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


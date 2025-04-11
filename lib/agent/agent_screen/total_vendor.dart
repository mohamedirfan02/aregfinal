import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Model class for Vendor
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
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'],
      fullName: json['full_name'],
      dob: json['dob'],
      age: json['age'],
      gender: json['gender'],
      countryCode: json['country_code'],
      contactNumber: json['contact_number'],
      email: json['email'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}


// Function to fetch vendor data from API
Future<List<Vendor>> fetchVendors() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString("token");
  const String apiUrl = 'https://enzopik.thikse.in/api/agent/all';

  final response = await http.get(
    Uri.parse(apiUrl),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body)['data'];
    return data.map((json) => Vendor.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load vendors');
  }
}

// Widget to display the list of vendors

class VendorList extends StatefulWidget {
  const VendorList({super.key});

  @override
  State<VendorList> createState() => _VendorListState();
}

class _VendorListState extends State<VendorList> {
  late Future<List<Vendor>> futureVendors;

  @override
  void initState() {
    super.initState();
    futureVendors = fetchVendors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        title: const Text('Agent List'),
        backgroundColor: Colors.deepPurple,
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
            final vendors = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vendors.length,
              itemBuilder: (context, index) {
                final v = vendors[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
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
                            const CircleAvatar(
                              backgroundColor: Colors.deepPurple,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                v.fullName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
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
                        InfoRow(label: 'Created', value: v.createdAt.split('T').first),
                        InfoRow(label: 'Updated', value: v.updatedAt.split('T').first),
                      ],
                    ),
                  ),
                );
              },
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
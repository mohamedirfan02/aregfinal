import 'package:flutter/material.dart';
import 'auth/logout_function.dart';

class VendorPage extends StatelessWidget {
  final Map<String, dynamic>? vendorDetails; // Allow null values

  const VendorPage({super.key, required this.vendorDetails});

  @override
  Widget build(BuildContext context) {
    if (vendorDetails == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vendor Details')),
        body: const Center(child: Text('No vendor details available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome ${vendorDetails!['full_name'] ?? 'Vendor'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              logout(context); // Logout function
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Full Name: ${vendorDetails!['full_name'] ?? 'Not available'}'),
            Text('Email: ${vendorDetails!['email'] ?? 'Not available'}'),
            Text('Date of Birth: ${vendorDetails!['dob'] ?? 'Not available'}'),
            Text('Age: ${vendorDetails!['age'] ?? 'Not specified'}'),
            Text('Gender: ${vendorDetails!['gender'] ?? 'Not specified'}'),
            Text('Contact Number: ${vendorDetails!['contact_number'] ?? 'Not specified'}'),
          ],
        ),
      ),
    );
  }
}


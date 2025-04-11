// import 'package:flutter/material.dart';
//
// import 'auth/logout_function.dart';
// class UserPage extends StatelessWidget {
//   final Map<String, dynamic>? userDetails; // Allow null values
//
//   const UserPage({super.key, required this.userDetails});
//
//   @override
//   Widget build(BuildContext context) {
//     if (userDetails == null) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('User Details')),
//         body: const Center(child: Text('No user details available')),
//       );
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Welcome ${userDetails!['full_name'] ?? 'User'}'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () {
//               logout(context); // Logout function
//             },
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Full Name: ${userDetails!['full_name'] ?? 'Not available'}'),
//             Text('Email: ${userDetails!['email'] ?? 'Not available'}'),
//             Text('Date of Birth: ${userDetails!['dob'] ?? 'Not available'}'),
//             Text('Gender: ${userDetails!['gender'] ?? 'Not available'}'),
//             Text('Contact Number: ${userDetails!['contact_number'] ?? 'Not available'}'),
//             Text('License Number: ${userDetails!['license_number'] ?? 'Not available'}'),
//             Text('Address: ${userDetails!['address'] ?? 'Not available'}'),
//           ],
//         ),
//       ),
//     );
//   }
// }
//

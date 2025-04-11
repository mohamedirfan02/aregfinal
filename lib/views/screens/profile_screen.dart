import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../common/custom_GradientContainer.dart';
import '../auth/reset_password.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic>? userDetails; // Allow null values

  const ProfileScreen({super.key, required this.userDetails});

  @override
  Widget build(BuildContext context) {
    final details = userDetails ?? {}; // Ensure it's not null
    const Color primaryTextColor = Color(0xFF292E10); // Define the color once

    return Scaffold(
      body:  Column(
          children: [
            // Top Section with Profile Info
            Padding(
              padding: const EdgeInsets.only(top: 50, bottom: 20),
              child: Column(
                children: [
                  // Profile Title
                  const Text(
                    'Profile',
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: primaryTextColor),
                  ),
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/image/profile.jpg'), // Change this
                    backgroundColor: Colors.grey,
                  ),
                  const SizedBox(height: 10),
                  // Name
                  Text(
                    details['full_name'] ?? 'K.S Restaurant',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTextColor),
                  ),
                  // Email
                  Text(
                    details['email'] ?? 'Thikse123@gmail.com',
                    style: const TextStyle(fontSize: 16, color: primaryTextColor),
                  ),
                  // Contact Number
                  Text(
                    details['contact_number'] ?? '9874563210',
                    style: const TextStyle(fontSize: 16, color: primaryTextColor),
                  ),
                ],
              ),
            ),

            // Profile Settings List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                  const Text(
                    "Profile Settings",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),

                  _buildSettingsTile("Edit profile", LucideIcons.user, context, primaryTextColor, null),
                  _buildSettingsTile("Change password", LucideIcons.lock, context, primaryTextColor,
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) =>  ResetPasswordScreen()))),
                  _buildSettingsTile("Add a payment method", LucideIcons.plusCircle, context, primaryTextColor, null),
                  _buildSettingsTile("Help Centre", LucideIcons.helpCircle, context, primaryTextColor, null),
                ],
              ),
            ),
          ],
        ),
    );
  }

  // Function to create a profile setting tile with navigation support
  Widget _buildSettingsTile(String title, IconData icon, BuildContext context, Color color, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(fontSize: 16, color: color)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
      onTap: onTap ?? () {}, // If no action is provided, do nothing
    );
  }
}

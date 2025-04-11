import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/custom_GradientContainer.dart';
import '../../views/auth/reset_password.dart';

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key, required Map userDetails});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  Map<String, dynamic> vendorDetails = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVendorDetails();
  }

  Future<void> _loadVendorDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      vendorDetails = {
        "full_name": prefs.getString('full_name') ?? 'K.S Restaurant',
        "email": prefs.getString('email') ?? 'Thikse123@gmail.com',
        "dob": prefs.getString('dob') ?? 'Not available',
        "age": prefs.getString('age') ?? 'Not specified',
        "gender": prefs.getString('gender') ?? 'Not specified',
        "contact_number": prefs.getString('contact_number') ?? '9874563210',
      };
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTextColor = Color(0xFF292E10);

    return Scaffold(
      body: Center(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            // Top Section with Profile Info
            Padding(
              padding: const EdgeInsets.only(top: 50, bottom: 20),
              child: Column(
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: primaryTextColor),
                  ),
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/image/profile.jpg'),
                    backgroundColor: Colors.grey,
                  ),
                  const SizedBox(height: 10),
                  // Full Name
                  Text(
                    vendorDetails['full_name'],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTextColor),
                  ),
                  // Email
                  Text(
                    vendorDetails['email'],
                    style: const TextStyle(fontSize: 16, color: primaryTextColor),
                  ),
                  // Contact Number
                  Text(
                    vendorDetails['contact_number'],
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

                  _buildSettingsTile("Edit Profile", LucideIcons.user, context, primaryTextColor, null),
                  _buildSettingsTile(
                    "Change Password",
                    LucideIcons.lock,
                    context,
                    primaryTextColor,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => ResetPasswordScreen())),
                  ),
                  _buildSettingsTile("Add a Payment Method", LucideIcons.plusCircle, context, primaryTextColor, null),
                  _buildSettingsTile("Help Centre", LucideIcons.helpCircle, context, primaryTextColor, null),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to create a profile setting tile with navigation support
  Widget _buildSettingsTile(String title, IconData icon, BuildContext context, Color color, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(fontSize: 16, color: color)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
      onTap: onTap ?? () {},
    );
  }
}

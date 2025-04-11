import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import '../../agent/common/agent_appbar.dart';
import '../../common/app_colors.dart';
import '../../common/custom_GradientContainer.dart';
import '../../common/custom_appbar.dart';
import '../../common/custom_home_appbar.dart';
import '../auth/logout_function.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Scaffold(
        backgroundColor: Colors.transparent,
        appBar:  CustomHomeAppBar(screenWidth: screenWidth,),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
               CustomHeadline(text: "Settings"), // ✅ Centered headline
              const SizedBox(height: 10),
              const Text(
                "Account Settings",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              _buildListTile("About Us", Icons.arrow_forward_ios, AppColors.darkGreen, onTap: () {}),
              _buildListTile("Privacy Policy", Icons.arrow_forward_ios, AppColors.darkGreen, onTap: () {}),
              _buildListTile("Terms and Conditions", Icons.add, AppColors.darkGreen, onTap: () {}),
              _buildListTile("Language", Icons.arrow_forward_ios, AppColors.darkGreen, onTap: () {}),
              _buildSwitchTile("Notifications", true),
              _buildSwitchTile("Dark mode", false),
              const Divider(height: 30),
              _buildListTile(
                "Logout",
                Icons.logout,
                AppColors.darkGreen,
                isLogout: true,
                onTap: () => logout(context), // ✅ Added logout function
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(
      String title,
      IconData icon,
      Color textColor, {
        bool isLogout = false,
        required VoidCallback onTap,
      }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor, // ✅ Applied correct color
        ),
      ),
      trailing: Icon(icon, color: textColor),
      onTap: onTap, // ✅ Logout function assigned here
    );
  }

  Widget _buildSwitchTile(String title, bool value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.darkGreen, // ✅ Applied darkGreen to switch text
        ),
      ),
      trailing: Switch(
        value: value,
        activeColor: AppColors.primaryGreen,
        onChanged: (newValue) {},
      ),
    );
  }

  // Future<void> logout(BuildContext context) async {
  //   try {
  //     // Retrieve the token from SharedPreferences
  //     SharedPreferences prefs = await SharedPreferences.getInstance();
  //     String? token = prefs.getString('token');
  //
  //     if (token != null) {
  //       // Notify the server to revoke the token
  //       final response = await http.post(
  //         Uri.parse("https://a85b-2409-40f4-1129-f07a-a167-64a3-5ed0-a898.ngrok-free.app/api/auth/logout"),
  //         headers: {
  //           "Content-Type": "application/json",
  //           "Authorization": "Bearer $token"
  //         },
  //       );
  //
  //       if (response.statusCode == 200) {
  //         // If logout is successful, remove the token
  //         await prefs.remove('token');
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Logout successful')),
  //         );
  //         // Navigate to the login page
  //         context.go('/login');
  //       } else {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Logout failed. Please try again')),
  //         );
  //       }
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('No token found. Please log in again')),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error during logout: $e')),
  //     );
  //   }
  // }
}

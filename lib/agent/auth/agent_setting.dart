import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import '../../common/app_colors.dart';
import '../../common/custom_GradientContainer.dart';
import '../../common/custom_appbar.dart';
import '../../common/custom_home_appbar.dart';
import '../../vendor_app/comman/vendor_appbar.dart';
import '../../views/auth/logout_function.dart';

class AgentSettingsScreen extends StatelessWidget {
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
}

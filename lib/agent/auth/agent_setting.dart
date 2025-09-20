import 'package:areg_app/views/screens/privacy_policy_screen.dart';
import 'package:flutter/material.dart';
import '../../common/app_colors.dart';
import '../../views/auth/logout_function.dart';
import '../common/common_appbar.dart';

class AgentSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppbar(title: 'Account Settings'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    _buildListTile("About Us", Icons.arrow_forward_ios,
                        AppColors.titleColor,
                        onTap: () {}),
                    _buildListTile(
                      "Privacy Policy",
                      Icons.arrow_forward_ios,
                      AppColors.titleColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen()),
                        );
                      },
                    ),
                    _buildListTile(
                        "Terms and Conditions", Icons.add, AppColors.titleColor,
                        onTap: () {}),
                    _buildListTile("Language", Icons.arrow_forward_ios,
                        AppColors.titleColor,
                        onTap: () {}),
                    const Divider(height: 30),
                    _buildListTile(
                      "Logout",
                      Icons.logout,
                      AppColors.titleColor,
                      isLogout: true,
                      onTap: () => logout(context),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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

  Widget _buildSwitchTile(
      String title, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.darkGreen,
        ),
      ),
      trailing: Switch(
        value: value,
        activeColor: AppColors.secondaryColor,
        onChanged: onChanged,
      ),
    );
  }
}

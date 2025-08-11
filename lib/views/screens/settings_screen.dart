import 'dart:io';

import 'package:areg_app/views/screens/privacy_policy_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/app_colors.dart';
import '../../common/custom_appbar.dart';
import '../../config/api_config.dart';
import '../../theme/ThemeNotifier.dart';
import '../../vendor_app/comman/vendor_appbar.dart';
import '../auth/logout_function.dart';
import 'language_screen.dart';

class SettingsScreen extends StatelessWidget {
  Future<void> downloadContractPDF(BuildContext context) async {
    try {
      print("🚀 Starting contract download (POST method)...");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userIdString = prefs.getString('user_id');
      final userId = int.tryParse(userIdString ?? '');


      if (userId == null || token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User info not found")),
        );
        return;
      }

      final url = ApiConfig.fbo_contract_pdf(userId);
      final dio = Dio();

      print("📥 Download URL (POST): $url");
      print("🔐 Token: $token");

      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/contract_$userId.pdf";

      final response = await dio.post(
        url,
        data: {"id": userId}, // Optional if backend needs it
        options: Options(
          headers: {"Authorization": "Bearer $token"},
          responseType: ResponseType.bytes,
        ),
      );

      print("📥 Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.data);
        print("✅ File written to $filePath");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Download complete! Opening...")),
        );
        OpenFilex.open(filePath);
      } else {
        print("❌ Failed to download file. Response: ${response.data}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to download contract. Status: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("❌ Download error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: $e")),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(),
      ),
        body: SingleChildScrollView(
          child: Padding(
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
                _buildListTile(
                    "About Us", Icons.arrow_forward_ios, AppColors.darkGreen,
                    onTap: () {}),
                _buildListTile(
                  "Privacy Policy",
                  Icons.arrow_forward_ios,
                  AppColors.darkGreen,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen()),
                    );
                  },
                ),
                _buildListTile(
                  "Tap to download contract",
                  Icons.download,
                  AppColors.darkGreen,
                  onTap: () => downloadContractPDF(context),
                ),

                _buildListTile(
                    "Language", Icons.arrow_forward_ios, AppColors.darkGreen,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LanguageScreen()),
                    );
                  },),
                // Consumer<ThemeNotifier>(
                //   builder: (context, themeNotifier, _) {
                //     final isDark = themeNotifier.themeMode == ThemeMode.dark;
                //     return _buildSwitchTile(
                //       "Dark mode",
                //       isDark,
                //           (value) {
                //         themeNotifier.toggleTheme(value);
                //       },
                //     );
                //   },
                // ),
          
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

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) {
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
        activeColor: AppColors.primaryGreen,
        onChanged: onChanged,
      ),
    );
  }

}

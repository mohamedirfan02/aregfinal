import 'dart:convert';
import 'package:areg_app/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../agent/common/common_appbar.dart';
import '../../config/api_config.dart';
import '../../views/auth/reset_password.dart';
import '../../views/dashboard/edit_profile_screen.dart';
import '../../views/screens/chatbot_screen.dart';

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
    fetchProfileData();
  }

  Future<void> fetchProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? id = prefs.getString('userId');
    String? role = prefs.getString('role');

    if (token == null || id == null || role == null) {
      print("Token or user ID missing.");
      return;
    }

    final url = Uri.parse(ApiConfig.getProfileData);

    final body = jsonEncode({
      "role": role,
      "id": int.tryParse(id),
    });

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body);
      final data = body['data']; // Fix here

      setState(() {
        vendorDetails = {
          "full_name": data['full_name'] ?? '',
          "email": data['email'] ?? '',
          "contact_number": data['contact_number'] ?? '',
          "profile": data['profile'] ?? '',
        };
        isLoading = false;
      });
    } else {
      print("❌ Failed to load profile: ${response.statusCode}");
      print(response.body);
      setState(() => isLoading = false);
    }
  }

  Future<void> submitFeedback(String feedbackText) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? Id = prefs.getString('userId'); // String expected
    String? role = prefs.getString('role'); // String expected

    if (token == null || Id == null) {
      print("Token or vendor ID missing.");
      return;
    }

    final url = Uri.parse(ApiConfig.AddFeedback);

    final body = jsonEncode({
      "role": role,
      "id": int.tryParse(Id),
      "feedback": feedbackText,
    });

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("✅ Feedback submitted successfully!");
    } else {
      print("❌ Failed to submit feedback: ${response.statusCode}");
      print(response.body);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTextColor = AppColors.primaryColor;
    return Scaffold(
      appBar: CommonAppbar(title: 'Profile'),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 1.w,
                        color: AppColors.greyColor.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(8.r),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: AppColors.cardGradientColor,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 50, bottom: 20),
                      child: Column(
                        children: [
                          const Text(
                            'Profile',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                          ),
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey,
                            backgroundImage: vendorDetails['profile'] != null && vendorDetails['profile'].isNotEmpty
                                ? NetworkImage(vendorDetails['profile'])
                                : const AssetImage('assets/image/profile.jpg') as ImageProvider,
                          ),

                          const SizedBox(height: 10),
                          Text(
                            vendorDetails['full_name'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                          ),
                          Text(
                            vendorDetails['email'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                          ),
                          Text(
                            vendorDetails['contact_number'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 16,
                              color: primaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Profile Settings",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildSettingsTile(
                          "Edit Profile",
                          LucideIcons.user,
                          context,
                          primaryTextColor,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfileScreen(),
                            ),
                          ),
                        ),
                        _buildSettingsTile(
                          "Change Password",
                          LucideIcons.lock,
                          context,
                          primaryTextColor,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ForgotPasswordScreen(),
                            ),
                          ),
                        ),
                        _buildSettingsTile(
                          "Help Center",
                          LucideIcons.helpCircle,
                          context,
                          primaryTextColor,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChatbotScreen(),
                            ),
                          ),
                        ),
                        _buildSettingsTile(
                          "Feedback",
                          Icons.feedback_outlined,
                          context,
                          primaryTextColor,
                          () => _showFeedback(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showFeedback(BuildContext context) {
    final TextEditingController feedbackController = TextEditingController();
    int selectedRating = -1; // No selection by default

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Rate your experience"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(5, (index) {
                        IconData icon;
                        Color color;

                        switch (index) {
                          case 0:
                            icon = Icons.sentiment_very_dissatisfied;
                            color = Colors.red;
                            break;
                          case 1:
                            icon = Icons.sentiment_dissatisfied;
                            color = Colors.deepOrange;
                            break;
                          case 2:
                            icon = Icons.sentiment_neutral;
                            color = Colors.yellow;
                            break;
                          case 3:
                            icon = Icons.sentiment_very_satisfied;
                            color = Colors.green;
                            break;
                          case 4:
                            icon = Icons.favorite;
                            color = Colors.pink;
                            break;
                          default:
                            icon = Icons.sentiment_neutral;
                            color = Colors.grey;
                        }

                        return IconButton(
                          icon: Icon(
                            icon,
                            color: selectedRating == index
                                ? color
                                : Colors.grey.shade400,
                            size: 30,
                          ),
                          onPressed: () {
                            setState(() {
                              selectedRating = index;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child:
                          Text("Thanks, what is the reason for your rating?"),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: feedbackController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: "Add your feedback",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel",
                      style: TextStyle(
                          color: Colors.black45, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final feedback = feedbackController.text.trim();
                    if (feedback.isNotEmpty) {
                      submitFeedback(feedback);
                    }
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF006D04)),
                  child: const Text("Submit",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      )),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsTile(String title, IconData icon, BuildContext context,
      Color color, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(fontSize: 16, color: color)),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
      onTap: onTap ?? () {},
    );
  }
}

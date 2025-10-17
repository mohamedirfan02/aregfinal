import 'dart:convert';

import 'package:areg_app/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../agent/common/common_appbar.dart';
import '../../config/api_config.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String role;
  late Map<String, dynamic> details;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    details = {};
    role = '';
    fetchProfileDetails();
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

  Future<void> fetchProfileDetails() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? userId = prefs.getString('userId');
      String? storedRole = prefs.getString('role');

      if (token == null || userId == null) {
        print("Token or user ID missing.");
        return;
      }

      final url = Uri.parse(ApiConfig.getProfileData);
      final body = jsonEncode({
        "role": storedRole,
        "id": int.tryParse(userId),
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

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final profileData = jsonData['data'];
        setState(() {
          details = profileData ?? {};
          role = storedRole ?? 'unknown';
          isLoading = false;
        });
      } else {
        print("❌ Failed to fetch profile: ${response.statusCode}");
        print(response.body);
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("❌ Exception: $e");
      setState(() => isLoading = false);
    }
  }

  // Show full screen image popup
  void _showImagePopup(BuildContext context) {
    final imageUrl = details['restaurant_url'];

    if (imageUrl == null || imageUrl.isEmpty) {
      // Show default image popup
      _showDefaultImagePopup(context);
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              // Tap anywhere to close
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  color: Colors.transparent,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              // Image container
              Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 3.0,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey[900],
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.white70,
                                  size: 50,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              // Close button
              Positioned(
                top: 50,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Show default image popup
  void _showDefaultImagePopup(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              // Tap anywhere to close
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  color: Colors.transparent,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              // Default image container
              Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 3.0,
                      child: Image.asset(
                        'assets/image/profile.png',
                        width: 300,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              // Close button
              Positioned(
                top: 50,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTextColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: CommonAppbar(title: "Profile"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [

          Center(
            child: Column(
              children: [


                // ✅ Name - Centered without label
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
                  child: Column(
                    children: [
                      Text(
                        'Profile',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Profile Image with tap functionality
                      GestureDetector(
                        onTap: () => _showImagePopup(context),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: details['restaurant_url'] != null
                                ? NetworkImage(details['restaurant_url'])
                                : const AssetImage('assets/image/profile.jpg') as ImageProvider,
                            onBackgroundImageError: (exception, stackTrace) {
                              print("Image Load Error: $exception");
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        role == 'user'
                            ? (details['restaurant_name'] ?? 'Restaurant Name')
                            : (details['full_name'] ?? 'Your Name'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      // ✅ Email - Centered without label
                      Text(
                        details['email'] ?? 'Your Email ID',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // ✅ FSSAI No for 'user', Gender for others - Centered without label
                      Text(
                        role == 'user'
                            ? (details['license_number'] ?? 'N/A')
                            : (details['gender'] ?? 'N/A'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // ✅ Contact Number - Centered without label
                      Text(
                        details['contact_number'] ?? 'Phone No',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),


              ],
            ),
          ),

          const SizedBox(height: 30),
          Text(
            "Profile Settings",
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.hintColor,
            ),
          ),
          const SizedBox(height: 10),
          _buildSettingsTile(
            "Edit profile",
            LucideIcons.user,
            context,
            primaryTextColor,
                () => GoRouter.of(context).push('/edit-profile'),
          ),

          _buildSettingsTile(
            "Change password",
            LucideIcons.lock,
            context,
            primaryTextColor,
                () => GoRouter.of(context).push('/change-password'),
          ),

          if (role != 'agent')
            _buildSettingsTile(
              "Help Center",
              LucideIcons.helpCircle,
              context,
              primaryTextColor,
                  () => GoRouter.of(context).push('/chatbot'),
            ),

          _buildSettingsTile(
            "Feedback",
            Icons.feedback_outlined,
            context,
            primaryTextColor,
                () => _showFeedbackDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow({
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
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
                            color: selectedRating == index ? color : Colors.grey.shade400,
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
                      child: Text("Thanks, what is the reason for your rating?"),
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
                  child: const Text("Cancel",style: TextStyle(color: AppColors.titleColor,fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final feedback = feedbackController.text.trim();
                    if (feedback.isNotEmpty) {
                      submitFeedback(feedback);
                      Navigator.of(context).pop();

                      // Show snackbar after popping the dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Feedback submitted!"),
                          backgroundColor: AppColors.primaryColor,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
                  child: const Text(
                    "Submit",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsTile(String title, IconData icon, BuildContext context, Color iconColor, VoidCallback onTap) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.iconTheme.color),
      title: Text(title, style: theme.textTheme.bodyLarge),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
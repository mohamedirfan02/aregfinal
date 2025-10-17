import 'package:areg_app/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class NotificationSuggestionScreen extends StatefulWidget {
  const NotificationSuggestionScreen({super.key});

  @override
  State<NotificationSuggestionScreen> createState() =>
      _NotificationSuggestionScreenState();
}

class _NotificationSuggestionScreenState
    extends State<NotificationSuggestionScreen> {
  bool _isLoading = false;

  Future<void> _requestNotificationPermission() async {
    setState(() => _isLoading = true);

    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Request permission
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        String? token = await messaging.getToken();
        print('FCM Token: $token');

        // Save permission status
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notification_enabled', true);
        await prefs.setBool('notification_prompt_shown', true);
        await prefs.setString('fcm_token', token ?? '');

        // Show success message and navigate
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notifications enabled successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );

          // Navigate to location permission screen
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.go('/location-permission');
              }
            });
          }
        }
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification permission denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error requesting notification permission: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Illustration
              SizedBox(
                height: size.height * 0.35,
                child: Image.asset(
                  'assets/notification_illustration.png', // Add your illustration asset
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback icon if image not found
                    return Icon(
                      Icons.notifications_active_rounded,
                      size: 120,
                      color: AppColors.fboColor,
                    );
                  },
                ),
              ),

              const SizedBox(height: 40),

              // Title and description
              Text(
                'Get instant updates on your used oil pickups, collection status, and reminders by enabling notifications.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                  height: 1.5,
                  letterSpacing: 0.2,
                ),
              ),


              const Spacer(flex: 3),

              // Allow Notification Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _requestNotificationPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.fboColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    'ALLOW NOTIFICATION',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Skip button
              // TextButton(
              //   onPressed: _isLoading
              //       ? null
              //       : () {
              //     Navigator.of(context).pop();
              //   },
              //   child: Text(
              //     'Maybe Later',
              //     style: TextStyle(
              //       color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
              //       fontSize: 14,
              //     ),
              //   ),
              // ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
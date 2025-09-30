import 'package:areg_app/common/app_colors.dart';
import 'package:areg_app/core/storage/app_assets_constant.dart';
import 'package:areg_app/views/screens/widgets/k_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isLoading = false;

  Future<void> _requestLocationPermission() async {
    setState(() => _isLoading = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable location services'),
              backgroundColor: AppColors.greyColor,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission permanently denied. Please enable from settings.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Permission granted
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('location_enabled', true);
        await prefs.setBool('location_prompt_shown', true);

        // Get current location to verify
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        print('Location: ${position.latitude}, ${position.longitude}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location access granted!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );

          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.go('/start');
              }
            });
          }
        }
      }
    } catch (e) {
      print('Error requesting location permission: $e');
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

              // Location illustration
              SizedBox(
                height: size.height * 0.35,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Map background
                    Container(
                      width: size.width * 0.7,
                      height: size.width * 0.5,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child:  SizedBox(
                        height: size.height * 0.35,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Map background
                            KSvg(
                              svgPath: AppAssetsConstants.currentLocation,
                              height: 250.h,
                              width: 250.w,
                              boxFit: BoxFit.cover,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),


              const SizedBox(height: 40),

              // Description
              Text(
                'We need your location to schedule pickups and connect you with the nearest oil collection partner.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                  height: 1.5,
                  letterSpacing: 0.2,
                ),
              ),

              const Spacer(flex: 3),

              // Allow Location Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _requestLocationPermission,
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
                    'ALLOW LOCATION',
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
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('location_prompt_shown', true);

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      context.go('/start');
                    }
                  });
                },
                child: Text(
                  'Maybe Later',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

}

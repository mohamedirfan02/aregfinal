import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../fbo_services/appbar_api.dart';
import '../fbo_services/fbo_notification_service.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  String? restaurantName;
  String? restaurantImage;
  bool isLoading = true;
  int notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadRestaurantDetails();
    _loadNotificationCount();
  }

  Future<void> _loadRestaurantDetails() async {
    final apiService = ApiService();
    final restaurantData = await apiService.fetchRestaurantDetails();
    if (!mounted) return;
    if (restaurantData != null) {
      setState(() {
        restaurantName = restaurantData['retaurant_name'];
        restaurantImage = restaurantData['restaurant_image'];
        isLoading = false;
      });
    } else {
      setState(() {
        restaurantName = "Unknown";
        restaurantImage = null;
        isLoading = false;
      });
    }
  }

// 2. In your parent widget (where the notification icon is), modify the _loadNotificationCount method:
  Future<void> _loadNotificationCount() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationService = FboNotificationService(); // Initialize your service
    final allNotifications = await notificationService.fetchNotifications() ?? [];

    int unreadCount = 0;
    for (var notification in allNotifications) {
      final messageId = notification['id']?.toString() ?? notification['title'];
      final isRead = prefs.getBool('read_$messageId') ?? false;
      if (!isRead) {
        unreadCount++;
      }
    }

    setState(() {
      notificationCount = unreadCount; // This will now only show unread notifications
    });
  }

  // Show full screen image popup
  void _showImagePopup(BuildContext context) {
    if (restaurantImage == null || restaurantImage!.isEmpty) {
      // Show default icon popup
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
                        restaurantImage!,
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
              // Restaurant name overlay
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    restaurantName ?? 'Restaurant',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
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

  // Show default icon popup when no image is available
  void _showDefaultImagePopup(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
              // Default icon container
              Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.restaurant,
                        size: 120,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        restaurantName ?? 'Restaurant',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'No image available',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor: isDarkMode ? Colors.black : const Color(0xFF006D04),
      elevation: 0,
      title: isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Restaurant image/icon with tap functionality
              GestureDetector(
                onTap: () => _showImagePopup(context),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: restaurantImage != null
                      ? ClipOval(
                    child: Image.network(
                      restaurantImage!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                    ),
                  )
                      : Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.restaurant,
                      size: 18,
                      color: isDarkMode ? Colors.white : Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200), // adjust as needed
                child: Text(
                  restaurantName ?? "Loading...",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Image.asset("assets/icon/cart.png",
                    width: 24, height: 24),
                onPressed: () {
                  GoRouter.of(context).push('/fbo-cart');
                },
              ),
              Stack(
                children: [
                  IconButton(
                    icon: Image.asset("assets/icon/bell.png",
                        width: 24, height: 24),
                    onPressed: () async {
                      await GoRouter.of(context).push('/fbo-notification');
                      _loadNotificationCount();
                    },
                  ),
                  if (notificationCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Center(
                          child: Text(
                            '$notificationCount',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
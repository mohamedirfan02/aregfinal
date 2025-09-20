import 'package:areg_app/common/app_colors.dart';
import 'package:flutter/material.dart';
import '../../fbo_services/fbo_notification_service.dart';
import '../../views/screens/user_notification.dart';


class CommonAppbar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  const CommonAppbar({super.key,required this.title,});

  @override
  _CommonAppbarState createState() => _CommonAppbarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CommonAppbarState extends State<CommonAppbar> {
  bool isLoading = true;
  int notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    final notifications = await FboNotificationService().fetchNotifications();
    if (!mounted) return;
    setState(() {
      notificationCount = notifications?.length ?? 0;
      isLoading = false; // ✅ Stop loading
    });
  }@override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Your existing green color for light mode
    final lightModeColor = AppColors.fboColor;

    // Black color for dark mode
    final darkModeColor = Colors.black;

    // Choose background color based on mode
    final backgroundColor = isDarkMode ? darkModeColor : lightModeColor;

    // For text and icons: white in dark mode, otherwise keep as is (white looks good on green)
    final iconTextColor = isDarkMode ? Colors.white : Colors.white;

    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      title: isLoading
          ? CircularProgressIndicator(color: iconTextColor)
          : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 22,
              color: iconTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              Stack(
                children: [
                  IconButton(
                    icon: Image.asset(
                      "assets/icon/bell.png",
                      width: 24,
                      height: 24,
                      color: iconTextColor,
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FboNotificationScreen(),
                        ),
                      );
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
                              color: Colors.white,
                              fontSize: 12,
                            ),
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

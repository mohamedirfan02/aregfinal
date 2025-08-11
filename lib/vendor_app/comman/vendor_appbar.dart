import 'package:flutter/material.dart';
import '../../common/app_colors.dart';
import '../../views/screens/user_notification.dart';

class VendorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onCartPressed;
  final VoidCallback? onNotificationPressed;

  const VendorAppBar({
    super.key,
    required this.title,
    this.onCartPressed,
    this.onNotificationPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor: isDark ? Colors.black : const Color(0xFF006D04),
      elevation: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.white70,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Image.asset("assets/icon/bell.png", width: 24, height: 24),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FboNotificationScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class CustomHeadline extends StatelessWidget {
  final String text;

  const CustomHeadline({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headlineColor = isDark ? Colors.white : AppColors.darkGreen;

    return Center(
      child: Text(
        text,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: headlineColor,
        ),
      ),
    );
  }
}

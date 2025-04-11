import 'package:flutter/material.dart';
import '../../common/app_colors.dart';

import '../vendor_screen/vendor_cart.dart';
import '../vendor_screen/vendor_notification.dart';

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
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const SizedBox(width: 5),
              Text(
                title, // ✅ Dynamic title
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Image.asset("assets/icon/cart.png", width: 24, height: 24),
                onPressed: () {
                  // ✅ Navigate to Notification Page
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => const VendorCartPage(),
                  //   ),
                  // );
                }, // ✅ Dynamic action
              ),
              IconButton(
                icon: Image.asset("assets/icon/bell.png", width: 24, height: 24),
                onPressed: () {
                  // ✅ Navigate to Notification Page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VendorNotificationPage(),
                    ),
                  );
                }, // ✅ Dynamic action
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

  CustomHeadline({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.darkGreen, // ✅ Use dark green
        ),
      ),
    );
  }
}

import 'package:areg_app/common/app_colors.dart';
import 'package:flutter/material.dart';
import '../../fbo_services/fbo_notification_service.dart';
import '../agent_screen/CartPage.dart';
import '../agent_screen/notification_page.dart';


class AgentAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;

  const AgentAppBar({
    super.key,
    required this.title,
  });

  @override
  _AgentAppBarState createState() => _AgentAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AgentAppBarState extends State<AgentAppBar> {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // final textColor = isDarkMode ? Colors.white : Colors.black;
    // final iconColor = isDarkMode ? Colors.white : Colors.black;
    final backgroundColor = isDarkMode ? Colors.grey[900] : AppColors.secondaryColor;

    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white, // You can also use textColor if needed
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Image.asset(
                  "assets/icon/cart.png",
                  width: 24,
                  height: 24,
                  color: Colors.white, // iconColor if you want it to change based on theme
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AgentCartPage()),
                  );
                },
              ),
              Stack(
                children: [
                  IconButton(
                    icon: Image.asset(
                      "assets/icon/bell.png",
                      width: 24,
                      height: 24,
                      color: Colors.white, // iconColor if you want it to change
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AgentNotificationPage()),
                      );
                      _loadNotificationCount(); // Refresh count
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
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        child: Center(
                          child: Text(
                            '$notificationCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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

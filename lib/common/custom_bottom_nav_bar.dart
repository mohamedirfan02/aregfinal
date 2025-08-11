import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      selectedItemColor: isDarkMode ? Colors.white : const Color(0xFF006D04),
      unselectedItemColor: isDarkMode ? Colors.white60 : Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: _buildIconWithIndicator(context, "assets/icon/chat.png", 0),
          label: "AI Chat",
        ),
        BottomNavigationBarItem(
          icon: _buildIconWithIndicator(context, "assets/icon/home.png", 1),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: _buildIconWithIndicator(context, "assets/icon/profile.png", 2),
          label: "Profile",
        ),
        BottomNavigationBarItem(
          icon: _buildIconWithIndicator(context, "assets/icon/setting.png", 3),
          label: "Settings",
        ),
      ],
    );
  }

  Widget _buildIconWithIndicator(BuildContext context, String assetPath, int index) {
    final isSelected = index == currentIndex;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final Color selectedColor = isDarkMode ? Colors.white : const Color(0xFF006D04);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 3,
          width: 28,
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 4),
        isSelected
            ? ColorFiltered(
          colorFilter: ColorFilter.mode(selectedColor, BlendMode.srcIn),
          child: Image.asset(assetPath, width: 28, height: 28),
        )
            : Image.asset(assetPath, width: 28, height: 28),
      ],
    );
  }
}

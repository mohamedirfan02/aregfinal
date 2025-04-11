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
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Colors.green, // ✅ Selected icon and label color
      unselectedItemColor: Colors.grey, // ✅ Unselected icon and label color
      type: BottomNavigationBarType.fixed, // ✅ Ensures labels are always visible
      items: [
        BottomNavigationBarItem(
          icon: _buildIcon("assets/icon/ai.png", 0),
          label: "AI Chat",
        ),
        BottomNavigationBarItem(
          icon: _buildIcon("assets/icon/home.png", 1),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: _buildIcon("assets/icon/profile.png", 2),
          label: "Profile",
        ),
        BottomNavigationBarItem(
          icon: _buildIcon("assets/icon/setting.png", 3),
          label: "Settings",
        ),
      ],
    );
  }

  /// ✅ Function to change icon color on tap
  Widget _buildIcon(String assetPath, int index) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        index == currentIndex ? Colors.green : Colors.grey, // Change color based on selection
        BlendMode.srcIn,
      ),
      child: Image.asset(assetPath, width: 28, height: 28),
    );
  }
}

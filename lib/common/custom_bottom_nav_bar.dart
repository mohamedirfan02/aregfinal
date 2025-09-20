// import 'package:flutter/material.dart';
//
// import 'app_colors.dart';
//
// class CustomBottomNavBar extends StatelessWidget {
//   final int currentIndex;
//   final Function(int) onTap;
//
//   const CustomBottomNavBar({
//     super.key,
//     required this.currentIndex,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;
//
//     return BottomNavigationBar(
//       currentIndex: currentIndex,
//       onTap: onTap,
//       backgroundColor: isDarkMode ? Colors.black : Colors.white,
//       selectedItemColor: isDarkMode ? Colors.white :AppColors.secondaryColor,
//       unselectedItemColor: isDarkMode ? Colors.white60 : Colors.grey,
//       type: BottomNavigationBarType.fixed,
//       items: [
//         BottomNavigationBarItem(
//           icon: _buildIconWithIndicator(context, "assets/icon/chat.png", 0),
//           label: "AI Chat",
//         ),
//         BottomNavigationBarItem(
//           icon: _buildIconWithIndicator(context, "assets/icon/home.png", 1),
//           label: "Home",
//         ),
//         BottomNavigationBarItem(
//           icon: _buildIconWithIndicator(context, "assets/icon/profile.png", 2),
//           label: "Profile",
//         ),
//         BottomNavigationBarItem(
//           icon: _buildIconWithIndicator(context, "assets/icon/setting.png", 3),
//           label: "Settings",
//         ),
//       ],
//     );
//   }
//
//   Widget _buildIconWithIndicator(BuildContext context, String assetPath, int index) {
//     final isSelected = index == currentIndex;
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;
//
//     final Color selectedColor = isDarkMode ? Colors.white : AppColors.secondaryColor;
//
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           height: 3,
//           width: 28,
//           decoration: BoxDecoration(
//             color: isSelected ? selectedColor : Colors.transparent,
//             borderRadius: BorderRadius.circular(2),
//           ),
//         ),
//         const SizedBox(height: 4),
//         Image.asset(
//           assetPath,
//           width: 28,
//           height: 28,
//           color: isSelected ? selectedColor : null, // 👈 Fill selected icon
//         ),
//       ],
//     );
//   }
// }
// Updated Custom Bottom Nav Bar
import 'package:flutter/material.dart';
import 'app_colors.dart';

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

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Regular nav items container
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Profile
              _buildNavItem(
                context,
                "assets/icon/profile.png",
                "Profile",
                0,
                isDarkMode,
              ),
              // Spacer for home button
              const SizedBox(width: 60),
              // Settings
              _buildNavItem(
                context,
                "assets/icon/setting.png",
                "Settings",
                2,
                isDarkMode,
              ),
            ],
          ),
          // Premium Home Button - Positioned in center
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 30,
            top: 5,
            child: _buildPremiumHomeButton(context, isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context,
      String assetPath,
      String label,
      int index,
      bool isDarkMode,
      ) {
    final isSelected = index == currentIndex;
    final Color selectedColor = isDarkMode ? Colors.white : AppColors.secondaryColor;
    final Color unselectedColor = isDarkMode ? Colors.white60 : Colors.grey;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top indicator bar
            Container(
              height: 3,
              width: 28,
              decoration: BoxDecoration(
                color: isSelected ? selectedColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            // Icon
            Image.asset(
              assetPath,
              width: 24,
              height: 24,
              color: isSelected ? selectedColor : unselectedColor,
            ),
            const SizedBox(height: 4),
            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? selectedColor : unselectedColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHomeButton(BuildContext context, bool isDarkMode) {
    final isSelected = currentIndex == 1;

    return GestureDetector(
      onTap: () => onTap(1),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [
              const Color(0xFF6A9600), // Purple
              const Color(0xFFC3E029), // Medium Purple
              const Color(0xFF2D8E11), // Medium Orchid
            ]
                : [
              Colors.grey.withOpacity(0.3),
              Colors.grey.withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFC3E029).withOpacity(0.4)
                  : Colors.black.withOpacity(0.1),
              blurRadius: isSelected ? 15 : 8,
              offset: const Offset(0, 4),
            ),
            if (isSelected)
              BoxShadow(
                color: const Color(0xFFC3E029).withOpacity(0.2),
                blurRadius: 25,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Inner glow effect
            if (isSelected)
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            // Home Icon
            Image.asset(
              "assets/icon/home.png",
              width: 28,
              height: 28,
              color: isSelected ? Colors.white : (isDarkMode ? Colors.white70 : Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:areg_app/vendor_app/vendor_screen/vendor_home.dart';
import 'package:areg_app/vendor_app/vendor_screen/vendor_profile.dart';
import '../../agent/auth/agent_setting.dart';
import '../../common/custom_bottom_nav_bar.dart';
import '../../views/screens/ai_chat_screen.dart';

class VendorBottomNavigation extends StatefulWidget {
  const VendorBottomNavigation({super.key});

  @override
  State<VendorBottomNavigation> createState() => _VendorBottomNavigationState();
}

class _VendorBottomNavigationState extends State<VendorBottomNavigation> {
  int _selectedIndex = 1; // ✅ Default to Home (Index 1)

  /// ✅ **Use PageStorage to Keep State & Improve Performance**
  final PageStorageBucket _bucket = PageStorageBucket();

  // ✅ **Keep pages alive to prevent rebuilds**
  final List<Widget> _pages = [
   //  AiChatScreen(),

    const VendorProfileScreen(userDetails: {}),
    const VendorHomeScreen(),
     AgentSettingsScreen(),
  ];

  void _onNavItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageStorage(
        bucket: _bucket,
        child: _pages[_selectedIndex], // ✅ Uses stored pages
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }
}

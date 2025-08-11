import 'package:flutter/material.dart';
import '../../agent/agent_home_screen.dart';
import '../../agent/auth/agent_setting.dart';
import '../../common/custom_bottom_nav_bar.dart';
import '../screens/ai_chat_screen.dart';
import '../screens/profile_screen.dart';

class AgentBottomNavigation extends StatefulWidget {
  final Map<String, dynamic>? userDetails;
  const AgentBottomNavigation({super.key ,this.userDetails});

  @override
  State<AgentBottomNavigation> createState() => _AgentBottomNavigationState();
}

class _AgentBottomNavigationState extends State<AgentBottomNavigation> {
  int _selectedIndex = 1; // ✅ Start at "Home" (Index 1)

  // ✅ Updated List of Pages
  List<Widget> get _pages => [
    AiChatScreen(),
    AgentHomeScreen(token: 'token'),
    ProfileScreen(),
    AgentSettingsScreen(),
  ];


  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // ✅ Display Selected Page

      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }
}

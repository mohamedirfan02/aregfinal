import 'package:areg_app/common/custom_bottom_nav_bar.dart';
import 'package:areg_app/views/screens/ai_chat_screen.dart';
import 'package:areg_app/views/screens/home_screen.dart';
import 'package:areg_app/views/screens/profile_screen.dart';
import 'package:areg_app/views/screens/settings_screen.dart';
import 'package:flutter/material.dart';


class BottomNavigation extends StatefulWidget {
  final Map<String, dynamic> userDetails; // ✅ Accept user details

  const BottomNavigation({super.key, required this.userDetails});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _selectedIndex = 1;
  late PageController _pageController;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    print("📦 Received in BottomNavigation: ${widget.userDetails}");
    _pageController = PageController(initialPage: _selectedIndex);
    _pages = [
      AiChatScreen(),
      HomeScreen(),
      ProfileScreen(),
      SettingsScreen(),
    ];
  }

  void _onNavItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 1) {
          _onNavItemTapped(1); // Navigate back to home
          return false; // prevent exit
        } else {
          return await _showExitConfirmationDialog(context); // only exit from home
        }
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: _pages,
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _selectedIndex,
          onTap: _onNavItemTapped,
        ),
      ),
    );
  }

}


Future<bool> _showExitConfirmationDialog(BuildContext context) async {
  if (!context.mounted) return false;

  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Exit App"),
      content: const Text("Do you really want to exit?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("No"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("Yes"),
        ),
      ],
    ),
  ) ??
      false;
}



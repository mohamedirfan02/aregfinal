import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import '../../common/custom_bottom_nav_bar.dart';
import '../screens/ai_chat_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';

class BottomNavigation extends StatefulWidget {
  final Map<String, dynamic> userDetails; // ✅ Accept user details

  const BottomNavigation({super.key, required this.userDetails});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _selectedIndex = 1; // ✅ Start at "Home" (Index 1)

  late List<Widget> _pages; // ✅ Define dynamically

  @override
  void initState() {
    super.initState();
    _pages = [
      AiChatScreen(),
      HomeScreen(),
      ProfileScreen(userDetails: widget.userDetails), // ✅ Pass user data
      SettingsScreen(),
    ];
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _showExitConfirmationDialog(context),
      child: Scaffold(
        body: _pages[_selectedIndex], // ✅ Display Selected Page

        // ✅ Bottom Navigation Bar
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _selectedIndex,
          onTap: _onNavItemTapped,
        ),
      ),
    );
  }
}

Future<bool> _showExitConfirmationDialog(BuildContext context) async {
  return await showDialog(
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
class MonthlyDropdownButton extends StatefulWidget {
  final void Function(String) onMonthSelected; // Callback function

  const MonthlyDropdownButton({super.key, required this.onMonthSelected});

  @override
  _MonthlyDropdownButtonState createState() => _MonthlyDropdownButtonState();
}

class _MonthlyDropdownButtonState extends State<MonthlyDropdownButton> {
  final List<String> months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  String? selectedMonth; // Stores the selected month

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: const Text(
          "Select Month",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        value: selectedMonth,
        items: months.map((String month) {
          return DropdownMenuItem<String>(
            value: month,
            child: Text(
              month,
              style: const TextStyle(fontSize: 16),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            selectedMonth = newValue;
          });
          if (newValue != null) {
            widget.onMonthSelected(newValue); // Call the callback function
          }
        },
        buttonStyleData: ButtonStyleData(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
        dropdownStyleData: DropdownStyleData(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
        ),
        iconStyleData: const IconStyleData(
          icon: Icon(Icons.arrow_drop_down, color: Colors.black),
        ),
      ),
    );
  }
}


class NextPage extends StatelessWidget {
  final String selectedMonth;

  const NextPage({super.key, required this.selectedMonth});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$selectedMonth Details")),
      body: Center(
        child: Text(
          "You selected: $selectedMonth",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}


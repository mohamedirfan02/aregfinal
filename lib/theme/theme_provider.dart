// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class ThemeProvider extends ChangeNotifier {
//   static const String themeKey = 'isDarkMode';
//   bool _isDarkMode = false;
//
//   bool get isDarkMode => _isDarkMode;
//
//   ThemeProvider() {
//     _loadTheme();
//   }
//
//   void toggleTheme(bool isOn) {
//     _isDarkMode = isOn;
//     _saveTheme(isOn);
//     notifyListeners();
//   }
//
//   void _loadTheme() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     _isDarkMode = prefs.getBool(themeKey) ?? false;
//     notifyListeners();
//   }
//
//   void _saveTheme(bool value) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     prefs.setBool(themeKey, value);
//   }
// }

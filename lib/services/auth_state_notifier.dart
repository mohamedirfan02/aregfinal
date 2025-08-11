import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStateNotifier extends ChangeNotifier {
  String? _role;
  bool _isAuthenticated = false;

  String? get role => _role;
  bool get isAuthenticated => _isAuthenticated;

  AuthStateNotifier() {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    _role = prefs.getString('role');
    _isAuthenticated = token != null && _role != null;
    notifyListeners();
  }
}

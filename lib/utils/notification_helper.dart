import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

Future<void> saveNotification(String title, String body) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> notifications = prefs.getStringList("notifications") ?? [];

  notifications.insert(0, jsonEncode({
    "title": title,
    "body": body,
    "date": DateTime.now().toString()
  }));

  await prefs.setStringList("notifications", notifications);
}

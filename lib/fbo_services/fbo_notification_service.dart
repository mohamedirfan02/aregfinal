import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FboNotificationService {
  static const String _baseUrl = "https://enzopik.thikse.in/api";

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> init() async {
    await _firebaseMessaging.requestPermission();
    await _getAndSaveFCMToken();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("📩 New Notification Received: ${message.notification?.title}");
      await saveNotification(
        title: message.notification?.title ?? "New Notification",
        body: message.notification?.body ?? "",
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("📩 Notification Clicked: ${message.notification?.title}");
    });
  }

  Future<void> _getAndSaveFCMToken() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      print("✅ FCM Token: $token");
      await sendTokenToServer(token);
    } else {
      print("❌ Failed to retrieve FCM Token");
    }
  }

  Future<void> sendTokenToServer(String token) async {
    final prefs = await SharedPreferences.getInstance();
    String? authToken = prefs.getString('token');
    String? userId = prefs.getString('user_id');

    if (authToken == null || userId == null) {
      print("❌ No authentication token or user ID found.");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/save-fcm-token"),
        headers: {
          "Authorization": "Bearer $authToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"user_id": userId, "fcm_token": token}),
      );

      print("📩 FCM Token Sent to Server: ${response.body}");
    } catch (e) {
      print("❌ Error sending FCM token: $e");
    }
  }

  Future<List<Map<String, dynamic>>?> fetchNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('user_id');

    if (token == null || userId == null) {
      print("❌ No authentication token or user ID found.");
      return [];
    }

    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/get-notifications"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "role": "user",
          "id": int.parse(userId),
        }),
      );

      print("🔹 API Response Status: ${response.statusCode}");
      print("🔹 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] is List) {
          List<Map<String, dynamic>> fetchedNotifications =
          List<Map<String, dynamic>>.from(data['data']);

          await _saveNotificationsLocally(fetchedNotifications);
          return fetchedNotifications;
        }
      }
    } catch (e) {
      print("❌ Error fetching notifications: $e");
    }

    return [];
  }

  Future<void> saveNotification({required String title, required String body, }) async {
    final prefs = await SharedPreferences.getInstance();

    Map<String, dynamic> newNotification = {
      "title": title,
      "message": body,
      "created_at": DateTime.now().toString(),
    };

    List<String>? storedNotifications = prefs.getStringList("notifications");
    List<Map<String, dynamic>> notifications = storedNotifications != null
        ? storedNotifications.map((e) => jsonDecode(e) as Map<String, dynamic>).toList()
        : [];

    notifications.insert(0, newNotification);

    await prefs.setStringList("notifications", notifications.map((e) => jsonEncode(e)).toList());

    print("✅ Notification Saved Locally: $title");
  }

  Future<void> _saveNotificationsLocally(List<Map<String, dynamic>> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> encodedNotifications = notifications.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList("notifications", encodedNotifications);
    print("✅ Fetched Notifications Saved Locally");
  }
}

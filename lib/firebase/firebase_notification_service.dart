import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print("❌ Notifications permission denied");
    } else {
      print("✅ Notifications permission granted");
    }
  }

  Future<String?> getFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print("✅ Current FCM Token: $token");
      return token;
    } catch (e) {
      print("❌ Error getting FCM token: $e");
      return null;
    }
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseApi {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
    await requestPermission();
    await getFCMToken();
    initializeLocalNotifications();
    FirebaseMessaging.onMessage.listen(showForegroundNotification);
  }

  /// Request permission for notifications
  static Future<void> requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("✅ User granted permission for notifications");
    } else {
      print("❌ User declined notification permissions");
    }
  }

  /// Get the FCM token for this device
  static Future<void> getFCMToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    print("📲 FCM Token: $token");

    // Store the token in your backend if necessary
  }

  /// Initialize local notifications for displaying in-app notifications
  static void initializeLocalNotifications() {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings settings =
    InitializationSettings(android: androidSettings);
    _localNotificationsPlugin.initialize(settings);
  }

  /// Show foreground notifications using local notifications
  static void showForegroundNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            "high_importance_channel",
            "High Importance Notifications",
            importance: Importance.max,
          ),
        ),
      );
    }
  }
}

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../../fbo_services/fbo_notification_service.dart';

class FboNotificationScreen extends StatefulWidget {
  const FboNotificationScreen({super.key});

  @override
  _FboNotificationScreenState createState() => _FboNotificationScreenState();
}

class _FboNotificationScreenState extends State<FboNotificationScreen> {
  final FboNotificationService _notificationService = FboNotificationService();
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _notificationService.init();
    fetchNotifications();
    setupFirebaseListeners();
  }

  void setupFirebaseListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("📩 New Notification: ${message.notification?.title}");
      // Fetch reason dynamically from DB (you can modify this based on your DB structure)
    //  String reason = await _notificationService.fetchReasonForNotification(message.messageId ?? "");

      _notificationService.saveNotification(
        title: message.notification?.title ?? "New Notification",
        body: message.notification?.body ?? "",
        //reason: reason,
      );

      setState(() {
        notifications.insert(0, {
          'title': message.notification?.title ?? "No Title",
          'message': message.notification?.body ?? "No Message",
          //'reason': reason, // Dynamic reason from DB
          'created_at': DateTime.now().toString(),
        });
      });
    });
  }

  Future<void> fetchNotifications() async {
    setState(() => isLoading = true);
    notifications = await _notificationService.fetchNotifications() ?? [];
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? const Center(child: Text("No notifications available"))
          : ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return NotificationItem(
            title: notification['title'] ?? 'No Title',
            message: notification['message'] ?? 'No Message',
            //reason: notification['reason'] ?? 'No Reason', // Dynamically fetched reason
            createdAt: notification['created_at'] ?? 'Unknown Date',
          );
        },
      ),
    );
  }
}

class NotificationItem extends StatelessWidget {
  final String title;
  final String message;
  final String createdAt;

  const NotificationItem({
    super.key,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(message),
      trailing: Text(createdAt.split('T')[0]),
    );
  }
}

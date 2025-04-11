import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/shimmer_loader.dart';
import '../common/agent_gradient.dart';

class AgentNotificationPage extends StatefulWidget {
  const AgentNotificationPage({super.key});

  @override
  State<AgentNotificationPage> createState() => _AgentNotificationPageState();
}

class _AgentNotificationPageState extends State<AgentNotificationPage> {
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    setupFirebaseListeners(); // ✅ Add Firebase Notification Listener
  }

  /// ✅ Listen for real-time notifications
  void setupFirebaseListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 New Notification: ${message.notification?.title}");

      setState(() {
        notifications.insert(0, {
          'title': message.notification?.title ?? "No Title",
          'message': message.notification?.body ?? "No Message",
          'created_at': DateTime.now().toString(),
        });
      });
    });
  }

  /// ✅ Get Token from SharedPreferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// ✅ Fetch Notifications from Laravel API
  Future<void> fetchNotifications() async {
    final url = Uri.parse("https://enzopik.thikse.in/api/get-notifications");
    String? token = await getToken();
    if (token == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "role": "agent",
          "id": 1,
        }),
      );

      debugPrint("📩 API Response: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        if (jsonData["status"] == "success") {
          setState(() {
            notifications = jsonData["data"];
            isLoading = false;
          });
        }
      } else {
        debugPrint("❌ API Error: ${response.statusCode} - ${response.body}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("❌ Error fetching notifications: $e");
      setState(() => isLoading = false);
    }
  }
  /// ✅ Build Shimmer UI for Loading State
  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 6, // ✅ Show 6 shimmer placeholders
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerLoader(height: 20, width: 100), // ✅ Fake Order ID
                const SizedBox(height: 10),
                const ShimmerLoader(height: 14), // ✅ Fake Name
                const ShimmerLoader(height: 14, width: 150), // ✅ Fake Address
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Expanded(child: ShimmerLoader(height: 40)), // ✅ Fake PDF Button
                    const SizedBox(width: 10),
                    const Expanded(child: ShimmerLoader(height: 40)), // ✅ Fake Excel Button
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return AgentGradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Image.asset("assets/icon/back.png", width: 24, height: 24),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.maybePop(context);
              }
            },
          ),
          title: const Text(
            "Notifications",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTodayLabel(),
              const SizedBox(height: 10),
              Expanded(
                child: isLoading
                    ? _buildShimmerList() // ✅ Show Shimmer While Loading
                    : notifications.isEmpty
                    ? const Center(child: Text("No notifications available"))
                    : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];

                    final String title = notification["title"] ?? "No Title";
                    final String message = notification["message"] ?? "No Message";
                    final String orderId = notification["order_id"]?.toString() ?? "N/A";
                    final String date = notification["created_at"]?.split('T')[0] ?? "Unknown Date";

                    return _buildNotificationCard(
                      title: title,
                      message: message,
                      orderId: orderId,
                      date: date,
                      statusIcon: "assets/icon/Pickup.png",
                      statusColor: Colors.orange,
                      backgroundColor: Colors.white,
                      onTap: () {
                        context.go('/order-details/$orderId');
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        "Today",
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String message,
    required String orderId,
    required String date,
    required String statusIcon,
    required Color statusColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black12.withOpacity(0.1), blurRadius: 5, spreadRadius: 1),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(statusIcon, width: 24, height: 24, color: statusColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Order ID: #$orderId",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Date: $date",
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

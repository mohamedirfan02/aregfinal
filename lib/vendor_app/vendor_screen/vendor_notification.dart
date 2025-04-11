import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../agent/common/agent_gradient.dart';

class VendorNotificationPage extends StatefulWidget {
  const VendorNotificationPage({super.key});

  @override
  State<VendorNotificationPage> createState() => _VendorNotificationPageState();
}

class _VendorNotificationPageState extends State<VendorNotificationPage> {
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  Future<void> fetchNotifications() async {
    final url = Uri.parse("https://enzopik.thikse.in/api/get-notifications");

    // ✅ Fetch Token & ID Dynamically
    String? token = await getToken();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id'); // Fetch user ID dynamically

    if (token == null || userId == null) {
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
          "role": "vendor", // Adjust role dynamically if needed
          "id": int.parse(userId), // Convert ID to integer
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
                    ? const Center(child: CircularProgressIndicator())
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
                       // context.go('/VendorCartPage/$orderId');
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

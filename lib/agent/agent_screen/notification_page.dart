import 'dart:convert';
import 'package:areg_app/common/app_colors.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/shimmer_loader.dart';
import '../../config/api_config.dart';

class AgentNotificationPage extends StatefulWidget {
  const AgentNotificationPage({super.key});

  @override
  State<AgentNotificationPage> createState() => _AgentNotificationPageState();
}

class _AgentNotificationPageState extends State<AgentNotificationPage> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  Set<String> readNotificationIds = {};

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    setupFirebaseListeners();
    loadReadNotificationIds();
  }

  Future<void> loadReadNotificationIds() async {
    final prefs = await SharedPreferences.getInstance();
    final readList = prefs.getStringList('read_notifications') ?? [];
    setState(() {
      readNotificationIds = readList.toSet();
    });
  }

  Future<void> markAsRead(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    readNotificationIds.add(notificationId);
    await prefs.setStringList('read_notifications', readNotificationIds.toList());
    setState(() {});
  }

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

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> fetchOrderDetails(int orderId) async {
    const url = ApiConfig.getOrderDetails;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final agentId = prefs.getString('agent_id');

    final body = {
      "role": "agent",
      "order_id": orderId,
      "id": int.tryParse(agentId ?? "0") ?? 0,
    };
    print("📦 Fetching Order Details with: ${jsonEncode(body)}");
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );
      print("🔁 Order Detail Response: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final data = jsonData['data'] as List?;
        if (data != null && data.isNotEmpty) {
          return Map<String, dynamic>.from(data[0]);
        }
        return {};
      } else {
        return {};
      }
    } catch (e) {
      print("❌ Error fetching order details: $e");
      return {};
    }
  }

  Future<void> fetchNotifications() async {
    final url = Uri.parse(ApiConfig.getNotification);
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? agentId = prefs.getString('agent_id');

    if (token == null || agentId == null) {
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
          "id": int.parse(agentId),
        }),
      );
      debugPrint("📩 API Response: ${response.body}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        if (jsonData["status"] == "success") {
          setState(() {
            // Proper type conversion to avoid casting errors
            notifications = (jsonData["data"] as List).map((notif) {
              final Map<String, dynamic> notification = Map<String, dynamic>.from(notif);
              return {
                ...notification,
                'created_at': '${notification["created_date"] ?? ""} ${notification["created_time"] ?? ""}'.trim()
              };
            }).toList();
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

  Widget _buildShimmerList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (context, index) {
        return const Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoader(height: 20, width: 100),
                SizedBox(height: 10),
                ShimmerLoader(height: 14),
                ShimmerLoader(height: 14, width: 150),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: ShimmerLoader(height: 40)),
                    SizedBox(width: 10),
                    Expanded(child: ShimmerLoader(height: 40)),
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.secondaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset("assets/icon/back.png", width: 24, height: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(fontSize: 20, color: Colors.white70, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildShimmerList(),
      )
          : notifications.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No notifications yet",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchNotifications,
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            final notificationId = notification["id"]?.toString() ?? index.toString();

            return _buildNotificationCard(
              notification: notification,
              notificationId: notificationId,
              onTap: () => _handleNotificationTap(notification, notificationId),
            );
          },
        ),
      ),
    );
  }

  // Handle different notification types
  void _handleNotificationTap(Map<String, dynamic> notification, String notificationId) async {
    await markAsRead(notificationId);

    final orderId = notification["order_id"];

    if (orderId != null) {
      // Order-related notification - fetch order details
      final orderDetails = await fetchOrderDetails(orderId is int ? orderId : int.tryParse(orderId.toString()) ?? 0);
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (_) => OrderDetailPopup(data: orderDetails),
      );
    } else {
      // Non-order notification - show general notification details
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (_) => GeneralNotificationPopup(notification: notification),
      );
    }
  }

  Widget _buildNotificationCard({
    required Map<String, dynamic> notification,
    required String notificationId,
    required VoidCallback onTap,
  }) {
    final title = notification["title"]?.toString() ?? "No Title";
    final message = notification["message"]?.toString() ?? "No Message";
    final date = notification["created_at"]?.toString() ?? "Unknown";
    final orderId = notification["order_id"];

    final isRead = readNotificationIds.contains(notificationId);
    Color cardBackground = isRead ? Colors.white : Colors.black12;
    Color titleColor = title.toLowerCase().contains('cancel')
        ? Colors.red
        : (isRead ? Colors.black : AppColors.titleColor);

    String resolvedIcon = title.toLowerCase().contains('cancel')
        ? "assets/icon/cancel.png"
        : "assets/icon/right.png";

    List<String> dateParts = date.split(' ');
    String datePart = dateParts.isNotEmpty ? dateParts.first : '';
    String timePart = dateParts.length > 1 ? dateParts[1] : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(resolvedIcon, width: 24, height: 24, color: titleColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                ),
                if (orderId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Order #$orderId",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  datePart.isNotEmpty && timePart.isNotEmpty
                      ? "$datePart at $timePart"
                      : date.isNotEmpty
                      ? date
                      : "Unknown time",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Order Detail Popup
class OrderDetailPopup extends StatelessWidget {
  final Map<String, dynamic> data;

  const OrderDetailPopup({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return AlertDialog(
        title: const Text("Order Details"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Text("Order details not available."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: AppColors.secondaryColor, fontWeight: FontWeight.bold)),
          )
        ],
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.secondaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Order Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow("Order ID", data["order_id"]?.toString() ?? "-"),
                    _detailRow("Oil Type", data["type"]?.toString() ?? "-"),
                    _detailRow("Name", data["user_name"]?.toString() ?? "-"),
                    _detailRow("Restaurant Name", data["restaurant_name"]?.toString() ?? "-"),
                    _detailRow("Quantity", "${data["quantity"]?.toString() ?? "0"} KG"),
                    _detailRow("Expected Pick Date", data["timeline"]?.toString() ?? "-"),
                    _detailRow("Amount", "₹${data["amount"]?.toString() ?? "0"}"),
                    _detailRow("Payment Method", data["payment_method"]?.toString() ?? "-"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text("$label:")),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

// General Notification Popup
class GeneralNotificationPopup extends StatelessWidget {
  final Map<String, dynamic> notification;

  const GeneralNotificationPopup({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.secondaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      notification["title"]?.toString() ?? "Notification",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow("Message", notification["message"]?.toString() ?? "-"),
                    _detailRow("Reason", notification["reason"]?.toString() ?? "-"),
                    _detailRow("Date", notification["created_date"]?.toString() ?? "-"),
                    _detailRow("Time", notification["created_time"]?.toString() ?? "-"),
                    if (notification["owner_id"] != null)
                      _detailRow("Owner ID", notification["owner_id"].toString()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              flex: 2,
              child: Text(
                "$label:",
                style: const TextStyle(fontWeight: FontWeight.w500),
              )),
          Expanded(
              flex: 3,
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold),
              )),
        ],
      ),
    );
  }
}
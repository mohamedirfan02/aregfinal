import 'dart:convert';
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
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    setupFirebaseListeners(); // ✅ Add Firebase Notification Listener
    loadReadNotificationIds(); // Load read status from storage
  }

  Set<String> readNotificationIds = {};

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
    setState(() {}); // To rebuild UI with updated colors
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
        return jsonData['data']?[0] ?? {};
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
            notifications = (jsonData["data"] as List).map((notif) {
              return {
                ...notif,
                'created_at': '${notif["created_date"]} ${notif["created_time"]}'
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
  Map<String, List<Map<String, dynamic>>> groupNotificationsByDate(List<dynamic> notifications) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var notif in notifications) {
      final date = DateTime.tryParse(notif['created_at'] ?? '') ?? DateTime.now();
      final now = DateTime.now();

      String label;
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        label = "Today";
      } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
        label = "Yesterday";
      } else {
        label = "${date.day}/${date.month}/${date.year}";
      }

      if (!grouped.containsKey(label)) {
        grouped[label] = [];
      }
      grouped[label]!.add(notif);
    }

    return grouped;
  }

  /// ✅ Build Shimmer UI for Loading State
  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 6, // ✅ Show 6 shimmer placeholders
      itemBuilder: (context, index) {
        return const Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoader(height: 20, width: 100), // ✅ Fake Order ID
                SizedBox(height: 10),
                ShimmerLoader(height: 14), // ✅ Fake Name
                ShimmerLoader(height: 14, width: 150), // ✅ Fake Address
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: ShimmerLoader(height: 40)),
                    // ✅ Fake PDF Button
                    SizedBox(width: 10),
                    Expanded(child: ShimmerLoader(height: 40)),
                    // ✅ Fake Excel Button
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
    return  Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF006D04),
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
          style: TextStyle(fontSize: 20, color: Colors.white70,fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Expanded(
              child: isLoading
                  ? _buildShimmerList() // ✅ Show Shimmer While Loading
                  : notifications.isEmpty
                  ? const Center(
                  child: Text("No notifications available"))
                  : ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _buildNotificationCard(
                    title: notification["title"] ?? "No Title",
                    message: notification["message"] ?? "Your order #${notification["order_id"] ?? "N/A"} has been placed.",
                    orderId: notification["order_id"]?.toString() ?? "N/A",
                    vendorId: notification["vendor_id"]?.toString() ?? "N/A",
                    reason: notification["reason"] ?? "-",
                    createdAt: notification["created_at"]?.split("T")[0] ?? "Unknown",
                    updatedAt: notification["updated_at"]?.split("T")[0] ?? "Unknown",
                    date: notification["created_at"]?.split("T")[0] ?? "Unknown",
                    onTap: () {}, statusIcon: '', statusColor: Colors.black, backgroundColor: Colors.black,
                  );

                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String message,
    required String orderId,
    required String vendorId,
    required String date,
    required String reason,
    required String createdAt,
    required String updatedAt,
    required String statusIcon,
    required Color statusColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    final isRead = readNotificationIds.contains(orderId);

    Color cardBackground = isRead ? Colors.white : const Color(0xFFDFF5E3);
    Color titleColor = title.toLowerCase().contains('cancel')
        ? Colors.red
        : (isRead ? Colors.black : Colors.green.shade900);

    String resolvedIcon = title.toLowerCase().contains('cancel')
        ? "assets/icon/cancel.png"
        : "assets/icon/right.png";

    String datePart = date.split(' ').first;
    String timePart = date.split(' ').length > 1 ? date.split(' ')[1] : '';

    return GestureDetector(
      onTap: () async {
        await markAsRead(orderId);
        final orderDetails = await fetchOrderDetails(int.tryParse(orderId) ?? 0);
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (_) => OrderDetailPopup(data: orderDetails),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
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
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 6),
                Text(
                  "$datePart at $timePart",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
class OrderDetailPopup extends StatelessWidget {
  final Map<String, dynamic> data;

  const OrderDetailPopup({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Order Details"),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow("Order ID", data["order_id"].toString()),
         // _detailRow("Agent ID", data["vendor_id"].toString()),
          _detailRow("Oil Type", data["type"] ?? "-"),
          _detailRow("Name", data["user_name"] ?? "-"),
          _detailRow("Restaurant Name", data["restaurant_name"] ?? "-"),
          _detailRow("Quantity", "${data["quantity"]} KG"),
         // _detailRow("Proposed Price", "₹${data["proposed_unit_price"]}"),
          _detailRow("Excepted Pick Date", " ${data["timeline"]}"),
        //  _detailRow("Collection date", "${data["timeline"]}"),
          _detailRow("Amount", "₹${data["amount"]}"),
          _detailRow("Payment Method", data["payment_method"] ?? "-"),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close",style: TextStyle(color: Color(0xFF006D04),fontWeight: FontWeight.bold),),
        )
      ],
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

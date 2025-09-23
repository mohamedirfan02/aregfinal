import 'dart:convert';
import 'package:areg_app/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
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
  bool showAllNotifications = false;


  @override
  void initState() {
    super.initState();
    _notificationService.init();
    fetchNotifications();
    setupFirebaseListeners();
  }
  Future<int> getUnreadNotificationCount() async {
    final prefs = await SharedPreferences.getInstance();
    final allNotifications = await _notificationService.fetchNotifications() ?? [];

    int unreadCount = 0;
    for (var notification in allNotifications) {
      final messageId = notification['id']?.toString() ?? notification['title'];
      final isRead = prefs.getBool('read_$messageId') ?? false;
      if (!isRead) {
        unreadCount++;
      }
    }
    return unreadCount;
  }



  Map<String, List<Map<String, dynamic>>> groupNotificationsByDate(
      List<Map<String, dynamic>> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String formatHeader(DateTime date) {
      if (date.isAtSameMomentAs(today)) return 'Today';
      if (date.isAtSameMomentAs(yesterday)) return 'Yesterday';
      return "${date.day.toString().padLeft(2, '0')}, ${_monthName(date.month)} ${date.year}";
    }

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in items) {
      final date = DateTime.tryParse(item['created_at'] ?? '') ?? now;
      final justDate = DateTime(date.year, date.month, date.day);
      final label = formatHeader(justDate);
      // final grouped = groupNotificationsByDate(notifications);

      if (!grouped.containsKey(label)) {
        grouped[label] = [];
      }
      grouped[label]!.add(item);
    }
    return grouped;
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  void setupFirebaseListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (!mounted) return;
      _notificationService.saveNotification(
        title: message.notification?.title ?? "New Notification",
        body: message.notification?.body ?? "",
      );

      setState(() {
        notifications.insert(0, {
          'title': message.notification?.title ?? "No Title",
          'message': message.notification?.body ?? "No Message",
          'created_at': DateTime.now().toString(),
          'read': false,
        });
      });
    });
  }

  Future<Map<String, dynamic>> _fetchOrderDetails(int orderId) async {
    const url = ApiConfig.getOrderDetails;
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? Id = prefs.getString('userId'); // String expected
    String? role = prefs.getString('role'); // String expected

    final requestBody = {
      "role": role,
      "order_id": orderId,
      "id": int.tryParse(Id ?? '0') ?? 0, // ensure it's an integer
    };

    try {
      print("Sending Request to: $url");
      print("Authorization: Bearer $token");
      print("Request Body: ${jsonEncode(requestBody)}");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {};
      }
    } catch (e) {
      print('Error: $e');
      return {};
    }
  }

  Future<void> fetchNotifications() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    notifications =
        (await _notificationService.fetchNotifications() ?? []).map((n) {
      final messageId = n['id']?.toString() ?? n['title'];
      final isRead = prefs.getBool('read_$messageId') ?? false;

      // Combine date and time from API
      final createdDate = n['created_date'] ?? '';
      final createdTime = n['created_time'] ?? '';
      final combinedDateTime = '$createdDate $createdTime';

      return {
        ...n,
        'read': isRead,
        'created_at': combinedDateTime,
      };
    }).toList();

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupNotificationsByDate(notifications);
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications",style: TextStyle(color: Colors.white),),
        backgroundColor: AppColors.fboColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? Center(
        child: Text(
          "No notifications available",
          style: TextStyle(color: textColor),
        ),
      )
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ListView(
          children: [
            const SizedBox(height: 12),
            ...buildGroupedList(
              context,
              grouped,
              textColor,
              showAll: showAllNotifications,
            ),
            if (notifications.length > 10 && !showAllNotifications)
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      showAllNotifications = true;
                    });
                  },
                  child: const Text("View All Notifications",),
                ),
              ),

          ],
        ),
      ),
    );
  }

  List<Widget> buildGroupedList(
      BuildContext context,
      Map<String, List<dynamic>> grouped,
      Color? textColor, {
        bool showAll = false,
      }) {
    // Flatten all entries first
    final allEntries = grouped.entries.expand((entry) {
      return entry.value.map((item) => MapEntry(entry.key, item));
    }).toList();

    // Apply limit if not showing all
    final limitedEntries = showAll ? allEntries : allEntries.take(10).toList();

    // Re-group limited entries by date
    final limitedGrouped = <String, List<Map<String, dynamic>>>{};
    for (var entry in limitedEntries) {
      limitedGrouped.putIfAbsent(entry.key, () => []).add(entry.value);
    }

    // Generate UI from limited or full grouped map
    return limitedGrouped.entries.expand((entry) {
      return [
        Text(
          entry.key,
          style: TextStyle(
            color: textColor?.withOpacity(0.8),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...entry.value.map((n) => // ✅ Replace the GestureDetector onTap in your buildGroupedList method
        GestureDetector(
          onTap: () async {
            final messageId = n['id']?.toString() ?? n['title'];
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('read_$messageId', true);
            setState(() => n['read'] = true);

            // ✅ Fetch order details only if order_id exists
            Map<String, dynamic> order = {};
            if (n['order_id'] != null) {
              final details = await _fetchOrderDetails(n['order_id'] ?? 1);
              order = details['data']?[0] ?? {};
            }

            showDialog(
              context: context,
              builder: (context) => NotificationPopup(
                title: n['title'] ?? '',
                message: n['message'] ?? '',
                createdAt: n['created_at'] ?? '',
                reason: n['reason'] ?? '', // ✅ Pass the reason from API
                orderId: n['order_id']?.toString() ?? '',
                oilType: order['type'] ?? '',
                quantity: order['quantity']?.toString() ?? '',
                amount: order['amount']?.toString() ?? '',
                paymentMethod: order['payment_method'] ?? '',
              ),
            );
          },
          child: NotificationCard(
            title: n['title'] ?? '',
            message: n['message'] ?? '',
            createdAt: n['created_at'] ?? '',
            isRead: n['read'] ?? false,
          ),
        ),),
        const SizedBox(height: 20),
      ];
    }).toList();
  }


}

class NotificationPopup extends StatelessWidget {
  final String title;
  final String message;
  final String createdAt;
  final String reason;
  final String orderId;
  final String oilType;
  final String quantity;
  final String amount;
  final String paymentMethod;

  const NotificationPopup({
    super.key,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.reason,
    required this.orderId,
    required this.oilType,
    required this.quantity,
    required this.amount,
    required this.paymentMethod,
  });

  // ✅ Determine notification type based on reason/title
  NotificationType get notificationType {
    final lowerReason = reason.toLowerCase();
    final lowerTitle = title.toLowerCase();

    if (lowerReason.contains("cancel") || lowerReason.contains("decline") ||
        lowerTitle.contains("cancel") || lowerTitle.contains("decline")) {
      return NotificationType.cancelled;
    } else if (lowerReason.contains("payment") || lowerTitle.contains("payment")) {
      return NotificationType.paymentCompleted;
    } else if (lowerReason.contains("acknowledgement") || lowerTitle.contains("acknowledged")) {
      return NotificationType.acknowledged;
    } else if (lowerReason.contains("approved") || lowerTitle.contains("approved")) {
      return NotificationType.approved;
    } else {
      return NotificationType.general;
    }
  }

  // ✅ Get dynamic content based on notification type
  Map<String, dynamic> get dynamicContent {
    switch (notificationType) {
      case NotificationType.cancelled:
        return {
          'icon': Icons.cancel,
          'color': Colors.red,
          'headerText': 'Cancelled',
          'description': 'Since we were unable to book your order.',
          'showOrderId': true,
        };

      case NotificationType.paymentCompleted:
        return {
          'icon': Icons.payment,
          'color': Colors.green,
          'headerText': 'Payment Completed!',
          'description': 'Your payment has been successfully processed.',
          'showOrderId': true,
        };

      case NotificationType.acknowledged:
        return {
          'icon': Icons.check_circle,
          'color': AppColors.primaryColor,
          'headerText': 'Sale Acknowledged!',
          'description': 'Your oil sale has been acknowledged and confirmed.',
          'showOrderId': true,
        };

      case NotificationType.approved:
        return {
          'icon': Icons.approval,
          'color': Colors.orange,
          'headerText': 'Request Approved!',
          'description': 'Your collection request has been approved with updated timeline.',
          'showOrderId': true,
        };

      default:
        return {
          'icon': Icons.notifications,
          'color': Colors.grey,
          'headerText': 'Notification',
          'description': message,
          'showOrderId': true,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final dateTime = DateTime.tryParse(createdAt) ?? DateTime.now();
    final formattedDate = "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}";
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    final formattedTime = "${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $ampm";

    final content = dynamicContent;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: theme.dialogBackgroundColor,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Dynamic Date Header
          Center(
            child: Text(
              "${dateTime.month.toString().padLeft(2, '0')} ${dateTime.day}, ${_weekday(dateTime.weekday)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ✅ Dynamic Icon and Header
          Row(
            children: [
              Icon(
                content['icon'],
                color: content['color'],
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  content['headerText'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: content['color'],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ✅ Dynamic Description
          Text(
            content['description'],
            style: TextStyle(color: textColor),
          ),

          // ✅ Show Order ID if applicable
          if (content['showOrderId'] && orderId.isNotEmpty) ...[
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: TextStyle(color: textColor),
                children: [
                  const TextSpan(text: "Order ID: "),
                  TextSpan(
                    text: "#$orderId",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ✅ Show reason if it's a cancellation/decline
          if (notificationType == NotificationType.cancelled && reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "Reason: $reason",
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],

          const SizedBox(height: 12),

          // ✅ Order Details (show only if available)
          if (oilType.isNotEmpty)
            Text("Oil Type: $oilType", style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
          if (paymentMethod.isNotEmpty)
            Text("Payment Method: $paymentMethod", style: TextStyle(color: theme.colorScheme.secondary)),

          Text("Date: $formattedDate", style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
          Text("Time: $formattedTime", style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),

          // ✅ Show quantity and amount only if available
          if (quantity.isNotEmpty || amount.isNotEmpty)
            Row(
              children: [
                if (quantity.isNotEmpty) ...[
                  _infoBox(context, "Total Kg", quantity),
                  const SizedBox(width: 8),
                ],
                if (amount.isNotEmpty)
                  _infoBox(context, "Amount", "₹$amount"),
              ],
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        )
      ],
    );
  }

  Widget _infoBox(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: theme.hintColor)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _weekday(int day) {
    switch (day) {
      case 1: return "Monday";
      case 2: return "Tuesday";
      case 3: return "Wednesday";
      case 4: return "Thursday";
      case 5: return "Friday";
      case 6: return "Saturday";
      case 7: return "Sunday";
      default: return "";
    }
  }
}

// ✅ Enum for different notification types
enum NotificationType {
  cancelled,
  paymentCompleted,
  acknowledged,
  approved,
  general,
}


class NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final String createdAt;
  final bool isRead;

  const NotificationCard({
    super.key,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateTime = DateTime.tryParse(createdAt) ?? DateTime.now();
    final formattedDate = "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}";
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    final formattedTime = "${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $ampm";


    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead
            ? theme.colorScheme.surface
            : theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isRead
                  ? theme.textTheme.bodyLarge?.color
                  : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Date: $formattedDate",
                  style: TextStyle(fontSize: 12, color: theme.hintColor)),
              Text("Time: $formattedTime",
                  style: TextStyle(fontSize: 12, color: theme.hintColor)),
            ],
          )
        ],
      ),
    );
  }
}


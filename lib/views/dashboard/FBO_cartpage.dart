import 'package:areg_app/agent/common/common_appbar.dart';
import 'package:areg_app/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../common/custom_appbar.dart';

// Order Model
class Order {
  final int orderId;
  final String type;
  final String quantity;
  final String status;
  final int userId;
  final String agreedUnitPrice;
  final String counterUnitPrice;
  final String amount;
  final int? vendorId;
  final String? vendorStatus;
  final int agentId;
  final String oilQuality;
  final String? oilImage;
  final String userName;
  final String userContact;
  final String address;
  final String timeline;
  final String pickupLocation;
  final String date;
  final String time;

  Order({
    required this.orderId,
    required this.type,
    required this.quantity,
    required this.status,
    required this.userId,
    required this.agreedUnitPrice,
    required this.counterUnitPrice,
    required this.amount,
    required this.vendorId,
    required this.vendorStatus,
    required this.agentId,
    required this.oilQuality,
    required this.oilImage,
    required this.userName,
    required this.userContact,
    required this.address,
    required this.timeline,
    required this.pickupLocation,
    required this.date,
    required this.time,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['order_id'] ?? 0,
      type: json['type'] ?? '',
      quantity: json['quantity'] ?? '',
      status: json['status'] ?? '',
      userId: json['user_id'] ?? 0,
      agreedUnitPrice: json['agreed_price'] ?? '',
      counterUnitPrice: json['counter_unit_price'] ?? '',
      amount: json['amount'] ?? '',
      vendorId: json['vendor_id'],
      vendorStatus: json['vendor_status'],
      agentId: json['agent_id'] ?? 0,
      oilQuality: json['oil_quality'] ?? '',
      oilImage: json['oil_image'],
      userName: json['user_name'] ?? '',
      userContact: json['user_contact'] ?? '',
      address: json['registered_address'] ?? '',
      timeline: json['timeline'] ?? '',
      pickupLocation: json['pickup_location'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
    );
  }
}

class FboCartScreen extends StatefulWidget {
  const FboCartScreen({super.key});

  @override
  State<FboCartScreen> createState() => _FboCartScreenState();
}

class _FboCartScreenState extends State<FboCartScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> statuses = [
    'pending',
    'accepted',
    'assigned',
    'completed'
  ];
  Map<String, List<Order>> ordersByStatus = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: statuses.length, vsync: this);

    // Initialize the map to avoid null access
    for (var status in statuses) {
      ordersByStatus[status] = [];
    }

    fetchOrders();
  }

  void _cancelOrder(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Order"),
        content: const Text("Are you sure you want to cancel this order?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Yes")),
        ],
      ),
    );
    if (confirmed == true) {
      // Perform cancel logic here
      print("Cancelling order ${order.orderId}");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? userIdString =
          prefs.getString('user_id'); // Fetch user_id as String

      if (token == null || userIdString == null) return;

      int userId = int.tryParse(userIdString) ?? 1;

      final response = await http.post(
        Uri.parse(ApiConfig.CancelOilOrder),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "user_id": userId,
          // Add the user_id field
          "order_id": order.orderId,
          // Assuming orderId is the field in your Order class
        }),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order cancelled successfully")),
        );
        fetchOrders(); // Refresh orders
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to cancel order")),
        );
      }
    }
  }

  Future<void> fetchOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('user_id');

    setState(() => isLoading = true);
    ordersByStatus.clear();

    if (token == null || userId == null) {
      print("❌ No token or user_id found. User must log in again.");
      setState(() => isLoading = false);
      return;
    }

    for (String status in statuses) {
      try {
        print("Fetching orders with status: $status");

        final response = await http.post(
          Uri.parse(ApiConfig.getOrderDetails),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            "id": int.parse(userId),
            "role": "user",
            "status": status,
          }),
        );

        print("Status code for '$status': ${response.statusCode}");
        print("Response body for '$status': ${response.body}");

        if (response.statusCode == 200) {
          final jsonBody = json.decode(response.body);

          final List<Order> orders = (jsonBody['data'] is List)
              ? (jsonBody['data'] as List)
                  .map<Order>((json) => Order.fromJson(json))
                  .toList()
              : [];

          print("Parsed ${orders.length} orders for status '$status'");
          ordersByStatus[status] = orders;
        } else {
          print("Failed to fetch orders for status '$status'");
          ordersByStatus[status] = [];
        }
      } catch (e) {
        print("❌ Error fetching orders for status '$status': $e");
        ordersByStatus[status] = [];
      }
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: CommonAppbar(title: "Oil Orders"),
      ),
      body: Column(
        children: [
          Container(
            color: theme.cardColor,
            child: TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.disabledColor,
              indicatorColor: theme.colorScheme.primary,
              tabs: statuses.map((s) => Tab(text: s.toUpperCase())).toList(),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ordersByStatus.length < statuses.length
                    ? Center(
                        child: Text(
                          "Loading orders...",
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: statuses.map((status) {
                          final orders = ordersByStatus[status]!;
                          if (orders.isEmpty) {
                            return Center(
                              child: Text(
                                "No Orders Found",
                                style: theme.textTheme.bodyMedium,
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              return Card(
                                color: theme.cardColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Order ID: ${order.orderId}",
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color:
                                                  _getStatusColor(order.status),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              order.status.toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      _buildLabelText(
                                          "Type: ${order.type}", theme),
                                      _buildLabelText(
                                          "Quantity: ${order.quantity} Kg",
                                          theme),
                                      _buildLabelText(
                                          "Agreed Price: ₹${order.agreedUnitPrice}",
                                          theme),
                                      //_buildLabelText("Counter Price: ₹${order.counterUnitPrice}", theme),
                                      _buildLabelText(
                                          "Amount: ₹${order.amount}", theme),
                                      _buildLabelText(
                                          "Oil Quality: ${order.oilQuality}",
                                          theme),
                                      _buildLabelText(
                                          "User Name: ${order.userName}",
                                          theme),
                                      _buildLabelText(
                                          "Contact: ${order.userContact}",
                                          theme),
                                      _buildLabelText(
                                          "Address: ${order.address}", theme),
                                      _buildLabelText(
                                          "Timeline: ${order.timeline}", theme),
                                      _buildLabelText(
                                          "Pickup Location: ${order.pickupLocation}",
                                          theme),
                                      _buildLabelText(
                                          "Date: ${order.date} ${order.time}",
                                          theme),
                                      if (order.vendorId != null)
                                        _buildLabelText(
                                            "Vendor ID: ${order.vendorId}",
                                            theme),
                                      if (order.vendorStatus != null)
                                        _buildLabelText(
                                            "Vendor Status: ${order.vendorStatus}",
                                            theme),
                                      if (status == 'pending') ...[
                                        const SizedBox(height: 12),
                                        ElevatedButton(
                                          onPressed: () => _cancelOrder(order),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Image.asset(
                                                'assets/icon/cancel.png',
                                                width: 20,
                                                height: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                "Cancel Order",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
          )
        ],
      ),
    );
  }

  Widget _buildLabelText(String text, ThemeData theme) {
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
    );
  }

// Optional: Color coding for order status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'assigned':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

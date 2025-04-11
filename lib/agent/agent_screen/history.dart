import 'package:flutter/material.dart';
import '../agent_service/history_api.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Order>> _ordersFuture;
  final OrderApi _orderApi = OrderApi();

  @override
  void initState() {
    super.initState();
    _ordersFuture = fetchOrders();
  }

  Future<List<Order>> fetchOrders() async {
    try {
      List<dynamic> ordersJson = await _orderApi.fetchOrders();
      return ordersJson.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Error fetching orders: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order History"),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white, // ✅ White background for the entire screen
        child: FutureBuilder<List<Order>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 50),
                    const SizedBox(height: 10),
                    Text(
                      "Error: ${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  "No orders found",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              );
            }

            List<Order> orders = snapshot.data ?? [];

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                Order order = orders[index];

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      "Order #${order.orderId ?? 'N/A'} - ${order.type ?? 'Unknown'}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _orderDetailRow("Quantity", order.quantity),
                          _orderDetailRow("Status", order.status),
                          _orderDetailRow("Agent Status", order.Vendorstatus),
                          _orderDetailRow("User", order.userName),
                          _orderDetailRow("Contact", order.userContact),
                          _orderDetailRow("Address", order.registeredAddress),
                          _orderDetailRow("Date", order.date),
                          _orderDetailRow("Time", order.time),
                        ],
                      ),
                    ),
                    trailing: order.Vendorstatus?.toLowerCase() == "declined"
                        ? const Icon(Icons.cancel, color: Colors.red)
                        : const Icon(Icons.check_circle, color: Colors.green),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _orderDetailRow(String label, String? value) {
    return Text(
      "$label: ${value ?? 'N/A'}",
      style: const TextStyle(fontSize: 14),
    );
  }
}

// Model with Null Safety
class Order {
  final int? orderId;
  final String? type;
  final String? quantity;
  final String? status;
  final String? Vendorstatus;
  final String? userName;
  final String? userContact;
  final String? registeredAddress;
  final String? date;
  final String? time;

  Order({
    required this.orderId,
    required this.type,
    required this.quantity,
    required this.status,
    required this.Vendorstatus,
    required this.userName,
    required this.userContact,
    required this.registeredAddress,
    required this.date,
    required this.time,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json["order_id"] as int?,
      type: json["type"] as String? ?? "Unknown",
      quantity: json["quantity"] as String? ?? "0",
      status: json["status"] as String? ?? "Pending",
      Vendorstatus: json["vendor_status"] as String? ?? "Pending",
      userName: json["user_name"] as String? ?? "No Name",
      userContact: json["user_contact"] as String? ?? "No Contact",
      registeredAddress: json["registered_address"] as String? ?? "No Address",
      date: json["date"] as String? ?? "N/A",
      time: json["time"] as String? ?? "N/A",
    );
  }
}

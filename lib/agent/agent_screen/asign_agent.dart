import 'package:flutter/material.dart';
import '../agent_service/assigned_api.dart';

class AssignAgent extends StatefulWidget {
  const AssignAgent({super.key});

  @override
  _AssignAgentState createState() => _AssignAgentState();
}

class _AssignAgentState extends State<AssignAgent> with SingleTickerProviderStateMixin {
  late Future<List<Order>> _assignedOrdersFuture;
  late Future<List<Order>> _completedOrdersFuture;
  final AssignedApi _assignedApi = AssignedApi();

  @override
  void initState() {
    super.initState();
    _assignedOrdersFuture = fetchOrders("assigned");
    _completedOrdersFuture = fetchOrders("completed");
  }

  Future<List<Order>> fetchOrders(String status) async {
    try {
      List<dynamic> ordersJson = await _assignedApi.fetchOrdersByStatus(status);
      return ordersJson.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Error fetching $status orders: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Assigned Agent"),
          backgroundColor: Colors.blueAccent,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Assigned'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrderList(_assignedOrdersFuture),
            _buildOrderList(_completedOrdersFuture),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(Future<List<Order>> futureOrders) {
    return FutureBuilder<List<Order>>(
      future: futureOrders,
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

        List<Order> orders = snapshot.data!;

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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order #${order.orderId ?? 'N/A'} - ${order.type ?? 'Unknown'}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _orderDetailRow("Vendor ID", order.vendorId?.toString()),
                    _orderDetailRow("Quantity", order.quantity),
                    _orderDetailRow("Status", order.status),
                    _orderDetailRow("User ID", order.userId?.toString()),
                    _orderDetailRow("Proposed Price", order.proposedUnitPrice),
                    _orderDetailRow("Counter Price", order.counterUnitPrice),
                    _orderDetailRow("Amount", order.amount),
                    _orderDetailRow("Vendor Status", order.vendorStatus),
                    _orderDetailRow("Agent ID", order.agentId?.toString()),
                    _orderDetailRow("Oil Quality", order.oilQuality),
                    _orderDetailRow("Timeline", order.timeline),
                    _orderDetailRow("Pickup Location", order.pickupLocation),
                    _orderDetailRow("User Name", order.userName),
                    _orderDetailRow("Contact", order.userContact),
                    _orderDetailRow("Address", order.registeredAddress),
                    _orderDetailRow("Date", order.date),
                    _orderDetailRow("Time", order.time),
                    if (order.oilImage != null && order.oilImage!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            order.oilImage!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Text("Image load failed"),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
  final int? userId;
  final String? proposedUnitPrice;
  final String? counterUnitPrice;
  final String? amount;
  final int? vendorId;
  final String? vendorStatus;
  final int? agentId;
  final String? oilQuality;
  final String? oilImage;
  final String? userName;
  final String? userContact;
  final String? registeredAddress;
  final String? timeline;
  final String? pickupLocation;
  final String? date;
  final String? time;

  Order({
    this.orderId,
    this.type,
    this.quantity,
    this.status,
    this.userId,
    this.proposedUnitPrice,
    this.counterUnitPrice,
    this.amount,
    this.vendorId,
    this.vendorStatus,
    this.agentId,
    this.oilQuality,
    this.oilImage,
    this.userName,
    this.userContact,
    this.registeredAddress,
    this.timeline,
    this.pickupLocation,
    this.date,
    this.time,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['order_id'],
      type: json['type'],
      quantity: json['quantity'],
      status: json['status'],
      userId: json['user_id'],
      proposedUnitPrice: json['proposed_unit_price'],
      counterUnitPrice: json['counter_unit_price'],
      amount: json['amount'],
      vendorId: json['vendor_id'],
      vendorStatus: json['vendor_status'],
      agentId: json['agent_id'],
      oilQuality: json['oil_quality'],
      oilImage: json['oil_image'],
      userName: json['user_name'],
      userContact: json['user_contact'],
      registeredAddress: json['registered_address'],
      timeline: json['timeline'],
      pickupLocation: json['pickup_location'],
      date: json['date'],
      time: json['time'],
    );
  }
}

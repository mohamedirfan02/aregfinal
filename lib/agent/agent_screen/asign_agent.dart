import 'package:areg_app/common/app_colors.dart';
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
  //  final isDark = Theme.of(context).brightness == Brightness.dark;
    //final textColor = isDark ? Colors.white70 : Colors.black;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.fboColor,
          elevation: 0,
          title: Text(
            "Assigned Agent",
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.white
                  : Colors.white70,
            ),
          ),
          bottom: TabBar(
            labelColor: Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : Colors.white,
            unselectedLabelColor: Theme.of(context).brightness == Brightness.light
                ? Colors.white70
                : Colors.white54,
            tabs: const [
              Tab(text: 'Assigned'),
              Tab(text: 'Completed'),
            ],
          ),

        ),
        body: TabBarView(
          children: [
            _buildOrderList(context, _assignedOrdersFuture),
            _buildOrderList(context, _completedOrdersFuture),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(BuildContext context, Future<List<Order>> futureOrders) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[850] : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.black.withOpacity(0.1);
    final textColor = isDark ? Colors.white70 : Colors.black;

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
          return Center(
            child: Text(
              "No orders found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          );
        }

        List<Order> orders = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            Order order = orders[index];
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                border: Border.all(color: borderColor, width: 1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Order ${order.orderId ?? 'N/A'} - ${order.type ?? 'Unknown'}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _orderDetailRow(context, "Vendor ID", order.vendorId?.toString()),
                  _orderDetailRow(context, "Quantity", order.quantity),
                  _orderDetailRow(context, "Status", order.status),
                  _orderDetailRow(context, "User ID", order.userId?.toString()),
                  //_orderDetailRow(context, "Proposed Price", order.proposedUnitPrice),
               //_orderDetailRow(context, "Counter Price", order.counterUnitPrice),
                  _orderDetailRow(context, "Amount", order.amount),
                 // _orderDetailRow(context, "Vendor Status", order.vendorStatus),
                //  _orderDetailRow(context, "Agent ID", order.agentId?.toString()),
                  _orderDetailRow(context, "Oil Quality", order.oilQuality),
                 // _orderDetailRow(context, "Timeline", order.timeline),
                  _orderDetailRow(context, "Pickup Location", order.pickupLocation),
                  _orderDetailRow(context, "User Name", order.userName),
                  _orderDetailRow(context, "Contact", order.userContact),
                  _orderDetailRow(context, "Address", order.registeredAddress),
                  _orderDetailRow(context, "Pickup Date", order.date),
                  _orderDetailRow(context, "Time", order.time),
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
                          errorBuilder: (context, error, stackTrace) =>
                          const Text("Image load failed"),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _orderDetailRow(BuildContext context, String label, String? value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white70 : Colors.black;
    final valueColor = AppColors.secondaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              "$label:",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: labelColor),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Text(
              value ?? 'N/A',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14, color: valueColor),
            ),
          ),
        ],
      ),
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

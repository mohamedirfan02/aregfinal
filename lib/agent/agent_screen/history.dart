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
  List<Order> _allOrders = [];
  List<Order> _filteredOrders = [];
  String _selectedStatus = 'All';

  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Accepted',
    'Assigned',
    'Completed',
    'acknowledged',
    'Confirmed',
    'Declined'
  ];

  @override
  void initState() {
    super.initState();
    _ordersFuture = fetchOrders();
  }

  Color _getStatusColor(String? status, bool isDark) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return isDark ? Colors.orange.shade900 : Colors.orange.shade100;
      case 'accepted':
        return isDark ? Colors.green.shade900 : Colors.green.shade100;
      case 'declined':
        return isDark ? Colors.red.shade900 : Colors.red.shade100;
      case 'acknowledged':
        return isDark ? Colors.blue.shade900 : Colors.blue.shade100;
      case 'assigned':
        return isDark ? Colors.pink.shade900 : Colors.pink.shade100;
      case 'completed':
        return isDark ? Colors.purple.shade900 : Colors.purple.shade100;
      case 'confirmed':
        return isDark ? Colors.teal.shade900 : Colors.tealAccent.shade100;
      default:
        return isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    }
  }


  Future<List<Order>> fetchOrders() async {
    try {
      List<dynamic> ordersJson = await _orderApi.fetchOrders();
      List<Order> orders =
          ordersJson.map((json) => Order.fromJson(json)).toList();
      _allOrders = orders;
      _applyFilter();
      return orders;
    } catch (e) {
      debugPrint("Error fetching orders: $e");
      return [];
    }
  }

  void _applyFilter() {
    setState(() {
      if (_selectedStatus == 'All') {
        _filteredOrders = _allOrders;
      } else {
        _filteredOrders = _allOrders
            .where((order) =>
                order.status?.toLowerCase() == _selectedStatus.toLowerCase())
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black;

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : const Color(0xFF006D04),
          centerTitle: true,
          elevation: 4,
          title: Text(
            'Order History',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.white, // Keep white for consistency
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Text(
                      "Filter by status: ",
                      style: TextStyle(fontSize: 16, color: textColor),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedStatus,
                      dropdownColor: Theme.of(context).cardColor,
                      style: TextStyle(color: textColor),
                      items: _statusOptions
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _selectedStatus = value;
                          _applyFilter();
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
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
                            const Icon(Icons.error,
                                color: Colors.red, size: 50),
                            const SizedBox(height: 10),
                            Text(
                              "Error: ${snapshot.error}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    } else if (_filteredOrders.isEmpty) {
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

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      itemCount: _filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = _filteredOrders[index];
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: _getStatusColor(order.status, isDark),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black26 : Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              "Order #${order.orderId ?? 'N/A'} - ${order.type ?? 'Unknown'}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "Quantity: ${order.quantity ?? 'N/A'}",
                                      style: TextStyle(color: textColor)),
                                  Text("Status: ${order.status ?? 'N/A'}",
                                      style: TextStyle(color: textColor)),
                                  Text(
                                      "Agent Status: ${order.Vendorstatus ?? 'Not Assigned'}",
                                      style: TextStyle(color: textColor)),
                                  Text("User: ${order.userName ?? 'N/A'}",
                                      style: TextStyle(color: textColor)),
                                  Text(
                                      "Contact: ${order.userContact ?? 'N/A'}",
                                      style: TextStyle(color: textColor)),
                                  Text(
                                      "Address: ${order.registeredAddress ?? 'N/A'}",
                                      style: TextStyle(color: textColor)),
                                  Text("Date: ${order.date ?? 'N/A'}",
                                      style: TextStyle(color: textColor)),
                                  Text("Time: ${order.time ?? 'N/A'}",
                                      style: TextStyle(color: textColor)),
                                  // Text(
                                  //     "Proposed Price: ${order.proposedUnitPrice ?? 'N/A'}",
                                  //     style: TextStyle(color: textColor)),
                                  // Text(
                                  //     "Counter Price: ${order.counterUnitPrice ?? 'N/A'}",
                                  //     style: TextStyle(color: textColor)),
                                  Text("Amount: ${order.amount ?? 'N/A'}",
                                      style: TextStyle(color: textColor)),
                                  Text(
                                      "Oil Quality: ${order.oilQuality ?? 'N/A'}",
                                      style: TextStyle(color: textColor)),
                                  Text(
                                      "Timeline: ${order.timeline ?? 'N/A'}",
                                      style: TextStyle(color: textColor)),
                                  Text(
                                      "Pickup Location: ${order.pickupLocation ?? 'N/A'}",
                                      style: TextStyle(color: textColor)),
                                  if (order.oilImage != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          order.oilImage!,
                                          height: 120,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            trailing: order.status?.toLowerCase() == "declined"
                                ? const Icon(Icons.cancel, color: Colors.red)
                                : const Icon(Icons.check_circle,
                                    color: Colors.green),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ));
  }
}

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
  final String? proposedUnitPrice;
  final String? counterUnitPrice;
  final String? amount;
  final String? oilQuality;
  final String? oilImage;
  final String? timeline;
  final String? pickupLocation;

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
    required this.proposedUnitPrice,
    required this.counterUnitPrice,
    required this.amount,
    required this.oilQuality,
    required this.oilImage,
    required this.timeline,
    required this.pickupLocation,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json["order_id"] as int?,
      type: json["type"] as String? ?? "Unknown",
      quantity: json["quantity"] as String? ?? "0",
      status: json["status"] as String? ?? "",
      Vendorstatus: json["vendor_status"] as String? ?? "not assigned",
      userName: json["user_name"] as String? ?? "No Name",
      userContact: json["user_contact"] as String? ?? "No Contact",
      registeredAddress: json["registered_address"] as String? ?? "No Address",
      date: json["date"] as String? ?? "N/A",
      time: json["time"] as String? ?? "N/A",
      proposedUnitPrice: json["proposed_unit_price"]?.toString() ?? "0",
      counterUnitPrice: json["counter_unit_price"]?.toString() ?? "-",
      amount: json["amount"]?.toString() ?? "0",
      oilQuality: json["oil_quality"] as String? ?? "-",
      oilImage: json["oil_image"] as String?,
      timeline: json["timeline"] as String? ?? "-",
      pickupLocation: json["pickup_location"] as String? ?? "-",
    );
  }
}

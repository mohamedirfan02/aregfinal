import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CompletedOrdersScreen extends StatefulWidget {
  const CompletedOrdersScreen({super.key});

  @override
  State<CompletedOrdersScreen> createState() => _CompletedOrdersScreenState();
}

class _CompletedOrdersScreenState extends State<CompletedOrdersScreen> {
  List<dynamic> completedOrders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCompletedOrders();
  }

  /// ✅ Fetch completed orders dynamically
  Future<void> _fetchCompletedOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? vendorIdString = prefs.getString('vendor_id');
    int? vendorId = vendorIdString != null ? int.tryParse(vendorIdString) : null;

    if (token == null || vendorId == null) {
      debugPrint("❌ No token or vendor ID found.");
      setState(() => isLoading = false);
      return;
    }

    final url = "https://enzopik.thikse.in/api/get-user-oil-completed-sale";
    final body = jsonEncode({"role": "vendor", "id": vendorId});

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          completedOrders = jsonData["data"] ?? [];
          isLoading = false;
        });
      } else {
        debugPrint("❌ Failed to fetch completed orders: ${response.body}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("❌ Exception fetching completed orders: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Completed Orders")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // ✅ Show loader
          : completedOrders.isEmpty
          ? const Center(
        child: Text(
          "No completed orders found",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ) // ✅ Show empty state
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: completedOrders.length,
        itemBuilder: (context, index) {
          return _buildCompletedOrderCard(completedOrders[index]);
        },
      ),
    );
  }

  /// ✅ Completed Order Card UI
  Widget _buildCompletedOrderCard(Map<String, dynamic> order) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Order ID: #${order["order_id"]}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            const Divider(),
            _buildDetailRow("Oil Type", order["type"]),
            _buildDetailRow("Oil Quantity", "${order['quantity'] ?? 0} KG"),
            _buildDetailRow("Customer", order["user_name"]),
            _buildDetailRow("Phone", order["user_contact"]),
            _buildDetailRow("Address", order["registered_address"]?.toString() ?? "N/A"),
            _buildDetailRow("Date", order["date"]),
            _buildDetailRow("Time", order["time"]),
            _buildDetailRow("Pickup Date", order["timeline"]?.toString() ?? "N/A"),
            _buildDetailRow("Pickup Location", order["pickup_location"]?.toString() ?? "N/A"),
            _buildDetailRow("counter price", order["counter_unit_price"]?.toString() ?? "N/A"),
            buildDetailRow("Total Amount", "₹${order["amount"] ?? "N/A"}"),
          ],
        ),
      ),
    );
  }
  Widget buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
  /// ✅ Helper for displaying order details
  Widget _buildDetailRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text("$title: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value?.toString() ?? "N/A", // ✅ Handle null values safely
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

}

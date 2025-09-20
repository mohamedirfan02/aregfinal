import 'dart:convert';
import 'package:areg_app/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';

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

    final url = ApiConfig.getAllCompletedOrders;
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
      debugPrint("Response Body: ${response.body}");
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : AppColors.primaryColor,
        centerTitle: true,
        elevation: 4,
        title: Text(
          'Completed Orders',
          style: TextStyle(
            color: Colors.white, // keep white on both modes for contrast
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : completedOrders.isEmpty
          ? Center(
        child: Text(
          "No completed orders found",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: completedOrders.length,
        itemBuilder: (context, index) {
          return _buildCompletedOrderCard(completedOrders[index], theme, isDark);
        },
      ),
    );
  }

  /// Modified to accept theme and isDark params for colors
  Widget _buildCompletedOrderCard(Map<String, dynamic> order, ThemeData theme, bool isDark) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: isDark ? theme.cardColor : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order ID: ${order["order_id"]}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.titleColor, // use theme primary color (green-ish)
              ),
            ),
            Divider(color: isDark ? Colors.white24 : Colors.black26),
            _buildDetailRow(order, "Oil Type", order["type"], isDark),
            _buildDetailRow(order, "Oil Quantity", "${order['quantity'] ?? 0} KG", isDark),
            _buildDetailRow(order, "Customer", order["user_name"], isDark),
            _buildDetailRow(order, "Phone", order["user_contact"], isDark),
            _buildDetailRow(order, "Address", order["registered_address"]?.toString() ?? "N/A", isDark),
            _buildDetailRow(order, "Date", order["date"], isDark),
            _buildDetailRow(order, "Time", order["time"], isDark),
            _buildDetailRow(order, "Pickup Date", order["timeline"]?.toString() ?? "N/A", isDark),
            _buildDetailRow(order, "Pickup Location", order["pickup_location"]?.toString() ?? "N/A", isDark),
            _buildDetailRow(order, "Agreed Price", order["agreed_price"]?.toString() ?? "N/A", isDark),
            buildDetailRow("Total Amount", "₹${order["amount"] ?? "N/A"}", theme, isDark),
          ],
        ),
      ),
    );
  }

  /// Updated to include dark mode color for value text
  Widget _buildDetailRow(Map<String, dynamic> order, String title, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$title: ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDetailRow(String title, String value, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }


}

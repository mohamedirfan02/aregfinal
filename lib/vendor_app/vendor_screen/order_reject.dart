import 'dart:convert';
import 'package:areg_app/common/app_colors.dart';
import 'package:areg_app/core/storage/app_assets_constant.dart';
import 'package:areg_app/views/screens/widgets/k_svg.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../agent/common/common_appbar.dart';
import '../../config/api_config.dart';

class OrdersRejected extends StatefulWidget {
  const OrdersRejected({super.key});

  @override
  State<OrdersRejected> createState() => _OrdersRejectedState();
}

class _OrdersRejectedState extends State<OrdersRejected> {
  List<dynamic> rejectedOrders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRejectedOrders();
  }

  Future<void> fetchRejectedOrders() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? vendorId = prefs.getString('vendor_id'); // Ensure this exists in prefs

      if (token == null || vendorId == null) {
        print("❌ Missing token or vendor ID.");
        setState(() => isLoading = false);
        return;
      }

      final url =  Uri.parse(ApiConfig.getVendorRejectedOrders(vendorId));
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          rejectedOrders = jsonData['rejectedData'] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load rejected orders');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppbar(title: 'Rejected Orders',),
      backgroundColor: const Color(0xFFF5F5F5),
      body: isLoading
          ? const Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.fboColor), // ✅ custom color
            ),
            KSvg(
              svgPath: AppAssetsConstants.splashLogo,
              height: 30,
              width: 30,
              boxFit: BoxFit.cover,
            ),
          ],
        ),)
          : rejectedOrders.isEmpty
          ? const Center(
        child: Text("No rejected orders found", style: TextStyle(fontSize: 16)),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔷 Header Title
            const Text(
              "Review all rejected orders below.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              "Track order details, locations, and payment statuses with clarity.",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            // 🔷 Rejected Orders List
            ...rejectedOrders.map((order) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.cancel, color: Colors.red, size: 28),
                  ),
                  title: Text(
                    order['type'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow("Quantity", order['quantity']),
                        _buildDetailRow("Status", order['status']),
                        _buildDetailRow("Location", order['pickup_location']),
                        _buildDetailRow("Per kg Price", order['unit_price']),
                        _buildDetailRow("Amount", "₹${order['amount']}"),
                        _buildDetailRow("CP assigned payment method", "₹${order['payment_method']}"),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }


}

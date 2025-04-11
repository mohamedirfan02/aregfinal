import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import '../../common/shimmer_loader.dart'; // ✅ Import Global Shimmer
import '../../common/custom_GradientContainer.dart';
import '../../common/custom_appbar.dart';
import '../../fbo_services/FBO_voucher_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoucherHistoryScreen extends StatefulWidget {
  const VoucherHistoryScreen({super.key});

  @override
  _VoucherHistoryScreenState createState() => _VoucherHistoryScreenState();
}

class _VoucherHistoryScreenState extends State<VoucherHistoryScreen> {
  final VoucherService _voucherService = VoucherService();
  late Future<List<Map<String, dynamic>>> _vouchersFuture;
  String? userRole;

  Map<int, bool> isDownloading = {}; // ✅ Track download state

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    _vouchersFuture = _voucherService.fetchVouchers();
  }

  /// ✅ Fetch user role from shared preferences
  Future<void> _fetchUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('role');
    });
  }

  /// ✅ Handle voucher download with loading indicator
  Future<void> _downloadVoucher(int orderId, String format) async {
    setState(() {
      isDownloading[orderId] = true; // ✅ Show downloading indicator
    });

    try {
      String filePath = await _voucherService.downloadVoucher(orderId, format: format);
      print("✅ Voucher ($format) saved at: $filePath");
      _voucherService.openFile(filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Voucher ($format) downloaded successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to download voucher.")),
      );
    }

    setState(() {
      isDownloading[orderId] = false; // ✅ Hide downloading indicator
    });
  }

  /// ✅ Shimmer effect while loading data
  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 6, // ✅ Show 6 shimmer placeholders
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerLoader(height: 20, width: 100), // ✅ Fake Order ID
                const SizedBox(height: 10),
                const ShimmerLoader(height: 14), // ✅ Fake Type
                const ShimmerLoader(height: 14), // ✅ Fake Quantity
                const ShimmerLoader(height: 14, width: 150), // ✅ Fake Status
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Expanded(child: ShimmerLoader(height: 40)), // ✅ Fake PDF Button
                    const SizedBox(width: 10),
                    const Expanded(child: ShimmerLoader(height: 40)), // ✅ Fake Excel Button
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
    return Scaffold(
      body: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _vouchersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildShimmerList(); // ✅ Shimmer Effect Instead of Spinner
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No vouchers available."));
            }

            List<Map<String, dynamic>> vouchers = snapshot.data!;

            return ListView.builder(
              itemCount: vouchers.length,
              itemBuilder: (context, index) {
                final voucher = vouchers[index];
                int orderId = voucher["order_id"];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order ID: ${voucher["order_id"]}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Type: ${voucher["type"]}'),
                        Text('Quantity: ${voucher["quantity"]}'),
                        Text('Status: ${voucher["status"]}'),
                        if (voucher["unit_price"] != null)
                          Text('Unit Price: ₹${voucher["unit_price"]}'),
                        Text('User Name: ${voucher["user_name"]}'),
                        Text('Address: ${voucher["address"]}'),
                        Text('User Contact: ${voucher["user_contact"]}'),
                        Text('Amount: ₹${voucher["amount"]}'),
                        Text('Date: ${voucher["date"]}'),
                        Text('Time: ${voucher["time"]}'),

                        const SizedBox(height: 10),

                        // ✅ Buttons for PDF & Excel download
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // ✅ PDF Download Button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: isDownloading[orderId] == true
                                    ? null
                                    : () => _downloadVoucher(orderId, "pdf"),
                                icon: isDownloading[orderId] == true
                                    ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                                    : const Icon(Icons.picture_as_pdf, color: Colors.white),
                                label: Text(isDownloading[orderId] == true ? "Downloading..." : "PDF",
                                    style: const TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (userRole == "agent")
                            // ✅ Excel Download Button (Only for Agents)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: isDownloading[orderId] == true
                                      ? null
                                      : () => _downloadVoucher(orderId, "excel"),
                                  icon: isDownloading[orderId] == true
                                      ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                      : const Icon(Icons.table_chart, color: Colors.white),
                                  label: Text(isDownloading[orderId] == true ? "Downloading..." : "Excel",
                                      style: const TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                ),
                              ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

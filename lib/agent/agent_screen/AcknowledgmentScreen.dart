import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/shimmer_loader.dart';
import '../agent_service/agent_acknowledgment_service.dart';
import '../common/agent_appbar.dart';
import '../common/agent_gradient.dart';

class AgentAcknowledgmentScreen extends StatefulWidget {
  const AgentAcknowledgmentScreen({super.key});

  @override
  _AgentAcknowledgmentScreenState createState() => _AgentAcknowledgmentScreenState();
}

class _AgentAcknowledgmentScreenState extends State<AgentAcknowledgmentScreen> {
  final AgentAcknowledgmentService _acknowledgmentService = AgentAcknowledgmentService();
  List<Map<String, dynamic>> acknowledgmentList = [];
  bool isLoading = true;
  bool hasError = false;

  /// ✅ Track "Oil Received" checkbox states for each order
  Map<int, bool> oilReceived = {};

  @override
  void initState() {
    super.initState();
    fetchAcknowledgmentDetails();
  }

  /// ✅ Fetch acknowledgment details
  Future<void> fetchAcknowledgmentDetails() async {
    setState(() => isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userIdString = prefs.getString('user_id'); // Retrieve as String
    int? userId = userIdString != null ? int.tryParse(userIdString) : null; // Convert to int

    if (token == null || userId == null) {
      print("❌ Error: Token or User ID is missing or invalid.");
      setState(() {
        hasError = true;
        isLoading = false;
      });
      return;
    }

    final data = await _acknowledgmentService.fetchAcknowledgmentDetails(token, userId);

    if (data != null) {
      setState(() {
        acknowledgmentList = data;

        for (var order in acknowledgmentList) {
          oilReceived[order['order_id']] = false;
        }

        isLoading = false;
      });
    } else {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  /// ✅ Acknowledge an order
  Future<void> acknowledgeOrder(int orderId) async {
    if (oilReceived[orderId] != true) return; // Prevent acknowledgment if checkbox is unchecked

    bool success = await _acknowledgmentService.acknowledgeOrder(orderId);

    if (success) {
      setState(() {
        acknowledgmentList.removeWhere((order) => order['order_id'] == orderId);
        oilReceived.remove(orderId); // ✅ Remove checkbox state for acknowledged orders
      });
      showResponseDialog("Order acknowledged successfully!", "success");
    } else {
      showResponseDialog("Failed to acknowledge order!", "error");
    }
  }

  /// ✅ Show response dialog
  void showResponseDialog(String message, String status) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(status == "success" ? "Success" : "Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
  /// ✅ Build Shimmer UI for Loading State
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
                const ShimmerLoader(height: 14), // ✅ Fake Name
                const ShimmerLoader(height: 14, width: 150), // ✅ Fake Address
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
    return AgentGradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const AgentAppBar(title: 'Acknowledgment'),
        body: isLoading
            ? _buildShimmerList() // ✅ Show Shimmer While Loading
            : hasError
            ? const Center(child: Text("Failed to load data!"))
            : acknowledgmentList.isEmpty
            ? const Center(child: Text("No completed sales found!"))
            : ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: acknowledgmentList.length,
          itemBuilder: (context, index) {
            var order = acknowledgmentList[index];
            int orderId = order['order_id'];

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order ID: $orderId",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text("Type: ${order['type']}"),
                    Text("Quantity: ${order['quantity']}"),
                    Text("Status: ${order['status']}"),
                    Text("Unit Price: ₹${order['proposed_unit_price'] ?? 'Not Set'}"),
                    Text("Vendor ID: ${order['vendor_id'] ?? 'N/A'}"),
                    const SizedBox(height: 10),
                    Text(
                      "Customer Details:",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text("Name: ${order['user_name']}"),
                    Text("Contact: ${order['user_contact']}"),
                    Text("Address: ${order['registered_address']}"),
                    Text("Date: ${order['date']}"),
                    Text("Time: ${order['time']}"),
                    const SizedBox(height: 15),

                    // ✅ Checkbox for "Oil Received"
                    Row(
                      children: [
                        Checkbox(
                          value: oilReceived[orderId] ?? false,
                          onChanged: (bool? value) {
                            setState(() {
                              oilReceived[orderId] = value ?? false;
                            });
                          },
                        ),
                        const Text(
                          "Oil Received",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    // ✅ Acknowledge Button (Enabled only when checkbox is checked)
                    ElevatedButton(
                      onPressed: oilReceived[orderId] == true
                          ? () => acknowledgeOrder(orderId)
                          : null, // Disabled if unchecked
                      style: ElevatedButton.styleFrom(
                        backgroundColor: oilReceived[orderId] == true
                            ? Colors.green // ✅ Dark green when enabled
                            : Colors.green.withOpacity(0.5), // ✅ Light green when disabled
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Acknowledge", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

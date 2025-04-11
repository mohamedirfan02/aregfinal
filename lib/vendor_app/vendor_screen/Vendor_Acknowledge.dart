import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/custom_appbar.dart';
import '../../fbo_services/Fbo_Acknowledgment_Service.dart';

class VendorAcknowledge extends StatefulWidget {
  const VendorAcknowledge({super.key});

  @override
  _VendorAcknowledgeState createState() => _VendorAcknowledgeState();
}

class _VendorAcknowledgeState extends State<VendorAcknowledge> {
  List<dynamic> completedOrders = [];
  bool isLoading = true;
  bool hasError = false;
  Map<int, bool> paymentReceived = {}; // ✅ Track Payment Checkbox State

  @override
  void initState() {
    super.initState();
    fetchCompletedOrders();
  }

  /// ✅ Fetch completed orders
  Future<void> fetchCompletedOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? userId = prefs.getString('vendor_id');
    String? token = prefs.getString('token');

    if (userId == null || token == null) {
      print("❌ Error: User ID or token is missing");
      setState(() {
        hasError = true;
        isLoading = false;
      });
      return;
    }

    print("✅ Using User ID: $userId for API request");
    print("✅ Using Token: $token for API request");

    setState(() {
      isLoading = true;
      hasError = false;
    });

    final response = await FboAcknowledgmentService.fetchCompletedOrders(userId, token);

    if (response != null) {
      setState(() {
        completedOrders = response;
        isLoading = false;

        // ✅ Initialize checkbox state
        for (var order in completedOrders) {
          paymentReceived[order["order_id"]] = false;
        }
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
    bool success = await FboAcknowledgmentService.acknowledgeOrder(orderId);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Order #$orderId acknowledged successfully!")),
      );

      setState(() {
        completedOrders.removeWhere((order) => order["order_id"] == orderId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to acknowledge order. Try again!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : hasError
            ? const Center(child: Text("Failed to load completed orders"))
            : ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: completedOrders.length,
          itemBuilder: (context, index) {
            var order = completedOrders[index];
            int orderId = order["order_id"];

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
                    Text("Unit Price: ₹${order['unit_price'] ?? 'N/A'}"),
                    const SizedBox(height: 10),
                    Text(
                      "Customer Details:",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text("Name: ${order['user_name']}"),
                    Text("Contact: ${order['user_contact']}"),
                    Text("Address: ${order['address']}"),
                    const SizedBox(height: 10),
                    Text(
                      "Date & Time:",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text("Date: ${order['date']}"),
                    Text("Time: ${order['time']}"),
                    const SizedBox(height: 15),

                    // ✅ Payment Received Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: paymentReceived[orderId] ?? false,
                          onChanged: (value) {
                            setState(() {
                              paymentReceived[orderId] = value!;
                            });
                          },
                        ),
                        const Text(
                          "Payment Received",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ✅ Acknowledge Button (Enabled only if Payment Received)
                    ElevatedButton(
                      onPressed: paymentReceived[orderId] == true
                          ? () => acknowledgeOrder(orderId)
                          : null, // Disabled if unchecked
                      style: ElevatedButton.styleFrom(
                        backgroundColor: paymentReceived[orderId] == true
                            ? Colors.green
                            : Colors.green.shade300, // Light green when disabled
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

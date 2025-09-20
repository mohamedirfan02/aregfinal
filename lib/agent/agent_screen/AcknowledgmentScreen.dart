import 'package:areg_app/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/shimmer_loader.dart';
import '../agent_service/agent_acknowledgment_service.dart';
import '../common/agent_appbar.dart';

class AgentAcknowledgmentScreen extends StatefulWidget {
  const AgentAcknowledgmentScreen({super.key});

  @override
  _AgentAcknowledgmentScreenState createState() =>
      _AgentAcknowledgmentScreenState();
}

class _AgentAcknowledgmentScreenState extends State<AgentAcknowledgmentScreen> {
  final AgentAcknowledgmentService _acknowledgmentService =
      AgentAcknowledgmentService();
  List<Map<String, dynamic>> acknowledgmentList = [];
  bool isLoading = true;
  bool hasError = false;
  Map<int, bool> isAcknowledging = {};


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
    int? userId = userIdString != null
        ? int.tryParse(userIdString)
        : null; // Convert to int

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
    if (oilReceived[orderId] != true)
      return; // Prevent acknowledgment if checkbox is unchecked

    bool success = await _acknowledgmentService.acknowledgeOrder(orderId);

    if (success) {
      setState(() {
        acknowledgmentList.removeWhere((order) => order['order_id'] == orderId);
        oilReceived
            .remove(orderId); // ✅ Remove checkbox state for acknowledged orders
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
        return const Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoader(height: 20, width: 100), // ✅ Fake Order ID
                SizedBox(height: 10),
                ShimmerLoader(height: 14), // ✅ Fake Name
                ShimmerLoader(height: 14, width: 150), // ✅ Fake Address
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: ShimmerLoader(height: 40)),
                    // ✅ Fake PDF Button
                    SizedBox(width: 10),
                    Expanded(child: ShimmerLoader(height: 40)),
                    // ✅ Fake Excel Button
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
    //final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: const AgentAppBar(title: 'Acknowledgment'),
      body: isLoading
          ? _buildShimmerList()
          : hasError
          ? const Center(child: Text("Failed to load data!"))
          : acknowledgmentList.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/no_data.json',
              width: 200,
              height: 200,
              repeat: false,
            ),
            const SizedBox(height: 20),
            const Text(
              "No Acknowledgement List yet!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: acknowledgmentList.length,
        itemBuilder: (context, index) {
          var order = acknowledgmentList[index];
          int orderId = order['order_id'];

          return Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order ID + Type
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Order #$orderId",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          order['restaurant_name'],
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Info Rows
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _infoTile("Quantity", "${order['quantity']}"),
                      _infoTile("Status", "${order['status']}"),
                    ],
                  ),

                  const Divider(height: 30, thickness: 1.2),

                  // Customer Details
                  const Text(
                    "Customer Details",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _infoRow(Icons.person, "Name", order['user_name']),
                  _infoRow(Icons.restaurant, "Restaurant name", order['type']),
                  _infoRow(Icons.phone, "Contact", order['user_contact']),
                  _infoRow(Icons.location_on, "Address", order['registered_address']),
                  _infoRow(Icons.calendar_today, "Date", order['date']),
                  _infoRow(Icons.access_time, "Time", order['time']),
                  _infoRow(Icons.payment, "Payment", order['payment_method']),

                  const SizedBox(height: 16),

                  // Oil Received + Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                      ElevatedButton.icon(
                        onPressed: oilReceived[orderId] == true && isAcknowledging[orderId] != true
                            ? () async {
                          setState(() {
                            isAcknowledging[orderId] = true;
                          });

                          await acknowledgeOrder(orderId); // your async function

                          setState(() {
                            isAcknowledging[orderId] = false;
                          });
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: oilReceived[orderId] == true
                              ? AppColors.secondaryColor
                              : Colors.green.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: isAcknowledging[orderId] == true
                            ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.check_circle, color: Colors.white),
                        label: const Text(
                          "Acknowledge",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),

                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _infoTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text("$title: $value"),
    );
  }

  Widget _infoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              "$label: ${value ?? 'N/A'}",
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

}

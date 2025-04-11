import 'dart:io';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../common/shimmer_loader.dart';

class AgentCartPage extends StatefulWidget {
  const AgentCartPage({super.key});

  @override
  State<AgentCartPage> createState() => _AgentCartPageState();
}

class _AgentCartPageState extends State<AgentCartPage> {
  List<dynamic> pendingOrders = [];
  List<dynamic> confirmedOrders  = [];
  List<dynamic> completedOrders = []; // ✅ Store completed orders
  Map<int, File?> capturedImages = {}; // Declare globally to store images per order
  bool isLoading = false;

  final Map<int, bool> showCollectionOptions = {};
  final Map<int, String> selectedCollectionMethod = {};
  final Map<int, bool> onlinePaySelected = {};
  final Map<int, bool> cashPaySelected = {};
  final Map<int, TextEditingController> amountControllers = {};
  final Map<int, TextEditingController> vendorIdControllers = {};
//  final Map<int, TextEditingController> unitPriceControllers = {};

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() => isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? agentId = prefs.getString('agent_id');

    if (token == null || agentId == null) {
      print("❌ No token or agent_id found. User must log in again.");
      setState(() => isLoading = false);
      return;
    }

    final Uri uri = Uri.parse("https://enzopik.thikse.in/api/get-order-details");
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final Map<String, dynamic> bodyPending = {
      "role": "agent",
      "id": int.parse(agentId),
      "status": "pending",
    };

    final Map<String, dynamic> bodyConfirmed = {
      "role": "agent",
      "id": int.parse(agentId),
      "status": "confirmed",
    };

    final Map<String, dynamic> bodyCompleted = {
      "role": "agent",
      "id": int.parse(agentId),
      "status": "completed",
    };

    try {
      final responsePending = await http.post(uri, headers: headers, body: jsonEncode(bodyPending));
      final responseConfirmed = await http.post(uri, headers: headers, body: jsonEncode(bodyConfirmed));
      final responseCompleted = await http.post(uri, headers: headers, body: jsonEncode(bodyCompleted));

      if (responsePending.statusCode == 200 &&
          responseConfirmed.statusCode == 200 &&
          responseCompleted.statusCode == 200) {
        final dataPending = jsonDecode(responsePending.body);
        final dataConfirmed = jsonDecode(responseConfirmed.body);
        final dataCompleted = jsonDecode(responseCompleted.body);

        setState(() {
          pendingOrders = dataPending['data'] ?? [];
          confirmedOrders = dataConfirmed['data'] ?? [];
          completedOrders = dataCompleted['data'] ?? [];

          print("✅ Pending Orders: $pendingOrders");
          print("✅ Confirmed Orders: $confirmedOrders");
          print("✅ Completed Orders: $completedOrders");
        });
      } else {
        print("❌ Failed to load orders");
        print("Pending Response: ${responsePending.body}");
        print("Confirmed Response: ${responseConfirmed.body}");
        print("Completed Response: ${responseCompleted.body}");
      }
    } catch (e) {
      print("❌ Exception Occurred: $e");
    }

    setState(() => isLoading = false);
  }
  Future<void> updateOrderStatus(int orderId, String status,{String? reason}) async {
    final String apiUrl = "https://enzopik.thikse.in/api/update-oil-sale/$orderId";

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? agentId = prefs.getString('agent_id');

    if (token == null || agentId == null) {
      print("❌ No token or agent_id found. User must log in again.");
      return;
    }

    // Prepare the request body
    Map<String, dynamic> requestBody = {
      "agent_id": agentId,
      "status": status,
    };
    if (reason != null) {
      requestBody["reason"] = reason;
    }
    if (status == "assigned" || status == "confirmed") {

      if (onlinePaySelected[orderId] == true) {
        requestBody["payment_method"] = "online";
      } else if (cashPaySelected[orderId] == true) {
        requestBody["payment_method"] = "cash";
      } else {
        print("❌ Payment method is required.");
        return;
      }

      if (status == "assigned") {
        String vendorId = vendorIdControllers[orderId]?.text ?? "";
        if (vendorId.isNotEmpty) {
          requestBody["vendor_id"] = vendorId;
        } else {
          print("❌ Vendor ID is required for assignment.");
          return;
        }
      }
    }

    if (status == "completed") {
      requestBody["oil_quality"] = oilQuality[orderId] ?? "Good";
      requestBody["payment"] = paymentDone[orderId] == true ? "done" : "pending";
      requestBody["reason"] = remarksControllers[orderId]?.text ?? "";
     // requestBody["unit_price"] = unitPriceControllers[orderId]?.text.replaceAll(RegExp(r'[^\d.]'), '') ?? "0"; // ✅

      if (!requestBody.containsKey("oil_quality")) {
        print("❌ Oil quality is missing in request body!");
      }
    }

    try {
      print("📤 Sending API Request: $requestBody");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      final jsonData = json.decode(response.body);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData["status"] == "success") {
          print("✅ Order Updated Successfully");
          fetchOrders();
        } else {
          print("❌ API Error: ${jsonData["message"]}");
        }
      } else {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.scale,
          title: "Error",
          desc: jsonData["message"] ?? "Failed to update order.",
          btnOkOnPress: () {},
        ).show();
      }
    } catch (e) {
      print("❌ Exception Occurred: $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Image.asset("assets/icon/back.png", width: 24, height: 24),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/AgentPage');
                }
              },
            ),
            title: const Text("Collection Details"),
            bottom: const TabBar(
              labelColor: Colors.green,
              unselectedLabelColor: Colors.black54,
              indicatorColor: Colors.green,
              tabs: [
                Tab(text: "Pending"),
                Tab(text: "Accepted"),
                Tab(text: "Completed"), // ✅ New Completed Tab
              ],
            ),
          ),
          body: isLoading
              ? _buildShimmerList() // ✅ Show Shimmer While Loading
              : TabBarView(
            children: [
              _buildOrderList(pendingOrders, isPending: true), // ✅ Pending Orders
              _buildOrderList(confirmedOrders , isPending: false), // ✅ Accepted Orders
              _buildOrderList(completedOrders, isPending: false, isCompleted: true), // ✅ Completed Orders
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildOrderList(List<dynamic> orders, {required bool isPending, bool isCompleted = false}) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          isPending
              ? "No pending orders"
              : isCompleted
              ? "No completed orders"
              : "No accepted orders",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildNotificationCard(orders[index], isPending, isCompleted);
      },
    );
  }


  Widget _buildNotificationCard(dynamic order, bool isPending, bool isCompleted) {
    if (order == null || order['order_id'] == null) {
      return const SizedBox(); // Prevent crash by returning an empty widget
    }

    int orderId = order['order_id'];
    amountControllers.putIfAbsent(orderId, () => TextEditingController());
    vendorIdControllers.putIfAbsent(orderId, () => TextEditingController());

    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      decoration: _boxDecoration(),
      child: Column(
        children: [
          Text(
            "Order ID: $orderId",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const Divider(),
          Text(order['user_name'] ?? "Unknown", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          _buildDetailRow("Order ID", order['order_id'].toString() ?? "N/A"),
          _buildDetailRow("Oil Type", order['type'] ?? "N/A"),
          _buildDetailRow("Oil Quantity", "${order['quantity'] ?? 0} KG"),
          buildDetailRow("Unit Price", "₹${order["proposed_unit_price"] ?? "N/A"}"),
          buildDetailRow("counter_unit_price", "₹${order["counter_unit_price"] ?? "N/A"}"),
          buildDetailRow("Total Amount", "₹${order["amount"] ?? "N/A"}"),
          buildDetailRow("Status", order["status"] ?? "N/A"),
          _buildDetailRow("Date", order['date'] ?? "N/A"),
          _buildDetailRow("Time", order['time'] ?? "N/A"),
          _buildDetailRow("Address", order['registered_address'] ?? "N/A"),
          _buildDetailRow("Phone Number", order['user_contact'] ?? "N/A", isPhoneNumber: true),
          _buildDetailRow("pickup location", order['pickup_location'] ?? "N/A"),
          _buildDetailRow("Pickup Time", order['timeline'] ?? "N/A"),
          const SizedBox(height: 10),

          if (isCompleted) ...[
            const Text("✅ Order Completed", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
          ],

          if (isPending)
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          showCollectionOptions[orderId] = true; // Show collection options
                        });
                        print("✅ Accept clicked for Order ID: $orderId");
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text("Accept", style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      onPressed: () => _showDeclineDialog(orderId), // ✅ Now opens the reason dialog
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("Decline", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                if (showCollectionOptions[orderId] ?? false) _buildCollectionOptions(orderId), // Show options
              ],
            ),

          if (!isPending && !isCompleted) _buildAcceptedOptions(orderId),
        ],
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
  final Map<int, String> oilQuality = {};
  final Map<int, bool> paymentDone = {};
  final Map<int, TextEditingController> remarksControllers = {};

  Widget _buildAcceptedOptions(int orderId) {
    remarksControllers.putIfAbsent(orderId, () => TextEditingController());

    return Column(
      children: [
        const SizedBox(height: 10),
        const Text("Oil Quality", style: TextStyle(fontWeight: FontWeight.bold)),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildOilQualityCheckbox(orderId, "Excellent"),
            _buildOilQualityCheckbox(orderId, "Good"),
            _buildOilQualityCheckbox(orderId, "Poor"),
          ],
        ),

        Row(
          children: [
            Checkbox(
              value: paymentDone[orderId] ?? false,
              onChanged: (value) {
                setState(() {
                  paymentDone[orderId] = value!;
                });
              },
            ),
            const Text("Payment Done"),
          ],
        ),

        TextField(
          controller: remarksControllers[orderId],
          decoration: const InputDecoration(labelText: "reason"),
        ),

        const SizedBox(height: 10),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => _captureImage(orderId),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text("Capture"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 10),
            if (capturedImages[orderId] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  capturedImages[orderId]!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
        ElevatedButton(
          onPressed: () => updateOrderStatus(orderId, "completed"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text("Complete Order", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
  /// ✅ Image Picker for camera
  Future<void> _captureImage(int orderId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        capturedImages[orderId] = File(image.path);
      });
    } else {
      debugPrint("No image captured.");
    }
  }
  Widget _buildOilQualityCheckbox(int orderId, String quality) {
    return Row(
      children: [
        Checkbox(
          value: oilQuality[orderId] == quality,
          onChanged: (value) {
            if (value!) {
              setState(() {
                oilQuality[orderId] = quality;
              });
            }
          },
        ),
        Text(quality),
      ],
    );
  }
  void _showDeclineDialog(int orderId) {
    TextEditingController reasonController = TextEditingController();

    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: "Decline Order",
      desc: "Please enter the reason for declining this order:",
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: "Reason",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      btnCancel: TextButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Text("Cancel", style: TextStyle(color: Colors.red)),
      ),
      btnOk: TextButton(
        onPressed: () {
          if (reasonController.text.isNotEmpty) {
            Navigator.pop(context); // Close dialog
            updateOrderStatus(orderId, "declined", reason: reasonController.text);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Reason cannot be empty!")),
            );
          }
        },
        child: const Text("Submit", style: TextStyle(color: Colors.green)),
      ),
    ).show();
  }

  Widget _buildCollectionOptions(int orderId) {
    return Column(
      children: [
        const SizedBox(height: 10),
        const Text("Choose Collection Method:", style: TextStyle(fontWeight: FontWeight.bold)),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => setState(() {
                selectedCollectionMethod[orderId] = "self";
                print("✅ Self Collection Selected for Order: $orderId");
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedCollectionMethod[orderId] == "self"
                    ? Colors.green
                    : Colors.grey,
              ),
              child: const Text("Self Collection"),
            ),
            ElevatedButton(
              onPressed: () => setState(() {
                selectedCollectionMethod[orderId] = "Agent";
                print("✅ Assigned to Agent for Order: $orderId");
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedCollectionMethod[orderId] == "Agent"
                    ? Colors.green
                    : Colors.grey,
              ),
              child: const Text("Assign to Agent"),
            ),
          ],
        ),
        _buildPaymentOptions(orderId, isPending: true),
      ],
    );
  }

  Widget _buildPaymentOptions(int orderId, {required bool isPending}) {
    // Ensure controllers exist
    //unitPriceControllers.putIfAbsent(orderId, () => TextEditingController());
    amountControllers.putIfAbsent(orderId, () => TextEditingController());
    vendorIdControllers.putIfAbsent(orderId, () => TextEditingController());

    return Column(
      children: [
        if (isPending) ...[
          const SizedBox(height: 10),
          // ✅ Payment Method Selection
          Row(
            children: [
              Checkbox(
                value: onlinePaySelected[orderId] ?? false,
                onChanged: (value) => setState(() {
                  onlinePaySelected[orderId] = value!;
                  cashPaySelected[orderId] = !value;
                }),
              ),
              const Text("Online Pay"),
              Checkbox(
                value: cashPaySelected[orderId] ?? false,
                onChanged: (value) => setState(() {
                  cashPaySelected[orderId] = value!;
                  onlinePaySelected[orderId] = !value;
                }),
              ),
              const Text("Cash Pay"),
            ],
          ),

          // ✅ Vendor ID Field (if assigned to vendor)
          if (selectedCollectionMethod[orderId] == "Agent")
            TextField(
              controller: vendorIdControllers[orderId],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Enter Agent ID"),
            ),

          const SizedBox(height: 10),

          // ✅ Submit Button
          ElevatedButton(
            onPressed: () => updateOrderStatus(
              orderId,
              selectedCollectionMethod[orderId] == "self" ? "confirmed" : "assigned",
            ),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Submit", style: TextStyle(color: Colors.white)),
          ),
        ],
      ],
    );
  }
}


Widget _buildDetailRow(String title, String value, {bool isPhoneNumber = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text("$title: ", style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
        if (isPhoneNumber) // Show WhatsApp icon only for phone numbers
          IconButton(
            icon: Image.asset("assets/icon/car.png"), // Ensure this icon exists
            iconSize: 24,
            onPressed: () async {
              String phoneNumber = value.replaceAll(RegExp(r'\D'), ''); // Remove non-numeric chars

              if (!phoneNumber.startsWith("91")) { // Ensure country code is added (India Example)
                phoneNumber = "91$phoneNumber";
              }

              final Uri whatsappUri = Uri.parse("whatsapp://send?phone=$phoneNumber");
              bool canLaunch = await canLaunchUrl(whatsappUri);
              debugPrint("📱 Can launch WhatsApp? $canLaunch");
              debugPrint("✅ Final WhatsApp URL: $whatsappUri"); // Debugging log

              if (await canLaunchUrl(whatsappUri)) {
                await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
              } else {
                debugPrint("❌ WhatsApp is not installed or cannot be launched.");
              }
            },
          ),
      ],
    ),
  );
}
BoxDecoration _boxDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10),
    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2)],
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
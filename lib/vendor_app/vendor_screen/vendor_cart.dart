import 'dart:convert';
import 'dart:io';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VendorCartPage extends StatefulWidget {
  const VendorCartPage({super.key});

  @override
  State<VendorCartPage> createState() => _VendorCartPageState();
}

class _VendorCartPageState extends State<VendorCartPage> with SingleTickerProviderStateMixin {
  List<dynamic> pendingOrders = []; // ✅ Store pending orders
  List<dynamic> approvedOrders = []; // ✅ Store approved order
  //List<dynamic> completedOrders = []; // ✅ Completed orders
  bool isLoading = true;
  Map<int, bool> isAccepted = {}; // ✅ Track accepted orders
  Map<int, String?> selectedOilQuality = {};
  Map<int, String?> selectedRemarks = {};
  Map<int, bool> isPaymentDone = {};
  Map<int, File?> capturedImages = {}; // Declare globally to store images per order


  late TabController _tabController; // ✅ Tab controller for Pending and Approved tabs

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // ✅ Initialize tab controller
    _fetchAssignedOrders();
  ///  _fetchCompletedOrders(); // ✅ Fetch completed orders
  }

  @override
  void dispose() {
    _tabController.dispose(); // ✅ Dispose tab controller
    super.dispose();
  }
  /// ✅ Refresh order list after any action
  void _refreshOrders() {
    setState(() {
      isLoading = true; // ✅ Show loading indicator while fetching data
    });
    _fetchAssignedOrders();
  }

  /// ✅ Fetch all assigned orders from API
  Future<void> _fetchAssignedOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? vendorIdString = prefs.getString('vendor_id');
    int? vendorId = vendorIdString != null ? int.tryParse(vendorIdString) : null;

    if (token == null || vendorId == null) {
      debugPrint("❌ No token or vendor ID found. User must log in again.");
      setState(() => isLoading = false);
      return;
    }

    final url = "https://enzopik.thikse.in/api/get-vendor-assigned-sale/$vendorId";
    debugPrint("Fetching data from: $url");

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("Response Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData["status"] == "success") {
          setState(() {
            pendingOrders = jsonData["pendingData"] ?? []; // ✅ Fetch Pending Orders
            approvedOrders = jsonData["approvedData"] ?? []; // ✅ Fetch Approved Orders
            isLoading = false;
          });
        } else {
          debugPrint("❌ API returned an unexpected format");
          setState(() => isLoading = false);
        }
      } else {
        debugPrint("❌ API request failed with status code: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("❌ Error fetching data: $e");
      setState(() => isLoading = false);
    }
  }


  /// ✅ Accept Order (Move from Pending to Approved)
  Future<void> _acceptOrder(int orderId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      debugPrint("❌ No token found.");
      return;
    }

    final url = "https://enzopik.thikse.in/api/update-oil-sale/$orderId";
    debugPrint("Updating order: $url");

    final body = jsonEncode({
      "vendor_status": "accepted", // ✅ Update vendor_status to "accepted"
    });

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

      debugPrint("Update Response Code: ${response.statusCode}");
      debugPrint("Update Response Body: ${response.body}");

      final jsonData = json.decode(response.body);
      if (response.statusCode == 200 && jsonData["status"] == "success") {
        setState(() {
          var order = pendingOrders.firstWhere((order) => order["order_id"] == orderId);
          pendingOrders.removeWhere((order) => order["order_id"] == orderId);
          approvedOrders.add(order);
          isAccepted[orderId] = true;
        });
        _refreshOrders();
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
      debugPrint("❌ Error updating order: $e");
    }
  }

  /// ✅ Decline Order (Remove from Pending and update vendor_status)
  Future<void> _declineOrder(int orderId,{String? reason}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      debugPrint("❌ No token found.");
      return;
    }

    final url = "https://enzopik.thikse.in/api/update-oil-sale/$orderId";
    debugPrint("Updating order: $url");

    final body = jsonEncode({
      "vendor_status": "declined", // ✅ Update vendor_status to "declined"
      if (reason != null) "decline_reason": reason, // ✅ Send reason if available
    });

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

      debugPrint("Update Response Code: ${response.statusCode}");
      debugPrint("Update Response Body: ${response.body}");

      final jsonData = json.decode(response.body);
      if (response.statusCode == 200 && jsonData["status"] == "success") {
        _refreshOrders();
        setState(() {
          pendingOrders.removeWhere((order) => order["order_id"] == orderId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order Declined")),
        );
      } else {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.scale,
          title: "Error",
          desc: jsonData["message"] ?? "Failed to decline order.",
          btnOkOnPress: () {},
        ).show();
      }
    } catch (e) {
      debugPrint("❌ Error declining order: $e");
    }
  }

  /// ✅ Submit Order (Update Vendor Status via API)
  Future<void> _submitOrder(int orderId) async {
    if (selectedOilQuality[orderId] == null) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.scale,
        title: "Error",
        desc: "Check the quality of the used oil",
        btnOkOnPress: () {},
      ).show();
      return;
    }

    if (!(isPaymentDone[orderId] ?? false)) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.scale,
        title: "Error",
        desc: "Please confirm payment status before submitting.",
        btnOkOnPress: () {},
      ).show();
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      debugPrint("❌ No token found.");
      return;
    }

    final url = Uri.parse("https://enzopik.thikse.in/api/update-oil-sale/$orderId");

    final imageFile = capturedImages[orderId];
    final oilQuality = selectedOilQuality[orderId];
    final remarks = selectedRemarks[orderId] ?? "";

    debugPrint("🔽 Submitting data:");
    debugPrint("Order ID: $orderId");
    debugPrint("Oil Quality: $oilQuality");
    debugPrint("Remarks: $remarks");
    debugPrint("Status: completed");
    debugPrint("Payment: done");
    debugPrint("Image Path: ${imageFile?.path}");

    try {
      final request = http.MultipartRequest("POST", url)
        ..headers["Authorization"] = "Bearer $token"
        ..fields["oil_quality"] = oilQuality!
        ..fields["status"] = "completed"
        ..fields["vendor_status"] = "accepted"
        ..fields["payment"] = "done"
        ..fields["remarks"] = remarks;

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('oil_image', imageFile.path));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      debugPrint("🧾 Multipart Response Code: ${response.statusCode}");
      debugPrint("🧾 Multipart Response Body: $responseBody");

      final jsonData = json.decode(responseBody);
      if (response.statusCode == 200 && jsonData["status"] == "success") {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.success,
          animType: AnimType.scale,
          title: "Success",
          desc: "Order Updated Successfully!",
          btnOkOnPress: () {
            setState(() {
              approvedOrders.removeWhere((order) => order["order_id"] == orderId);
            });
          },
        ).show();
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
      debugPrint("❌ Error submitting order with image: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "Agent Cart",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: "Pending"),
              Tab(text: "Approved"),
            //  Tab(text: "Completed"), // ✅ Added Completed Tab
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // ✅ Pending Tab
            _buildOrderList(pendingOrders, isPending: true),
            // ✅ Approved Tab
            _buildOrderList(approvedOrders, isPending: false),
           // _buildOrderList(completedOrders, isPending: false, isCompleted: true), // ✅ Completed Orders
          ],
        ),
      ),
    );
  }

  /// ✅ Build Order List (for Pending and Approved tabs)
  Widget _buildOrderList(List<dynamic> orders, {required bool isPending,bool isCompleted = false}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? const Center(
        child: Text(
          "No orders available",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      )
          :
      ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _buildMessageCard(orders[index], isPending: isPending);
        },
      ),
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
            _declineOrder(orderId, reason: reasonController.text);
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

  /// ✅ Message Card UI (for each order)
  Widget _buildMessageCard(Map<String, dynamic> order, {required bool isPending, bool isCompleted = false}) {
    int orderId = order["order_id"];
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Order #$orderId",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          const Divider(thickness: 1.2),
          const SizedBox(height: 8),

          ...[
            _buildDetailRow("🛢 Oil Type", order["type"]?.toString() ?? "N/A"),
            _buildDetailRow("⚖ Quantity", "${order["quantity"] ?? 0} KG"),
            _buildDetailRow("👤 Customer", order["user_name"]?.toString() ?? "N/A"),
            _buildDetailRow("📞 Phone", order["user_contact"]?.toString() ?? "N/A"),
            _buildDetailRow("📍 Address", order["registered_address"]?.toString() ?? "N/A"),
            _buildDetailRow("📆 Date", order["date"]?.toString() ?? "N/A"),
            _buildDetailRow("⏰ Time", order["time"]?.toString() ?? "N/A"),
            _buildDetailRow("📦 Pickup Date", order["timeline"]?.toString() ?? "N/A"),
            _buildDetailRow("📌 Pickup Location", order["pickup_location"]?.toString() ?? "N/A"),
            _buildDetailRow("💰 Counter Price", order["counter_unit_price"]?.toString() ?? "N/A"),
          ].expand((row) => [row, const SizedBox(height: 4)]),

          const SizedBox(height: 12),

          if (isPending)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptOrder(orderId),
                    icon: const Icon(Icons.check_circle_outline),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    label: const Text("Accept", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDeclineDialog(orderId),
                    icon: const Icon(Icons.cancel_outlined),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    label: const Text("Decline", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),

          if (!isPending) ...[
            const SizedBox(height: 12),
            const Text("🧪 Oil Quality", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ...["Excellent", "Good", "Poor"].map((quality) {
              return RadioListTile<String>(
                title: Text(quality),
                value: quality,
                groupValue: selectedOilQuality[orderId],
                onChanged: (value) {
                  setState(() => selectedOilQuality[orderId] = value);
                },
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),

            const SizedBox(height: 10),

            TextField(
              onChanged: (value) => setState(() => selectedRemarks[orderId] = value),
              decoration: InputDecoration(
                labelText: "✏️ Remarks (Optional)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Checkbox(
                  value: isPaymentDone[orderId] ?? false,
                  onChanged: (value) => setState(() => isPaymentDone[orderId] = value ?? false),
                ),
                const Text("💳 Payment Done"),
              ],
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

            const SizedBox(height: 12),
            Center(
              child: ElevatedButton(
                onPressed: () => _submitOrder(orderId),
                child: const Text("Submit", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
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


  Widget _buildDetailRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text("$title: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(value ?? "N/A", style: const TextStyle(color: Colors.black54)), // ✅ Default to "N/A"
          ),
        ],
      ),
    );
  }

}
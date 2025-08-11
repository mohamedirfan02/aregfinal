import 'dart:convert';
import 'dart:io';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';

class VendorCartPage extends StatefulWidget {
  const VendorCartPage({super.key});

  @override
  State<VendorCartPage> createState() => _VendorCartPageState();
}

class _VendorCartPageState extends State<VendorCartPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> pendingOrders = []; // ✅ Store pending orders
  List<dynamic> approvedOrders = []; // ✅ Store approved order
  //List<dynamic> completedOrders = []; // ✅ Completed orders
  bool isLoading = true;
  Map<int, bool> isAccepting = {};
  Map<int, bool> isAccepted = {}; // ✅ Track accepted orders
  Map<int, String?> selectedOilQuality = {};
  Map<int, String?> selectedRemarks = {};
  Map<int, bool> isPaymentDone = {};
  Map<int, File?> capturedImages = {}; // Declare globally to store images per order

  late TabController _tabController; // ✅ Tab controller for Pending and Approved tabs

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this); // ✅ Initialize tab controller
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
    int? vendorId =
        vendorIdString != null ? int.tryParse(vendorIdString) : null;

    if (token == null || vendorId == null) {
      debugPrint("❌ No token or vendor ID found. User must log in again.");
      setState(() => isLoading = false);
      return;
    }

    final url = ApiConfig.getVendorAssignedSale(vendorId.toString());

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
            pendingOrders =
                jsonData["pendingData"] ?? []; // ✅ Fetch Pending Orders
            approvedOrders =
                jsonData["approvedData"] ?? []; // ✅ Fetch Approved Orders
            isLoading = false;
          });
        } else {
          debugPrint("❌ API returned an unexpected format");
          setState(() => isLoading = false);
        }
      } else {
        debugPrint(
            "❌ API request failed with status code: ${response.statusCode}");
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

    final url = ApiConfig.updateOilSale(orderId);

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
          var order =
              pendingOrders.firstWhere((order) => order["order_id"] == orderId);
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
  Future<void> _declineOrder(int orderId, {String? reason}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      debugPrint("❌ No token found.");
      return;
    }

    final url = ApiConfig.updateOilSale(orderId);

    debugPrint("Updating order: $url");

    final body = jsonEncode({
      "vendor_status": "declined",
      // ✅ Update vendor_status to "declined"
      if (reason != null) "reason": reason,
      // ✅ Send reason if available
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

    setState(() => isLoading = true); // 👈 Show loader before submission

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        debugPrint("❌ No token found.");
        return;
      }

      final url = Uri.parse(ApiConfig.updateOilSale(orderId));
      final imageFile = capturedImages[orderId];
      debugPrint("🟡 Is this the compressed image? ${imageFile?.path.contains('compressed')}");
      final oilQuality = selectedOilQuality[orderId];
      final remarks = selectedRemarks[orderId] ?? "";

      debugPrint("🔽 Submitting data:");
      debugPrint("Order ID: $orderId");
      debugPrint("Oil Quality: $oilQuality");
      debugPrint("Remarks: $remarks");
      debugPrint("Status: completed");
      debugPrint("Payment: done");
      debugPrint("Image Path: ${imageFile?.path}");

      final request = http.MultipartRequest("POST", url)
        ..headers["Authorization"] = "Bearer $token"
        ..headers["Accept"] = "application/json"
        ..fields["oil_quality"] = oilQuality!
        ..fields["status"] = "completed"
        ..fields["vendor_status"] = "accepted"
        ..fields["payment"] = "done"
        ..fields["remarks"] = remarks;

      if (imageFile != null) {
        debugPrint("⛔ File exists: ${File(imageFile.path).existsSync()}");
        debugPrint("⛔ File length: ${await File(imageFile.path).length()} bytes");

        request.files.add(
          await http.MultipartFile.fromPath('oil_image', imageFile.path),
        );
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
    } finally {
      setState(() => isLoading = false); // 👈 Hide loader after completion
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Use 3 if adding "Completed" tab
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF006D04),
          elevation: 0,
          title: const Text(
            "Order Assigned",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,color:  Colors.white,),
          ),
        ),
        body: Column(
          children: [
            Container(
              color: const Color(0xFF006D04), // Same color as AppBar
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: "Pending"),
                  Tab(text: "Approved"),
                  // Tab(text: "Completed"),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrderList(pendingOrders, isPending: true),
                  _buildOrderList(approvedOrders, isPending: false),
                  // _buildOrderList(completedOrders, isPending: false, isCompleted: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  /// ✅ Build Order List (for Pending and Approved tabs)
  Widget _buildOrderList(List<dynamic> orders,
      {required bool isPending,
        // bool isCompleted = false
      }) {
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
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    return _buildMessageCard(orders[index],
                        isPending: isPending);
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
  Widget _buildMessageCard(
      Map<String, dynamic> order, {
        required bool isPending,
        // bool isCompleted = false,
      }) {
    final int orderId = order["order_id"];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.grey[900]!, Colors.grey[850]!]
              : [const Color(0xFFF8F9FA), const Color(0xFFE9ECEF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Order #$orderId",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Divider(thickness: 1.2, color: isDark ? Colors.white24 : Colors.black26),
          const SizedBox(height: 12),
          _buildDetailColumn([
            _buildDetailRow("Oil Type", order["type"]),
            _buildDetailRow("Quantity", "${order["quantity"]} KG"),
            _buildDetailRow("Customer", order["user_name"]),
            _buildDetailRow("Phone", order["user_contact"], isPhoneNumber: true),
            _buildDetailRow("Address", order["registered_address"]),
            _buildDetailRow("Date", order["date"]),
            _buildDetailRow("Time", order["time"]),
            _buildDetailRow("Pickup Location", order["pickup_location"], isAddress: true),
            _buildDetailRow("Pickup Date", order["timeline"]),
            _buildDetailRow("Per Kg Price", order["agreed_price"]),
            _buildDetailRow("Total Price", order["amount"]),
          ]),
          const SizedBox(height: 16),

          if (isPending) _buildActionButtons(orderId,order),

          if (!isPending) ...[
            Text("Oil Quality",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black,
                )),
            const SizedBox(height: 8),
            ...["Excellent", "Good", "Poor"].map((quality) {
              return RadioListTile<String>(
                title: Text(quality, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                value: quality,
                groupValue: selectedOilQuality[orderId],
                onChanged: (value) => setState(() => selectedOilQuality[orderId] = value),
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => setState(() => selectedRemarks[orderId] = value),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: "Remarks (Optional)",
                labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: isPaymentDone[orderId] ?? false,
                  onChanged: (value) => setState(() => isPaymentDone[orderId] = value ?? false),
                ),
                Text("Payment Done", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              ],
            ),
            const SizedBox(height: 14),
            _buildCaptureSection(orderId),
            const SizedBox(height: 18),
            Center(
              child: ElevatedButton(
                onPressed: () => _submitOrder(orderId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006D04),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Submit", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildDetailColumn(List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children
          .map((widget) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: widget,
      ))
          .toList(),
    );
  }


  Widget _buildActionButtons(int orderId, Map<String, dynamic> order) {
    final pickupDate = order["timeline"]; // 🟡 Adjust if nested

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isAccepting[orderId] == true
                ? null
                : () async {
              // ✅ Show confirmation dialog before accepting
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Confirm Accept"),
                  content: Text(
                    "Are you sure you want to accept this order?\n\nPickup Date: ${pickupDate ?? "N/A"}",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Accept"),
                    ),
                  ],
                ),
              );

              if (confirmed != true) return; // Cancelled

              setState(() {
                isAccepting[orderId] = true;
              });

              await _acceptOrder(orderId);

              setState(() {
                isAccepting[orderId] = false;
              });
            },
            icon: isAccepting[orderId] == true
                ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Icon(Icons.check_circle_outline, color: Colors.white),
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
            icon: const Icon(Icons.cancel_outlined, color: Colors.white),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            label: const Text("Decline", style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }


  Widget _buildCaptureSection(int orderId) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () => _captureImage(orderId),
          icon: const Icon(Icons.camera_alt_outlined,color: Colors.white),
          label: const Text("Capture",style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF006D04),
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
    );
  }


  /// ✅ Image Picker for camera
  Future<void> _captureImage(int orderId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      final File originalFile = File(image.path);

      debugPrint("📸 Original image size: ${(await originalFile.length()) / (1024 * 1024)} MB");

      final File compressedFile = await _compressImage(originalFile);

      debugPrint("📉 Compressed image size: ${(await compressedFile.length()) / (1024 * 1024)} MB");
      debugPrint("📂 Compressed path: ${compressedFile.path}");

      // ✅ Assign compressed image to the map
      setState(() {
        capturedImages[orderId] = compressedFile;
      });
    } else {
      debugPrint("No image captured.");
    }
  }



  Future<File> _compressImage(File file) async {
    final imageBytes = await file.readAsBytes();
    final decodedImage = img.decodeImage(imageBytes);

    if (decodedImage == null) {
      throw Exception("Image decoding failed.");
    }

    final resized = img.copyResize(decodedImage, width: 800); // Resize for compression

    int quality = 70;
    List<int> compressedBytes = img.encodeJpg(resized, quality: quality);

    while (compressedBytes.length > 2 * 1024 * 1024 && quality > 30) {
      quality -= 10;
      compressedBytes = img.encodeJpg(resized, quality: quality);
    }

    final dir = await getTemporaryDirectory();
    final newPath = "${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg";

    final compressedFile = File(newPath)..writeAsBytesSync(compressedBytes);
    return compressedFile;
  }



  Widget _buildDetailRow(
      String title,
      String? value, {
        bool isPhoneNumber = false,
        bool isAddress = false,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black,
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: isAddress
                  ? () async {
                final String query = Uri.encodeComponent(value!);
                Uri mapUri;

                if (Platform.isAndroid) {
                  mapUri = Uri.parse("geo:0,0?q=$query");
                } else if (Platform.isIOS) {
                  mapUri = Uri.parse("comgooglemaps://?q=$query");
                  if (!await canLaunchUrl(mapUri)) {
                    mapUri = Uri.parse("https://www.google.com/maps/search/?q=$query");
                  }
                } else {
                  mapUri = Uri.parse("https://www.google.com/maps/search/?q=$query");
                }

                if (await canLaunchUrl(mapUri)) {
                  await launchUrl(mapUri, mode: LaunchMode.externalApplication);
                } else {
                  debugPrint("❌ Unable to launch Google Maps.");
                }
              }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  value ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.2,
                    color: isAddress
                        ? (isDark ? Colors.lightBlue[200] : Colors.blue)
                        : (isDark ? Colors.white : Colors.black),
                    decoration: isAddress ? TextDecoration.underline : TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
          if (isPhoneNumber)
            IconButton(
              icon: Image.asset(
                "assets/image/call.png",
                width: 30,
                height: 30,
              ),
              padding: const EdgeInsets.only(left: 4),
              constraints: const BoxConstraints(),
              onPressed: () async {
                String phoneNumber = value!.replaceAll(RegExp(r'\D'), '');
                if (!phoneNumber.startsWith("91")) {
                  phoneNumber = "91$phoneNumber";
                }

                final Uri whatsappUri = Uri.parse("whatsapp://send?phone=$phoneNumber");
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

}

import 'dart:convert';
import 'package:areg_app/common/app_colors.dart';
import 'package:areg_app/common/floating_chatbot_btn.dart';
import 'package:areg_app/config/api_config.dart';
import 'package:areg_app/core/storage/app_assets_constant.dart';
import 'package:areg_app/vendor_app/comman/vendor_appbar.dart';
import 'package:areg_app/vendor_app/vendor_screen/vendor_order_screen.dart';
import 'package:areg_app/views/screens/fbo_voucher.dart';
import 'package:areg_app/views/screens/widgets/k_svg.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Vendor_Acknowledge.dart';
import 'completed_order_screen.dart';
import 'order_reject.dart';

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  String totalBalance = "₹290,500";
  String percentageIncrease = "85%";
  List<Map<String, dynamic>> pendingOrders = [];
  List<Map<String, dynamic>> approvedOrders = [];
  bool _isLoading = true;
  String totalAmount = "0";
  String totalQuantity = "0";
  String currentDate = "";
  int todayCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchAssignedOrders();
    fetchVendorData();
  }
  String formatIndianCurrency(String amount) {
    double value = double.tryParse(amount) ?? 0;
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    return formatter.format(value);
  }

  Future<void> fetchVendorData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? agentId = prefs.getString('vendor_id');

      if (token == null || agentId == null) {
        print("🚨 Token or Agent ID is null.");
        return;
      }

      print("🔄 Fetching vendor data...");

      var response = await http.post(
        Uri.parse(ApiConfig.getCpHome),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "role": "vendor",
          "id": int.parse(agentId),
        }),
      );

      print("🔹 Response Status Code: ${response.statusCode}");
      print("🔹 Raw Response Body: ${response.body}");

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        if (data["status"] == "success") {
          setState(() {
            totalAmount = data["total_amount"] ?? "0";
            totalQuantity = data["total_quantity"] ?? "0";
            currentDate = data["current_date"] ?? "";
            todayCount = data["today_count"] ?? 0;
          });

          print("✅ Vendor data updated successfully!");
        } else {
          print("❌ API returned error: ${data["message"]}");
        }
      } else {
        print("❌ Failed to fetch data: ${response.body}");
      }
    } catch (e) {
      print("🚨 Error fetching data: $e");
    }
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
      setState(() => _isLoading = false);
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
            pendingOrders = (jsonData["pendingData"] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
                [];

            approvedOrders = (jsonData["approvedData"] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
                [];

            _isLoading = false;
          });

          debugPrint("✅ Loaded ${pendingOrders.length} pending orders");
          debugPrint("✅ Loaded ${approvedOrders.length} approved orders");
        } else {
          debugPrint("❌ API returned an unexpected format");
          setState(() => _isLoading = false);
        }
      } else {
        debugPrint(
            "❌ API request failed with status code: ${response.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("❌ Error fetching data: $e");
      setState(() => _isLoading = false);
    }
  }

  /// 🔄 Refresh the data
  Future<void> _refreshOrders() async {
    await _fetchAssignedOrders();
    await fetchVendorData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: VendorAppBar(title: 'Welcome'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrders,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                const Text(
                  'Get Start Your Journey !',
                  style: TextStyle(
                    color: AppColors.titleColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                // Card Section
                _buildVendorCardSection(
                  totalAmount: totalAmount,
                  totalQuantity: totalQuantity,
                  currentDate: currentDate,
                  todayCount: todayCount,
                ),
                const SizedBox(height: 24),
                Text("See Your Activity",
                    style: TextStyle(
                        color: AppColors.lightGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),

                // Action Buttons
                _buildActionButtons(context),
                const SizedBox(height: 24),

                // Promotional Section
                _buildPromoSection(context),
                const SizedBox(height: 32),

                // Recent Orders Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assigned Orders',
                          style: TextStyle(
                            color: AppColors.titleColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${pendingOrders.length} pending',
                          style: const TextStyle(
                            color: AppColors.titleColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _refreshOrders,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.refresh,
                          color: AppColors.primaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Recent Orders List
                if (_isLoading)
                  Container(
                    padding: const EdgeInsets.all(40),
                    child: const Column(
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.fboColor),
                        ),
                        KSvg(
                          svgPath: AppAssetsConstants.splashLogo,
                          height: 30,
                          width: 30,
                          boxFit: BoxFit.cover,
                        ),
                      ],
                    ),
                  )
                else if (pendingOrders.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: const [
                        Icon(Icons.inbox, color: AppColors.white24, size: 56),
                        SizedBox(height: 16),
                        Text(
                          'No assigned orders',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Orders will appear here when assigned',
                          style: TextStyle(
                            color: AppColors.white24,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pendingOrders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(pendingOrders[index]);
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      // Add the DraggableChatbotButton here using a Stack
      floatingActionButton: DraggableChatbotButton(),
    );
  }




  Widget _buildVendorCardSection({
    required String totalAmount,
    required String totalQuantity,
    required String currentDate,
    required int todayCount,
  }) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor,
            AppColors.secondaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Row with totals
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Total Amount & Total Quantity
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Total Amount', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    SizedBox(height: 4),
                    Text(formatIndianCurrency(totalAmount), style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 12),
                    Text('Total Quantity', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    SizedBox(height: 4),
                    Text(totalQuantity, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),

                Spacer(), // pushes Today Count to the right

                // Right: Today Count (bigger)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Today Count', style: TextStyle(color: Colors.white70, fontSize: 18)),
                    SizedBox(height: 4),
                    Text(
                      todayCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 45, // big font
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Bottom: Current Date
            Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Date: $currentDate',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

// ✅ Updated Action Buttons
  Widget _buildActionButton(
      BuildContext context,
      String label,
      IconData icon,
      Widget targetPage,
      ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryColor, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
          context,
          'Orders',
          Icons.shopping_cart_outlined,
          const VendorCartPage(),
        ),
        _buildActionButton(
          context,
          'Completed',
          Icons.check_circle_outline,
          const CompletedOrdersScreen(),
        ),
        _buildActionButton(
          context,
          'Rejected',
          Icons.cancel_outlined,
          const OrdersRejected(),
        ),
        _buildActionButton(
          context,
          'Get',
          Icons.receipt_long_outlined,
          const VendorAcknowledge(),
        ),
      ],
    );
  }


  Widget _buildPromoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor.withOpacity(0.1),
            AppColors.secondaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Take Control of Your Orders.',
                  style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Start managing your collections easily',
                  style: TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              // Navigate to VoucherHistoryScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VoucherHistoryScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Vouchers',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


// ✅ Updated Order Card
  Widget _buildOrderCard(Map<String, dynamic> order) {
    final String restaurantName = order['restaurant_name'] ?? 'Unknown';
    final String oilType = order['type'] ?? 'Oil';
    final String quantity = order['quantity'] ?? '0';
    final String amount = order['amount'] ?? '0';
    final String orderDate = order['date'] ?? 'N/A';
    final String orderId = order['order_id'].toString();

    return GestureDetector(
      onTap: () {
        _showOrderDetails(order);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Oil Type Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryColor.withOpacity(0.2),
                    AppColors.secondaryColor.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.oil_barrel,
                color: AppColors.primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),

            // Order Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurantName,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          oilType,
                          style: const TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Order $orderId',
                        style: const TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.water_drop,
                          color: AppColors.primaryColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$quantity KG',
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.calendar_today,
                          color: Color(0xFF757575), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        orderDate,
                        style: const TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Amount and Arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹$amount',
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: const Text(
                    'Assigned',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 📋 Show order details in a bottom sheet
  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.darkGreen,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border(
              top: BorderSide(
                color: AppColors.lightGreen.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Order Details',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.close,
                          color: AppColors.lightGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Restaurant Info
                  _buildDetailRow(
                      'Restaurant', order['restaurant_name'] ?? 'N/A'),
                  _buildDetailRow('Customer', order['user_name'] ?? 'N/A'),
                  _buildDetailRow('Contact', order['user_contact'] ?? 'N/A'),
                  const SizedBox(height: 16),
                  Divider(color: AppColors.lightGreen.withOpacity(0.2)),
                  const SizedBox(height: 16),

                  // Order Info
                  _buildDetailRow('Order ID', '#${order['order_id']}'),
                  _buildDetailRow('Oil Type', order['type'] ?? 'N/A'),
                  _buildDetailRow('Quantity', '${order['quantity']} KG'),
                  _buildDetailRow('Amount', '₹${order['amount']}'),
                  const SizedBox(height: 16),
                  Divider(color: AppColors.lightGreen.withOpacity(0.2)),
                  const SizedBox(height: 16),

                  // Pickup Info
                  const Text(
                    'Pickup Location',
                    style: TextStyle(
                      color: AppColors.lightGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    order['pickup_location'] ?? 'N/A',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const VendorCartPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Get Your Orders',
                        style: TextStyle(
                          color: AppColors.darkestGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.lightGreen,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
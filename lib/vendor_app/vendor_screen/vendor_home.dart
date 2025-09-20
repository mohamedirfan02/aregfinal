import 'dart:convert';
import 'package:areg_app/common/app_colors.dart';
import 'package:areg_app/common/floating_chatbot_btn.dart';
import 'package:areg_app/vendor_app/vendor_screen/vendor_order_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../agent/agent_screen/history.dart';
import '../../agent/common/agent_action_button.dart';
import '../../config/api_config.dart';
import '../../views/screens/fbo_voucher.dart';
import '../comman/vendor_appbar.dart';
import 'Vendor_Acknowledge.dart';
import 'completed_order_screen.dart';
import 'order_reject.dart';

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  String oilCollection = "0 KG";
  String todaycount = "0";
  String currentDate = "";

  @override
  void initState() {
    super.initState();
    fetchVendorData();
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

        setState(() {
          todaycount = "${data["today_count"] ?? 0}";
          oilCollection = "${data["total_quantity"] ?? 0} KG";
          currentDate = data["current_date"] ?? "";
        });

        print(
            "✅ Updated: $todaycount orders, $oilCollection oil, $currentDate");
      } else {
        print("❌ Failed to fetch data: ${response.body}");
      }
    } catch (e) {
      print("🚨 Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Define dynamic colors for light/dark
    final backgroundColor =
        isDark ? theme.scaffoldBackgroundColor : Colors.white;
    final primaryGreen = isDark ? Color(0xFF4CAF50) : AppColors.secondaryColor;
    final secondaryGreen = isDark ? Color(0xFF81C784) : AppColors.secondaryColor;
    final textColorLight = isDark ? Colors.white70 : Colors.white70;
    final textColorWhite = isDark ? Colors.white : Colors.white;
    final textColorDark = isDark ? Colors.white70 : Colors.black87;
    final containerBgColor = isDark ? theme.cardColor : Colors.white;
    final containerBorderColor =
        isDark ? Colors.white12 : Colors.black.withOpacity(0.1);
    final shadowColor = isDark ? Colors.black45 : Colors.black12;

    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: VendorAppBar(title: 'Welcome'),
        ),
        body: Stack(
          children: [
            Positioned(
              top: -2,
              left: -2,
              right: -2,
              child: Container(
                height: screenHeight * 0.35,
                width: screenWidth,
                decoration: BoxDecoration(
                  color: primaryGreen,
                  image: const DecorationImage(
                    image: AssetImage('assets/image/agent_home.png'),
                    fit: BoxFit.contain,
                  ),
                  border: Border.all(
                    width: 1.28,
                    color: theme.dividerColor.withOpacity(0.2),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            "Total Oil Collected",
                            style: TextStyle(
                              color: textColorLight,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            oilCollection,
                            style: TextStyle(
                              color: textColorWhite,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const HistoryScreen()),
                              );
                            },
                            label: const Text(
                              'History',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                                side: const BorderSide(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.arrow_outward,
                                size: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 60,),
                    Container(
                      margin: const EdgeInsets.only(
                          top: 20, left: 16, right: 16, bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: containerBgColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: 6,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            currentDate.isNotEmpty
                                ? "Today $currentDate"
                                : "Loading date...",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: textColorDark,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.9, // Responsive width
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        "Today Collection",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.secondaryColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondaryColor,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withAlpha((0.2 * 255).toInt()),
                                            blurRadius: 3,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        "$todaycount Restaurant",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),


                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 20),
                      child: Row(
                        children: [
                          Expanded(
                              child:
                                  Divider(color: secondaryGreen, thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              "Service Request",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: primaryGreen,
                              ),
                            ),
                          ),
                          Expanded(
                              child:
                                  Divider(color: secondaryGreen, thickness: 1)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: containerBgColor,
                          border:
                              Border.all(color: containerBorderColor, width: 1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _serviceBtn(
                                  context,
                                  title: "Orders",
                                  imagePath: "assets/icon/lg1.png",
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const VendorCartPage()),
                                  ),
                                ),
                                _divider(),
                                _serviceBtn(
                                  context,
                                  title: "Completed",
                                  imagePath: "assets/icon/lg2.png",
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const CompletedOrdersScreen()),
                                  ),
                                ),
                                _divider(),
                                _serviceBtn(
                                  context,
                                  title: "Rejected",
                                  imagePath: "assets/icon/lg3.png",
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const OrdersRejected()),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Spacer(flex: 1),
                                _serviceBtn(
                                  context,
                                  title: "Acknowledge",
                                  imagePath: "assets/icon/lg4.png",
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const VendorAcknowledge()),
                                  ),
                                ),
                                _divider(),
                                _serviceBtn(
                                  context,
                                  title: "Voucher",
                                  imagePath: "assets/icon/lg5.png",
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const VoucherHistoryScreen()),
                                  ),
                                ),
                                const Spacer(flex: 1),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const DraggableChatbotButton(),
          ],
        ));
  }

  Widget _serviceBtn(
    BuildContext ctx, {
    required String title,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 90,
      height: 90,
      child: ActionButton(title: title, imagePath: imagePath, onTap: onTap),
    );
  }

  Widget _divider() => Container(
        height: 60,
        width: 1,
        color:AppColors.secondaryColor.withOpacity(0.5),
      );
}

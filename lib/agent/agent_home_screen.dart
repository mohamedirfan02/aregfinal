import 'package:areg_app/common/app_colors.dart';
import 'package:areg_app/common/floating_chatbot_btn.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/api_config.dart';
import '../views/screens/fbo_voucher.dart';
import 'agent_screen/AcknowledgmentScreen.dart';
import 'agent_screen/Fbo_DocumentScreen.dart';
import 'agent_screen/agent_login_request.dart';
import 'agent_screen/asign_agent.dart';
import 'agent_screen/fbo_rejected_list.dart';
import 'agent_screen/fbo_request.dart';
import 'agent_screen/history.dart';
import 'agent_screen/total_restaurant.dart';
import 'agent_screen/total_vendor.dart';
import 'common/agent_action_button.dart';
import 'common/agent_appbar.dart';

class AgentHomeScreen extends StatefulWidget {
  final String token;

  const AgentHomeScreen({super.key, required this.token});

  @override
  _AgentHomeScreenState createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen> {
  String totalAmount = "0.00 ₹";
  String oilCollection = "0 KG";

  @override
  void initState() {
    super.initState();
    fetchAgentData();
  }

  Future<void> fetchAgentData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? agentId = prefs.getString('agent_id');

      var response = await http.post(
        Uri.parse(ApiConfig.getCpHome),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "role": "agent",
          "id": int.parse(agentId!),
        }),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          totalAmount = "${data["total_amount"] ?? "0.00"} ₹";
          oilCollection = "${data["total_quantity"] ?? "0"} KG";
        });
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AgentAppBar(title: 'Welcome to Collection Point'),
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
                color: AppColors.secondaryColor,
                image: const DecorationImage(
                  image: AssetImage('assets/image/agent_bg1.png'),
                  fit: BoxFit.cover,
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
                            color: Colors.white70,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          oilCollection,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const HistoryScreen()),
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
                            backgroundColor: AppColors.secondaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                              side: const BorderSide(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.arrow_outward, size: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 70),
                  _buildStatusButtons(context, isDark),
                  const SizedBox(height: 20),
                  _buildServiceTitle(isDark),
                  const SizedBox(height: 12),
                  _buildServiceGrid(context, screenWidth),
                ],
              ),
            ),
          ),
          const DraggableChatbotButton(),
        ],
      ),
    );
  }

  Widget _buildStatusButtons(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 11),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!isDark)
              const BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatusButton("FBO", "assets/icon/mg1.png", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantList()));
            }),
            Container(
              height: 50,
              width: 1,
              color: AppColors.secondaryColor.withOpacity(0.5),
            ),
            _buildStatusButton("Rejected", "assets/icon/mg2.png", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => FboRejectedList()));
            }),
            Container(
              height: 50,
              width: 1,
              color: AppColors.secondaryColor.withOpacity(0.5),
            ),
            _buildStatusButton("Agent", "assets/icon/mg3.png", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => VendorList()));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(String title, String imagePath, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : AppColors.secondaryColor,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              imagePath,
              width: 32,
              height: 32,
              color: isDark ? Colors.white : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 :AppColors.secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTitle(bool isDark) {
    return Row(
      children: [
        const Expanded(
          child: Divider(thickness: 1, endIndent: 15, color: AppColors.secondaryColor),
        ),
        Text(
          "Service Request",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 :AppColors.secondaryColor,
          ),
        ),
        const Expanded(
          child: Divider(thickness: 1, indent: 15, color:AppColors.secondaryColor),
        ),
      ],
    );
  }

  Widget _buildServiceGrid(BuildContext context, double screenWidth) {
    final size = screenWidth * 0.24;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade900
              : Colors.white,
          border: Border.all(color: Colors.black.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            _serviceBtn("Acknowledge", "assets/icon/lg1.png", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentAcknowledgmentScreen()));
            }, size),
            _serviceBtn("Approval", "assets/icon/lg2.png", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FboLoginRequest()));
            }, size),
            _serviceBtn("Voucher", "assets/icon/lg3.png", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const VoucherHistoryScreen()));
            }, size),
            _serviceBtn("Documents", "assets/icon/lg4.png", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FboDocumentScreen()));
            }, size),
            _serviceBtn("Order Assign", "assets/icon/lg5.png", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignAgent()));
            }, size),
            _serviceBtn("Agent pending", "assets/icon/lg5.png", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentLoginRequest()));
            }, size),
          ],
        ),
      ),
    );
  }

  Widget _serviceBtn(String title, String imagePath, VoidCallback onTap, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: ActionButton(
        title: title,
        imagePath: imagePath,
        onTap: onTap,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../views/screens/fbo_voucher.dart';
import 'agent_screen/AcknowledgmentScreen.dart';
import 'agent_screen/Fbo_DocumentScreen.dart';
import 'agent_screen/asign_agent.dart';
import 'agent_screen/fbo_request.dart';
import 'agent_screen/history.dart';
import 'agent_screen/total_restaurant.dart';
import 'agent_screen/total_vendor.dart';
import 'common/agent_action_button.dart';
import 'common/agent_appbar.dart';

class AgentHomeScreen extends StatefulWidget {
  final String token; // Pass the token here

  const AgentHomeScreen({super.key, required this.token});

  @override
  _AgentHomeScreenState createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen> {
  String totalAmount = "0.00 ₹";
  String oilCollection = "0 KG";
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchAgentData(); // Fetch data when returning to this screen
  }

  @override
  void initState() {
    super.initState();
    fetchAgentData(); // Fetch data on screen load
  }

  Future<void> fetchAgentData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      print("🔄 Fetching agent data...");

      var response = await http.get(
        Uri.parse("https://9d5e-103-186-120-91.ngrok-free.app/api/get-cp-home"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("🔹 Response Status Code: ${response.statusCode}");
      print("🔹 Raw Response Body: ${response.body}");

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        setState(() {
          totalAmount = "${data["total_amount"] ?? "0.00"} ₹";
          oilCollection = "${data["total_quantity"] ?? "0"} KG";
        });

        print("✅ Updated Values -> Total Amount: $totalAmount, Oil Collection: $oilCollection");
      } else {
        print("❌ Failed to fetch data: ${response.body}");
      }
    } catch (e) {
      print("🚨 Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AgentAppBar(title: 'Allen Walker'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ✅ Banner UI at the Top
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: screenWidth,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFDDEDC5),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Total Amount",
                                style: TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                              Text(
                                totalAmount, // ✅ Dynamically updated
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "Oil Collection",
                                style: TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                              Text(
                                oilCollection, // ✅ Dynamically updated
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: Colors.black26, thickness: 0.5),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildBannerButton("Restaurant", () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => RestaurantList()));
                          }),
                          _buildBannerButton("Vendor", () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => VendorList()));
                          }),
                        ],

                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ✅ Action Buttons in Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  childAspectRatio: 1.8,
                  children: [
                    ActionButton(
                      title: "Acknowledgment",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AgentAcknowledgmentScreen()),
                        );
                      },
                    ),
                    ActionButton(
                      title: "Pending Approval",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const FboLoginRequest()),
                        );
                      },
                    ),
                    ActionButton(
                      title: "Voucher",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const VoucherHistoryScreen()),
                        );
                      },
                    ),
                    ActionButton(
                      title: "FBO Document",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const FboDocumentScreen()),
                        );
                      },
                    ),
                    ActionButton(
                      title: "History",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HistoryScreen()),
                        );
                      },
                    ),
                    ActionButton(
                      title: "Orders Assign to Agent",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AssignAgent()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerButton(String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.shade700, width: 1),
        ),
        child: Text(
          title,
          style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

}

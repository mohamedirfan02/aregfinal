import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/custom_ImageSlider.dart';
import '../../common/custom_appbar.dart';
import '../../common/custom_circular_indicator.dart';
import 'package:shimmer/shimmer.dart' as shimmer;
import '../../fbo_services/oil_sale_service.dart';
import '../dashboard/FBOAcknowledgmentScreen.dart';
import 'fbo_voucher.dart';
import 'monthly_view_screen.dart';
import 'oil_place_screen.dart';
import 'order_tracking_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 1; // Home is active
  String? userId;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadUserId(); // Load user ID first
  }

  // ✅ Load User ID from SharedPreferences
  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedUserId = prefs.getString('userId');

    if (storedUserId != null) {
      print("✅ Loaded User ID from SharedPreferences: $storedUserId");
      setState(() {
        userId = storedUserId;
      });
      _fetchUserData();
    } else {
      print("❌ No user ID found in SharedPreferences.");
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  void _fetchUserData() async {
    final data = await OilSaleService.fetchOilSaleData();
    if (data != null) {
      setState(() {
        userData = data;
        isLoading = false;
      });
    } else {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Scrollbar(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: screenHeight * 0.05),
                child: Stack(
                  children: [
                    Positioned(
                      top: -2,
                      left: -2,
                      child: Container(
                        width: 418.0,
                        height: 177.0,
                        decoration: BoxDecoration(
                          color: const Color(0xFF006D04),
                          border: Border.all(
                            width: 1.28,
                            color: Colors.black.withOpacity(0.1),
                          ),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        if (isLoading)
                          _buildShimmerList()
                        else if (hasError)
                          const Text("❌ Failed to load data", style: TextStyle(color: Colors.red))
                        else
                          buildUserData(screenWidth),
                        SizedBox(height: 10,),
                        MyWidget(),
                        _buildMonthlyDropdown(screenWidth, context),
                        SizedBox(height: 10,),
                        buildWeeklyProgress(screenWidth, userData?["weekly"] ?? []),
                        _buildReuseOilPickup(screenWidth),
                      ],
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

  Widget _buildShimmerList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Shimmer for Total Revenue Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _shimmerBox(height: 32, width: 120), // Fake Revenue
              _shimmerBox(height: 60, width: 60), // Fake Circular Indicator
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ✅ Shimmer for Online & Cash Payment Progress Bars
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _shimmerBox(height: 20, width: 100)), // Fake Online Payment
              const SizedBox(width: 10),
              Expanded(child: _shimmerBox(height: 20, width: 100)), // Fake Cash Payment
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ✅ Shimmer for Weekly Progress Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                4,
                    (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: _shimmerBox(height: 100, width: 80), // Fake Week Card
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ✅ Shimmer for Oil Pickup Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _shimmerBox(height: 50, width: double.infinity),
        ),
      ],
    );
  }
  /// ✅ Shimmer Box Helper Function
  Widget _shimmerBox({double height = 20, double width = double.infinity}) {
    return shimmer.Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget buildUserData(double screenWidth) {
    if (userData == null) {
      return const Text("❌ No Data Found", style: TextStyle(color: Colors.red));
    }

    final totalRevenue = userData?["total"]?["revenue"] ?? 0;
    final totalQuantity = userData?["total"]?["quantity"] ?? 0;
    final onlinePayment = userData?["total_online_payment"] ?? 0;
    final cashPayment = userData?["total_cash_payment"] ?? 0;

    return Column(
      children: [
        // 💚 Green Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6FA006), Color(0xFF6FA006)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text(
                'Year 2025',
                style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold, fontSize: 22),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Total Amount', style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '₹ $totalRevenue',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                          ),
                          const SizedBox(width: 4),
                          Lottie.asset(
                            'assets/animations/money.json',
                            width: 30,
                            height: 30,
                            repeat: true,
                            fit: BoxFit.cover,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Total Oil KG', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Lottie.asset(
                            'assets/animations/fuel.json',
                            width: 30,
                            height: 30,
                            repeat: true,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$totalQuantity Kg',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/animations/hand.json',
                    width: 50,
                    height: 50,
                    repeat: true,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: totalQuantity / 1000,
                      backgroundColor: Colors.white30,
                      color: Colors.white,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Lottie.asset(
                    'assets/animations/hand.json',
                    width: 50,
                    height: 50,
                    repeat: true,
                    fit: BoxFit.cover,
                  ),
                ],
              ),


            ],
          ),
        ),

        // 💵 Online & Cash Amount
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Color(0xFF6FA006),),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text("Online Transfer", style: TextStyle(fontSize: 14,fontWeight: FontWeight.bold,)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center, // 💥 Center align
                        children: [
                          Text(
                            "$onlinePayment",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                          const SizedBox(width: 4),
                          Lottie.asset(
                            'assets/animations/money.json',
                            width: 30,
                            height: 30,
                            repeat: true,
                            fit: BoxFit.cover,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Color(0xFF6FA006),),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text("Cash Amount", style: TextStyle(fontSize: 14,fontWeight: FontWeight.bold,)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center, // 💥 Center align
                        children: [
                          Text(
                            "$cashPayment",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                          const SizedBox(width: 4),
                          Lottie.asset(
                            'assets/animations/money.json',
                            width: 30,
                            height: 30,
                            repeat: true,
                            fit: BoxFit.cover,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }



// ✅ Show weekly progress dynamically, ensuring 4 weeks are displayed
  Widget buildWeeklyProgress(double screenWidth, List weeklyData) {
    List<Map<String, dynamic>> defaultWeeks = [
      {"week": 1, "quantity": 0, "revenue": 0},
      {"week": 2, "quantity": 0, "revenue": 0},
      {"week": 3, "quantity": 0, "revenue": 0},
      {"week": 4, "quantity": 0, "revenue": 0},
    ];

    // Merge actual data with default weeks, ensuring all weeks exist
    for (var weekData in weeklyData) {
      int weekNumber = weekData["week"];
      if (weekNumber >= 1 && weekNumber <= 4) {
        defaultWeeks[weekNumber - 1] = weekData; // Replace default with actual data
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Row(
            children: defaultWeeks.map<Widget>((week) {
              return _buildWeekCard(
                "Week ${week["week"]}",
                week["quantity"] > 0 ?"${week["quantity"]}KG/${week["revenue"]}₹" : "No Data",
                week["quantity"] > 0 ? week["quantity"] / 100 : 0, // Show 0 progress for empty weeks
                screenWidth,
              );
            }).toList(),
          ),
        ),

        // ✅ Centered month display with <>
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Center(
            child: Text(
              "<${_getMonthName(DateTime.now().month)}>",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
        ),
      ],
    );
  }
// ✅ Helper function to get month name
  String _getMonthName(int month) {
    List<String> months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return months[month - 1];
  }



  Widget _buildProgressIndicator(String label, String amount, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(amount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 9),
        SizedBox(
          width: 140,
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey.shade300,
            color: const Color(0xFF86BC23),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
// Add this method to build Monthly Dropdown and Voucher Button side by side
  Widget _buildMonthlyDropdown(double screenWidth, BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ✅ Monthly Dropdown
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black26),
                color: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: 1, // Default to January
                  items: List.generate(12, (index) {
                    return DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text("${_getMonthName(index + 1)}", style: const TextStyle(fontSize: 16)),
                    );
                  }),
                  onChanged: (int? newMonth) {
                    if (newMonth != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MonthlyViewPage(month: newMonth),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 10), // Space between Dropdown and Voucher button

          // ✅ Voucher Button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VoucherHistoryScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 25),
              decoration: BoxDecoration(
                color: const Color(0xFF6FA006),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(3, 4),
                    blurRadius: 6,
                  ),
                  const BoxShadow(
                    color: Colors.white24,
                    offset: Offset(-2, -2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Text(
                "Voucher",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 2,
                      color: Colors.black38,
                    ),
                  ],
                ),
              ),
            ),
          )

        ],
      ),
    );
  }
  Widget _buildWeekCard(String week, String details, double progress, double screenWidth) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
      padding: EdgeInsets.all(screenWidth * 0.03),
      width: screenWidth * 0.25,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2),
        ],
      ),
      child: Column(
        children: [
          Text(week, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          Text(details, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade300,
            color: const Color(0xFF86BC23),
            minHeight: 6,
          ),
        ],
      ),
    );
  }
// ✅ Reuse oil pickup section with separate Voucher button
  Widget _buildReuseOilPickup(double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: 20),
      child: Container(
        padding: const EdgeInsets.all(7),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF86BC23),
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            children: [
              const Text(
                "Used Oil Pickup",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // ✅ Vertical Buttons
              _buildActionButton(
                title: "Acknowledge",
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => FboAcknowledgmentScreen()));
                },
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                title: "Order Status",
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen()));
                },
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                title: "Request Sale",
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => OilPlacedScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF5A8E14),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }


}
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  bool isLoading = true;
  bool hasError = false;
  List<Map<String, dynamic>> rangeDataList = []; // ✅ Declare list here

  @override
  void initState() {
    super.initState();
    fetchRangeData();
  }

  Future<void> fetchRangeData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      Map<String, String> headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      final response = await http.get(
        Uri.parse("https://enzopik.thikse.in/api/get-range"),
        headers: headers,
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['data'] != null && jsonData['data'].isNotEmpty) {
          setState(() {
            rangeDataList = List<Map<String, dynamic>>.from(jsonData['data']);
            isLoading = false;
          });

          print("🟢 Updated rangeDataList: $rangeDataList"); // Debugging
        } else {
          setState(() {
            hasError = true;
            isLoading = false;
          });
        }
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      print('Error: $e');
    }
  }


  Widget _buildRangeList() {
    print("🔹 UI Rebuilding with rangeDataList: $rangeDataList");

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (hasError || rangeDataList.isEmpty) {
      return const Center(
        child: Text("Failed to load price ranges", style: TextStyle(color: Colors.red)),
      );
    }

    return SizedBox(
      height: 70, // Reduced height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: rangeDataList.length,
        itemBuilder: (context, index) {
          final rangeData = rangeDataList[index];
          return Container(
            width: 220,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "From: ${rangeData['from']}Kg",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  "To: ${rangeData['to']}Kg",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  "₹${rangeData['price']}",
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return _buildRangeList();
  }
}
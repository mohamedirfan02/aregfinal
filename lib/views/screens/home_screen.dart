import 'dart:convert';
import 'dart:ui';
import 'package:areg_app/common/app_colors.dart';
import 'package:areg_app/common/floating_chatbot_btn.dart';
import 'package:areg_app/common/k_linear_gradient_bg.dart';
import 'package:areg_app/views/screens/widgets/RequirementStatsCard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/custom_appbar.dart';
import 'package:shimmer/shimmer.dart' as shimmer;
import '../../config/api_config.dart';
import '../../fbo_services/oil_sale_service.dart';

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

  String _selectedDataCategory = 'Total';
  dynamic _selectedData = {};

  Future<void> _onRefresh() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    await _fetchUserData(); // Re-fetch user data on pull-down
  }

  @override
  void initState() {
    super.initState();
    _loadUserId(); // Load user ID first
  }

  // ✅ Load User ID from SharedPreferences
  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedUserId = prefs.getString('userId');
    if (!mounted) return; // 👈 prevents setState if widget is disposed
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

  Future<void> _fetchUserData() async {
    final data = await OilSaleService.fetchOilSaleData();
    if (!mounted) return; // 👈 prevents setState if widget is disposed

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

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(),
      ),
      body: Stack(
        children: [
          KLinearGradientBg(
            gradientColor: AppColors.GradientColor,
            child: SafeArea(
              child: Column(
                // Change this from SingleChildScrollView to Column
                children: [
                  // Top content (not scrollable)
                  if (isLoading)
                    _buildShimmerList()
                  else if (hasError)
                    const Text(
                      "Too many attempts, please wait for 5 to 10 sec and switch tab",
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    )
                  else
                    buildUserData(context),

                  // Bottom container (scrollable content inside)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20.r),
                          topRight: Radius.circular(20.r),
                        ),
                        color: AppColors.white,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildMoneyEarnedSection(screenWidth, context),
                            const SizedBox(height: 10),
                            _buildReuseOilPickup(screenWidth, context),
                            _buildMonthlyDropdown(screenWidth, context),
                            const SizedBox(height: 10),
                            buildWeeklyProgress(
                                screenWidth, userData?["weekly"] ?? []),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
       DraggableChatbotButton(),

        ],
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
              Expanded(child: _shimmerBox(height: 20, width: 100)),
              // Fake Online Payment
              const SizedBox(width: 10),
              Expanded(child: _shimmerBox(height: 20, width: 100)),
              // Fake Cash Payment
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

  // Update your buildUserData method to only include the green card:

  // Add this state variable to your main class

  Widget buildUserData(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatter = NumberFormat('#,##0');

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (userData == null) {
      return const Text(
        "❌ Too many attempts, please wait 5–10 seconds and switch tab",
        style: TextStyle(color: Colors.red),
      );
    }

    // Reduced sizing factors
    double horizontalPadding = screenWidth * 0.03; // Reduced from 0.04
    double verticalPadding = screenHeight * 0.015; // Reduced from 0.02
    double fontSizeSubtitle = screenWidth * 0.035; // Reduced from 0.045
    double fontSizeAmount = screenWidth * 0.04; // Reduced from 0.05

    return Column(
      children: [

        // Card Container
        ClipRRect(
          borderRadius: BorderRadius.circular(screenWidth * 0.04), // Reduced from 0.05
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              margin: EdgeInsets.all(horizontalPadding * 0.8), // Reduced margin
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                    Colors.white.withOpacity(0.05),
                    Colors.white.withOpacity(0.15),
                  ]
                      : [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.3),
                  ],
                ),
                image: DecorationImage(
                  image: AssetImage('assets/image/fbo_bg.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.5),
                    BlendMode.dstATop,
                  ),
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.15),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(-5, -5),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: -5,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Left Column
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white.withOpacity(0.3),
                      borderRadius:
                      BorderRadius.circular(screenWidth * 0.025), // Reduced from 0.03
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getDisplayTitle(),
                            style: TextStyle(
                              color: isDark ? Colors.white :AppColors.darkestGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: fontSizeSubtitle,
                            ),
                          ),
                          SizedBox(height: verticalPadding),
                          // Amount Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getAmountLabel(),
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: fontSizeSubtitle,
                                ),
                              ),
                              SizedBox(height: verticalPadding / 2),
                              Row(
                                children: [
                                  Text(
                                    '₹ ${formatter.format(_getDisplayAmount())}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: fontSizeAmount,
                                    ),
                                  ),
                                  SizedBox(width: horizontalPadding / 2),
                                  Lottie.asset(
                                    'assets/animations/money.json',
                                    width: screenWidth * 0.055, // Reduced from 0.07
                                    height: screenWidth * 0.055,
                                    repeat: true,
                                    fit: BoxFit.cover,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: verticalPadding),
                          // Quantity Section
                          if (_getDisplayQuantity() != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getQuantityLabel(),
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: fontSizeSubtitle,
                                  ),
                                ),
                                SizedBox(height: verticalPadding / 2),
                                Row(
                                  children: [
                                    Text(
                                      '${formatter.format(_getDisplayQuantity())} Kg',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: fontSizeAmount,
                                      ),
                                    ),
                                    SizedBox(width: horizontalPadding / 2),
                                    Lottie.asset(
                                      'assets/animations/fuelnew.json',
                                      width: screenWidth * 0.055, // Reduced from 0.07
                                      height: screenWidth * 0.055,
                                      repeat: true,
                                      fit: BoxFit.cover,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: horizontalPadding),

                  // Right Column - Pie Chart
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        InteractiveWheelPieChart(
                          userData: userData!,
                          onCategorySelected: (category, data) {
                            setState(() {
                              _selectedDataCategory = category;
                              _selectedData = data;
                            });
                          },
                        ),
                        // Legend
                        Container(
                          padding: EdgeInsets.all(horizontalPadding / 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.white.withOpacity(0.3),
                            borderRadius:
                            BorderRadius.circular(screenWidth * 0.025), // Reduced from 0.03
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Rotate to Explore',
                                style: TextStyle(
                                  color:
                                  isDark ? Colors.white70 : Colors.black87,
                                  fontSize: fontSizeSubtitle * 0.6,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: verticalPadding / 4),
                              Text(
                                _selectedDataCategory,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontSize: fontSizeSubtitle * 0.7,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

// Helper methods for dynamic display
  String _getDisplayTitle() {
    switch (_selectedDataCategory) {
      case 'Online Payment':
        return 'Online Payments';
      case 'Cash Payment':
        return 'Cash Payments';
      case 'Total Revenue':
        return 'Total Revenue';
      case 'Oil Quantity':
        return 'Oil Quantity';
      case 'Month 9':
        return 'September 2025';
      case 'Week 1':
        return 'Week 1';
      case 'Week 2':
        return 'Week 2';
      default:
        return 'Year 2025';
    }
  }

  String _getAmountLabel() {
    switch (_selectedDataCategory) {
      case 'Online Payment':
      case 'Cash Payment':
        return 'Payment Amount';
      case 'Oil Quantity':
        return 'Quantity Value';
      default:
        return 'Total Amount';
    }
  }

  int _getDisplayAmount() {
    if (_selectedData.isNotEmpty && _selectedData['amount'] != null) {
      return _selectedData['amount'];
    }
    if (_selectedData.isNotEmpty && _selectedData['revenue'] != null) {
      return _selectedData['revenue'];
    }
    if (_selectedDataCategory == 'Oil Quantity' &&
        _selectedData['quantity'] != null) {
      return _selectedData['quantity'] * 50; // Assuming 50 rupees per kg
    }
    return userData?["total"]?["revenue"] ?? 0;
  }

  String _getQuantityLabel() {
    switch (_selectedDataCategory) {
      case 'Online Payment':
      case 'Cash Payment':
        return 'Related Oil KG';
      case 'Oil Quantity':
        return 'Total Oil KG';
      default:
        return 'Total Oil KG';
    }
  }

  int? _getDisplayQuantity() {
    if (_selectedDataCategory == 'Oil Quantity') {
      return _selectedData['quantity'] ?? userData?["total"]?["quantity"] ?? 0;
    }
    if (_selectedDataCategory == 'Online Payment' ||
        _selectedDataCategory == 'Cash Payment') {
      return null; // Don't show quantity for payment categories
    }
    if (_selectedData.isNotEmpty && _selectedData['quantity'] != null) {
      return _selectedData['quantity'];
    }
    return userData?["total"]?["quantity"] ?? 0;
  }

// Create a new method for the money section that will go inside the white background:
  Widget _buildMoneyEarnedSection(double screenWidth, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatter = NumberFormat('#,##0');

    final onlinePayment = userData?["total_online_payment"] ?? 0;
    final cashPayment = userData?["total_cash_payment"] ?? 0;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: screenWidth * 0.05, bottom: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Money That You've Earned!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.titleColor,
              ),
            ),
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
                    color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                    border: Border.all(color: AppColors.secondaryColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Online Transfer",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : AppColors.titleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "₹ ${formatter.format(onlinePayment)}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.lightGreenAccent
                                  : AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Lottie.asset(
                            'assets/animations/online.json',
                            width: 40,
                            height: 40,
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
                    color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                    border: Border.all(color: AppColors.secondaryColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Cash Amount",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : AppColors.titleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "₹ ${formatter.format(cashPayment)}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.lightGreenAccent
                                  : AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Lottie.asset(
                            'assets/animations/money.json',
                            width: 40,
                            height: 40,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : AppColors.titleColor;
    final subTextColor = isDarkMode ? Colors.white70 : Colors.black;
    final cardBackground = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDarkMode ? Colors.white24 : Colors.black12;

    List<Map<String, dynamic>> defaultWeeks = [
      {"week": 1, "quantity": 0, "revenue": 0},
      {"week": 2, "quantity": 0, "revenue": 0},
      {"week": 3, "quantity": 0, "revenue": 0},
      {"week": 4, "quantity": 0, "revenue": 0},
    ];

    for (var weekData in weeklyData) {
      int weekNumber = weekData["week"];
      if (weekNumber >= 1 && weekNumber <= 4) {
        defaultWeeks[weekNumber - 1] = weekData;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 8),
          child: Text(
            "Weekly Oil Collection Summary",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Row(
            children: defaultWeeks.map<Widget>((week) {
              return _buildWeekCard(
                "Week ${week["week"]}",
                week["quantity"] > 0
                    ? "${week["quantity"]}KG / ${week["revenue"]}₹"
                    : "0 KG / 0 ₹",
                week["quantity"] > 0 ? week["quantity"] / 100 : 0,
                screenWidth,
                textColor,
                subTextColor,
                cardBackground,
                borderColor,
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Center(
            child: Text(
              "<  ${_getMonthName(DateTime.now().month)}  >",
              style: TextStyle(
                fontSize: 18,
                color: subTextColor,
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
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return months[month - 1];
  }

// Add this method to build Monthly Dropdown and Voucher Button side by side
  Widget _buildMonthlyDropdown(double screenWidth, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      child: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Select Month & View Vouchers",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : AppColors.titleColor,
                    // 🌓 Text color
                  ),
                ),
                Icon(Icons.event, color: AppColors.titleColor),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 🗓 Monthly Dropdown
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color:
                              isDarkMode ? Colors.white38 : AppColors.fboColor),
                      color: isDarkMode ? Colors.grey[900] : Colors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        dropdownColor:
                            isDarkMode ? Colors.grey[900] : Colors.white,
                        value: 1,
                        items: List.generate(12, (index) {
                          return DropdownMenuItem<int>(
                            value: index + 1,
                            child: Text(
                              _getMonthName(index + 1),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode
                                    ? Colors.white
                                    : AppColors.titleColor,
                              ),
                            ),
                          );
                        }),
                        onChanged: (int? newMonth) {
                          if (newMonth != null) {
                            GoRouter.of(context).push(
                              '/monthly-view',
                              extra: {'month': newMonth},
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 🎫 Voucher Button
                GestureDetector(
                  onTap: () {
                    context.push('/voucherPage'); // ✅ Go to voucher pa
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 25),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF6FA006)
                          : AppColors.fboColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode
                              ? Colors.black.withOpacity(0.6)
                              : Colors.black.withOpacity(0.3),
                          offset: const Offset(3, 4),
                          blurRadius: 6,
                        ),
                        BoxShadow(
                          color: isDarkMode ? Colors.white12 : Colors.white24,
                          offset: const Offset(-2, -2),
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekCard(
      String week,
      String details,
      double progress,
      double screenWidth,
      Color textColor,
      Color subTextColor,
      Color cardBackground,
      Color borderColor) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
      padding: EdgeInsets.all(screenWidth * 0.03),
      width: screenWidth * 0.25,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12, width: 1), // ✅ Border added
        // boxShadow removed
      ),
      child: Column(
        children: [
          Text(
            week,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w100,
              color: AppColors.primaryGreen,
            ),
          ),
          Text(
            details,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w100,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }

// ✅ Reuse oil pickup section with separate Voucher button
  Widget _buildReuseOilPickup(double screenWidth, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: 20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF558400) : AppColors.fboColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Manage Oil Pickup",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4), // spacing between title & subtitle
            Text(
              "Confirm request a sale of your Used oil",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    title: "Acknowledge",
                    context: context,
                    onTap: () {
                      context.push(
                          '/FboAcknowledgmentScreen'); // ✅ Go to voucher pa
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    title: "Request Sale",
                    context: context,
                    onTap: () {
                      context.push('/OilPlacedScreen'); // ✅ Go to voucher pa
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    bool _isPressed = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform: _isPressed
                ? (Matrix4.identity()..scale(0.97))
                : Matrix4.identity(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2E2E2E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black54 : Colors.black26,
                  offset: const Offset(2, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title text
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.lightGreenAccent.shade100
                          : AppColors.primaryGreen,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Arrow container
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black87 : Colors.black26,
                        offset: const Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: isDark
                        ? Colors.lightGreenAccent.shade100
                        : AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
  List<Map<String, dynamic>> rangeDataList = []; // Declare list here
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
        Uri.parse(ApiConfig.getRange),
        headers: headers,
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['data'] != null && jsonData['data'].isNotEmpty) {
          if (!mounted) return; // ✅ Check before setState
          setState(() {
            rangeDataList = List<Map<String, dynamic>>.from(jsonData['data']);
            isLoading = false;
          });

          print("🟢 Updated rangeDataList: $rangeDataList"); // Debugging
        } else {
          if (!mounted) return; // ✅ Check before setState
          setState(() {
            hasError = true;
            isLoading = false;
          });
        }
      } else {
        if (!mounted) return; // ✅ Check before setState
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return; // ✅ Check before setState
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
        child: Text("Failed to load price ranges",
            style: TextStyle(color: Colors.red)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            "Oil Amount Price List",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006D04),
            ),
          ),
        ),
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: rangeDataList.length,
            itemBuilder: (context, index) {
              final rangeData = rangeDataList[index];
              return Container(
                width: 220,
                margin: const EdgeInsets.only(right: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0x1A87BD23),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0x1A87BD23),
                  ),
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
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF006D04),
                      ),
                    ),
                    Text(
                      "To: ${rangeData['to']}Kg",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF006D04),
                      ),
                    ),
                    Text(
                      "₹${rangeData['price']}",
                      style: const TextStyle(
                        color: Color(0xFF006D04),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildRangeList();
  }
}

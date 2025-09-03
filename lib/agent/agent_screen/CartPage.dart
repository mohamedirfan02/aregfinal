import 'dart:io';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../common/shimmer_loader.dart';
import '../../config/api_config.dart';

class AgentCartPage extends StatefulWidget {
  const AgentCartPage({super.key});

  @override
  State<AgentCartPage> createState() => _AgentCartPageState();
}

class _AgentCartPageState extends State<AgentCartPage> {
  List<dynamic> pendingOrders = [];
  List<dynamic> confirmedOrders = [];
  Map<int, File?> capturedImages =
      {}; // Declare globally to store images per order
  Map<int, DateTime> rescheduleDates = {};
  bool isLoading = false;
  Map<int, int> selectedVendorIds = {}; // orderId -> vendorId
  Map<int, List<Map<String, dynamic>>> vendorsPerOrder = {};
  bool isSubmitting = false;
  bool isCompleting = false;

  TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  List<dynamic> _filterOrders(List<dynamic> orders) {
    if (searchQuery.isEmpty) return orders;

    return orders.where((order) {
      final orderId = order['order_id'].toString();
      final restaurant = (order['restaurant_name'] ?? "").toLowerCase();
      return orderId.contains(searchQuery) || restaurant.contains(searchQuery);
    }).toList();
  }


  final Map<int, bool> showCollectionOptions = {};
  final Map<int, String> selectedCollectionMethod = {};
  final Map<int, bool> onlinePaySelected = {};
  final Map<int, bool> cashPaySelected = {};
  final Map<int, TextEditingController> amountControllers = {};
  final Map<int, TextEditingController> vendorIdControllers = {};

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        _showError("❌ Location permissions are permanently denied.");
        return;
      }
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      _getCurrentLocation();
    }
  }

  void _showError(String message) {
    final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.red))),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(timeLimit: Duration(seconds: 10)),
      );
      print("📍 Location: ${position.latitude}, ${position.longitude}");
    } catch (e) {
      _showError("❌ Error getting location: $e");
    }
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
    final Uri uriPendingConfirmed = Uri.parse(ApiConfig.getOrderDetails);
    final Uri uriCompleted = Uri.parse(ApiConfig.getAllCompletedOrders);
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
    };
    try {
      final responsePending = await http.post(uriPendingConfirmed,
          headers: headers, body: jsonEncode(bodyPending));
      final responseConfirmed = await http.post(uriPendingConfirmed,
          headers: headers, body: jsonEncode(bodyConfirmed));
      final responseCompleted = await http.post(uriCompleted,
          headers: headers, body: jsonEncode(bodyCompleted));
      if (responsePending.statusCode == 200 &&
          responseConfirmed.statusCode == 200 &&
          responseCompleted.statusCode == 200) {
        final dataPending = jsonDecode(responsePending.body);
        final dataConfirmed = jsonDecode(responseConfirmed.body);
        final dataCompleted = jsonDecode(responseCompleted.body);
        setState(() {
          for (var order in dataPending['data']) {
            int orderId = order['order_id'];
            vendorsPerOrder[orderId] =
                List<Map<String, dynamic>>.from(order['available_vendors']);
          }
          pendingOrders = dataPending['data'] ?? []; // ✅ Add this
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

  Future<void> _fetchNearestOrders() async {
    setState(() => isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? agentId = prefs.getString('agent_id');
    if (token == null || agentId == null) {
      print("❌ Token or Agent ID missing.");
      setState(() => isLoading = false);
      return;
    }
    // Get current location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final double latitude = position.latitude;
    final double longitude = position.longitude;
    print("📍 Location: $latitude, $longitude");
    final response = await http.post(
      Uri.parse(ApiConfig.nearestOrders),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "role": "agent",
        "id": int.parse(agentId),
        "latitude": latitude.toStringAsFixed(6),
        "longitude": longitude.toStringAsFixed(6),
        "reschedule": "yes",
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        confirmedOrders = data['data'] ?? [];
        print("✅ Nearest Orders: $confirmedOrders");
      });
    } else {
      print("❌ Failed to fetch nearest orders");
      print("Response: ${response.body}");
    }

    setState(() => isLoading = false);
  }

  Future<void> updateOrderStatus(int orderId, String status,
      {String? reason, DateTime? rescheduleDate}) async {
    final String apiUrl = ApiConfig.updateOilSale(orderId);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? agentId = prefs.getString('agent_id');
    if (token == null || agentId == null) {
      print("❌ No token or agent_id found. User must log in again.");
      return;
    }

    Map<String, dynamic> requestBody = {
      "agent_id": agentId,
      "status": status,
    };
    if (reason != null) {
      requestBody["reason"] = reason;
    }
    if (rescheduleDate != null) {
      requestBody["timeline"] = rescheduleDate.toIso8601String(); // ✅ Add date
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
      requestBody["payment"] =
          paymentDone[orderId] == true ? "done" : "pending";
      requestBody["reason"] = remarksControllers[orderId]?.text ?? "";

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

  List<dynamic> completedOrders = [];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: isDark ? Colors.black : Colors.white,
          appBar: AppBar(
            backgroundColor: isDark ? Colors.grey[900] : Color(0xFF006D04),
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
            title: Text(
              "Collection Details",
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(100),
              child: Column(
                children: [
                  // 🔎 Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search by Order ID or Restaurant Name",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  // 📌 Tabs
                  TabBar(
                    labelColor: Colors.white,
                    unselectedLabelColor: isDark ? Colors.grey[400] : Colors.white38,
                    indicatorColor: Colors.white54,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: "Pending"),
                      Tab(text: "Completed"),
                      Tab(text: "Self Collection"),
                    ],
                  ),
                ],
              ),
            ),
          ),
          body: isLoading
              ? _buildShimmerList()
              : TabBarView(
            children: [
              _buildOrderList(
                _filterOrders(pendingOrders),
                isPending: true,
                key: const ValueKey("pending"),
              ),
              _buildOrderList(
                _filterOrders(completedOrders),
                isPending: false,
                isCompleted: true,
                key: const ValueKey("completed"),
              ),
              _buildOrderList(
                _filterOrders(confirmedOrders),
                isPending: false,
                key: ValueKey("accepted_${confirmedOrders.length}"),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildOrderList(List<dynamic> orders,
      {required bool isPending, bool isCompleted = false, Key? key}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (orders.isEmpty) {
      return Center(
        child: Text(
          isPending
              ? "No pending orders"
              : isCompleted
                  ? "No completed orders"
                  : "No accepted orders",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      );
    }

    // 👉 Accepted Tab: Flat list without grouping
    if (!isPending && !isCompleted) {
      return ListView(
        key: key,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () async {
                await _checkLocationPermission();
                await _fetchNearestOrders();
              },
              icon: const Icon(Icons.location_on, color: Colors.white),
              label: const Text("Nearest Pickup",
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF006D04),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          ...orders.map((order) {
            try {
              return _buildNotificationCard(order, isPending, isCompleted);
            } catch (e) {
              print("❌ Error rendering Accepted Order: $e");
              return const SizedBox();
            }
          }).toList(),
        ],
      );
    }

    // 👇 For Pending and Completed Tabs: Keep grouping
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    List<dynamic> todayOrders = [];
    List<dynamic> yesterdayOrders = [];
    List<dynamic> earlierOrders = [];

    for (var order in orders) {
      String? dateStr =
          order['payment_date'] ?? order['date'] ?? order['created_at'];
      if (dateStr == null) continue;

      dateStr =
          dateStr.contains('T') ? dateStr : dateStr.replaceFirst(' ', 'T');
      final orderDate = DateTime.tryParse(dateStr);
      if (orderDate == null) continue;

      if (_isSameDate(orderDate, today)) {
        todayOrders.add(order);
      } else if (_isSameDate(orderDate, yesterday)) {
        yesterdayOrders.add(order);
      } else {
        earlierOrders.add(order);
      }
    }

    return ListView(
      key: key,
      children: [
        if (todayOrders.isNotEmpty) ...[
          _buildSectionHeader("Today Orders", isDark),
          ...todayOrders.map((order) {
            try {
              return _buildNotificationCard(order, isPending, isCompleted);
            } catch (e) {
              print("❌ Error rendering Today Order: $e");
              return const SizedBox();
            }
          }),
        ],
        if (yesterdayOrders.isNotEmpty) ...[
          _buildSectionHeader("Yesterday Orders", isDark),
          ...yesterdayOrders.map((order) {
            try {
              return _buildNotificationCard(order, isPending, isCompleted);
            } catch (e) {
              print("❌ Error rendering Yesterday Order: $e");
              return const SizedBox();
            }
          }),
        ],
        if (earlierOrders.isNotEmpty) ...[
          _buildSectionHeader("Earlier Orders", isDark),
          ...earlierOrders.map((order) {
            try {
              return _buildNotificationCard(order, isPending, isCompleted);
            } catch (e) {
              print("❌ Error rendering Earlier Order: $e");
              return const SizedBox();
            }
          }),
        ],
      ],
    );
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildNotificationCard(
      dynamic order, bool isPending, bool isCompleted) {
    final int? orderId = order['order_id'] ?? order['id'];
    if (order == null || orderId == null) return const SizedBox();

    amountControllers.putIfAbsent(orderId, () => TextEditingController());
    vendorIdControllers.putIfAbsent(orderId, () => TextEditingController());

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String date = order['date'] ??
        order['payment_date']?.split(' ')?.first ??
        order['created_at']?.split('T')?.first ??
        'N/A';

    final String time = order['time'] ??
        order['payment_date']?.split(' ')?.last ??
        order['created_at']?.split('T')?.last?.split('.')?.first ??
        'N/A';

    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(2, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Order ID: $orderId",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[400] : Colors.black38,
                ),
              ),
              IconButton(
                icon: Image.asset(
                  "assets/image/call.png",
                  width: 30,
                  height: 30,
                ),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                onPressed: () async {
                  String phoneNumber = (order['user_contact'] ?? '').replaceAll(RegExp(r'\D'), '');
                  if (phoneNumber.isNotEmpty) {
                    if (!phoneNumber.startsWith("91")) {
                      phoneNumber = "91$phoneNumber";
                    }

                    final Uri whatsappUri = Uri.parse("whatsapp://send?phone=$phoneNumber");
                    if (await canLaunchUrl(whatsappUri)) {
                      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
                    } else {
                      debugPrint("❌ WhatsApp is not installed or cannot be launched.");
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Phone number not available")),
                    );
                  }
                },
              ),
            ],
          ),
          const Divider(),
          Text(
            order['restaurant_name'] ?? "Unknown",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          _buildDetailRow("Order ID", orderId.toString(), isDark: isDark),
          _buildDetailRow("Oil Type", order['type'] ?? "N/A", isDark: isDark),
          _buildDetailRow("Payment Method", order['payment_method'] ?? "N/A",
              isDark: isDark),
          _buildDetailRow("Oil Quantity", "${order['quantity'] ?? 0} KG",
              isDark: isDark),
          _buildDetailRow("Agreed price", "₹${order["agreed_price"] ?? "N/A"}",
              isDark: isDark),
          _buildDetailRow("Total Amount", "₹${order["amount"] ?? "N/A"}",
              isDark: isDark),
          _buildDetailRow("Status", order["status"] ?? "N/A", isDark: isDark),
          _buildDetailRow("Status", order["timeline"] ?? "N/A", isDark: isDark),
          _buildDetailRow("Date", date, isDark: isDark),
          _buildDetailRow("Time", time, isDark: isDark),
          _buildDetailRow("Address", order['registered_address'] ?? "N/A",
              isDark: isDark),
          _buildDetailRow(
            "Phone Number",
            order['user_contact'] ?? "N/A",
          ),
          _buildDetailRow("Pickup Location", order['pickup_location'] ?? "N/A",
              isAddress: true),
          const SizedBox(height: 10),
          if (isCompleted)
            const Text(
              "✅ Order Completed",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006D04),
              ),
            ),
          if (isPending)
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          showCollectionOptions[orderId] = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006D04),
                      ),
                      child: const Text("Accept",
                          style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      onPressed: () => _showDeclineDialog(orderId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text("Decline",
                          style: TextStyle(color: Colors.white)),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _showRescheduleDialog(order),
                          icon: const Icon(Icons.calendar_month,
                              color: Colors.deepPurple),
                          tooltip: "Schedule Order",
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Schedule",
                          style:
                              TextStyle(fontSize: 12, color: Colors.deepPurple),
                        ),
                      ],
                    ),
                  ],
                ),
                if (showCollectionOptions[orderId] ?? false)
                  _buildCollectionOptions(orderId),
              ],
            ),
          if (!isPending && !isCompleted) _buildAcceptedOptions(orderId),
        ],
      ),
    );
  }

  void _showRescheduleDialog(Map<String, dynamic> order) {
    DateTime selectedDate = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Schedule Order",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TableCalendar(
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: selectedDate,
                      selectedDayPredicate: (day) =>
                          isSameDay(day, selectedDate),
                      onDaySelected: (selected, focused) {
                        setState(() {
                          selectedDate = selected;
                        });
                      },
                      calendarStyle: CalendarStyle(
                        todayDecoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                        ),
                        defaultTextStyle: TextStyle(
                            color: isDark ? Colors.white : Colors.black),
                        weekendTextStyle: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        rescheduleDates[order['order_id']] = selectedDate;
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text("Confirm Schedule"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
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
        const Text("Oil Quality",
            style: TextStyle(fontWeight: FontWeight.bold)),
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
              activeColor: const Color(0xFF4CAF50),
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
          decoration: InputDecoration(
            labelText: "Enter Reason",
            labelStyle: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: const Icon(Icons.markunread_sharp, color: Colors.black),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black26, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => _captureImage(orderId),
              icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
              label:
                  const Text("Capture", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF006D04),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
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
          onPressed: isCompleting
              ? null
              : () async {
                  setState(() => isCompleting = true); // 🔄 Show spinner

                  await updateOrderStatus(orderId, "completed");

                  setState(() => isCompleting = false); // ✅ Done
                },
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006D04)),
          child: isCompleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text("Complete Order",
                  style: TextStyle(color: Colors.white)),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          activeColor: const Color(0xFF4CAF50),
          // green premium shade
          checkColor: Colors.white,
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
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text("Decline Order"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Please enter the reason for declining this order:"),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: "Reason",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    const Text("Cancel", style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (reasonController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Reason cannot be empty!")),
                          );
                          return;
                        }

                        setState(() => isSubmitting = true);

                        await updateOrderStatus(
                          orderId,
                          "declined",
                          reason: reasonController.text,
                        );

                        if (context.mounted)
                          Navigator.pop(context); // Close dialog
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006D04),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Submit",
                        style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCollectionOptions(int orderId) {
    return Column(
      children: [
        const SizedBox(height: 10),
        const Text("Choose Collection Method:",
            style: TextStyle(fontWeight: FontWeight.bold)),
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
                    ? Color(0xFF006D04)
                    : Colors.grey,
              ),
              child: const Text(
                "Self Collection",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => setState(() {
                selectedCollectionMethod[orderId] = "Agent";
                print("✅ Assigned to Agent for Order: $orderId");
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedCollectionMethod[orderId] == "Agent"
                    ? Color(0xFF006D04)
                    : Colors.grey,
              ),
              child: const Text(
                "Assign to Agent",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        _buildPaymentOptions(orderId, isPending: true),
      ],
    );
  }

  Widget _buildPaymentOptions(int orderId, {required bool isPending}) {
    amountControllers.putIfAbsent(orderId, () => TextEditingController());
    vendorIdControllers.putIfAbsent(orderId, () => TextEditingController());
    final List<Map<String, dynamic>> availableVendorsForOrder = vendorsPerOrder[orderId] ?? [];
    if ((vendorIdControllers[orderId]?.text.isEmpty ?? true) &&
        selectedCollectionMethod[orderId] == "Agent") {
      final defaultVendorId = selectedVendorIds[orderId] ??
          availableVendorsForOrder.first['id'];
      vendorIdControllers[orderId]?.text = defaultVendorId.toString();
    }
    return Column(
      children: [
        if (isPending) ...[
          const SizedBox(height: 10),
          // ✅ Payment Method Selection
          Row(
            children: [
              Theme(
                data: ThemeData(
                  unselectedWidgetColor: Colors.grey.shade400,
                ),
                child: Checkbox(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  activeColor: const Color(0xFF006D04),
                  // green premium shade
                  checkColor: Colors.white,
                  value: onlinePaySelected[orderId] ?? false,
                  onChanged: (value) => setState(() {
                    onlinePaySelected[orderId] = value!;
                    cashPaySelected[orderId] = !value;
                  }),
                ),
              ),
              const Text(
                "Online Pay",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF2E7D32), // text color to match premium theme
                ),
              ),
              const SizedBox(width: 16),
              Theme(
                data: ThemeData(
                  unselectedWidgetColor: Colors.grey.shade400,
                ),
                child: Checkbox(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  activeColor: const Color(0xFFF9A825),
                  // amber premium shade
                  checkColor: Colors.white,
                  value: cashPaySelected[orderId] ?? false,
                  onChanged: (value) => setState(() {
                    cashPaySelected[orderId] = value!;
                    onlinePaySelected[orderId] = !value;
                  }),
                ),
              ),
              const Text(
                "Cash Pay",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFFF57F17), // matching amber
                ),
              ),
            ],
          ),

          // ✅ Vendor ID Field (if assigned to vendor)
          if (selectedCollectionMethod[orderId] == "Agent")
            DropdownButtonFormField<int>(
              value: selectedVendorIds[orderId] ??
                  availableVendorsForOrder.first['id'], // ✅ Set default
              items:
                  availableVendorsForOrder.map<DropdownMenuItem<int>>((vendor) {
                return DropdownMenuItem<int>(
                  value: vendor['id'],
                  child: Text(vendor['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedVendorIds[orderId] = value!;
                  vendorIdControllers[orderId]?.text = value.toString();
                });
              },
              decoration: InputDecoration(
                labelText: "Select Agent",
                labelStyle: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(Icons.badge, color: Colors.black),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF006D04), width: 2),
                ),
              ),
            ),

          const SizedBox(height: 10),
          // ✅ Submit Button
          ElevatedButton(
            onPressed: isSubmitting
                ? null
                : () async {
              final method = selectedCollectionMethod[orderId];
              final scheduledDate = rescheduleDates[orderId];

              if (scheduledDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please schedule a date before submitting."),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // ✅ If "self", show a confirmation dialog first
              if (method == "self") {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Confirm Submission"),
                    content: Text(
                      "Are you sure you want to submit?\nScheduled date: ${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel",style: TextStyle(color: Colors.black),),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Confirm",style: TextStyle(color: Colors.green)),
                      ),
                    ],
                  ),
                );

                if (confirmed != true) return; // Cancelled
              }

              setState(() => isSubmitting = true);

              await updateOrderStatus(
                orderId,
                method == "self" ? "confirmed" : "assigned",
                rescheduleDate: scheduledDate,
              );

              setState(() => isSubmitting = false);
            },

            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006D04)),
            child: isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text("Submit", style: TextStyle(color: Colors.white)),
          ),
        ],
      ],
    );
  }
}

Widget _buildDetailRow(String title, String value,
    {bool isPhoneNumber = false, bool isAddress = false, bool isDark = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100, // Reduced width for compact layout
          child: Text(
            "$title:",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              height: 1.2,
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isAddress
                ? () async {
                    final String query = Uri.encodeComponent(value);
                    Uri mapUri;

                    if (Platform.isAndroid) {
                      mapUri = Uri.parse("geo:0,0?q=$query");
                    } else if (Platform.isIOS) {
                      mapUri = Uri.parse("comgooglemaps://?q=$query");
                      if (!await canLaunchUrl(mapUri)) {
                        mapUri = Uri.parse(
                            "https://www.google.com/maps/search/?q=$query");
                      }
                    } else {
                      mapUri = Uri.parse(
                          "https://www.google.com/maps/search/?q=$query");
                    }

                    if (await canLaunchUrl(mapUri)) {
                      await launchUrl(mapUri,
                          mode: LaunchMode.externalApplication);
                    } else {
                      debugPrint("❌ Unable to launch Google Maps.");
                    }
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.2,
                  color: isAddress ? Colors.blue : Colors.black,
                  decoration: isAddress
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
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

class _CalendarRescheduler extends StatefulWidget {
  final Map<String, dynamic> order;

  const _CalendarRescheduler({required this.order});

  @override
  State<_CalendarRescheduler> createState() => _CalendarReschedulerState();
}

class _CalendarReschedulerState extends State<_CalendarRescheduler> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Reschedule Order",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TableCalendar(
          firstDay: DateTime.now(),
          lastDay: DateTime.now().add(const Duration(days: 30)),
          focusedDay: _selectedDate,
          selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDate = selected;
            });
          },
          calendarStyle: const CalendarStyle(
            selectedDecoration:
                BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
            todayDecoration: BoxDecoration(
                color: Colors.orangeAccent, shape: BoxShape.circle),
            weekendTextStyle: TextStyle(color: Colors.red),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Call your backend API to update order['id'] with _selectedDate
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text("Order rescheduled to ${_selectedDate.toLocal()}")),
            );
          },
          icon: const Icon(Icons.check),
          label: const Text("Confirm Reschedule"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

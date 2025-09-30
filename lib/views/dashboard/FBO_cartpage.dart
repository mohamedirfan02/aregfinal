import 'package:areg_app/agent/common/common_appbar.dart';
import 'package:areg_app/common/app_colors.dart';
import 'package:areg_app/config/api_config.dart';
import 'package:areg_app/core/storage/app_assets_constant.dart';
import 'package:areg_app/views/screens/widgets/k_svg.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Order Model
class Order {
  final int orderId;
  final String type;
  final String quantity;
  final String status;
  final int userId;
  final String agreedUnitPrice;
  final String counterUnitPrice;
  final String amount;
  final int? vendorId;
  final String? vendorStatus;
  final int agentId;
  final String oilQuality;
  final String? oilImage;
  final String userName;
  final String userContact;
  final String address;
  final String timeline;
  final String pickupLocation;
  final String date;
  final String time;

  Order({
    required this.orderId,
    required this.type,
    required this.quantity,
    required this.status,
    required this.userId,
    required this.agreedUnitPrice,
    required this.counterUnitPrice,
    required this.amount,
    required this.vendorId,
    required this.vendorStatus,
    required this.agentId,
    required this.oilQuality,
    required this.oilImage,
    required this.userName,
    required this.userContact,
    required this.address,
    required this.timeline,
    required this.pickupLocation,
    required this.date,
    required this.time,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['order_id'] ?? 0,
      type: json['type'] ?? '',
      quantity: json['quantity'] ?? '',
      status: json['status'] ?? '',
      userId: json['user_id'] ?? 0,
      agreedUnitPrice: json['agreed_price'] ?? '',
      counterUnitPrice: json['counter_unit_price'] ?? '',
      amount: json['amount'] ?? '',
      vendorId: json['vendor_id'],
      vendorStatus: json['vendor_status'],
      agentId: json['agent_id'] ?? 0,
      oilQuality: json['oil_quality'] ?? '',
      oilImage: json['oil_image'],
      userName: json['user_name'] ?? '',
      userContact: json['user_contact'] ?? '',
      address: json['registered_address'] ?? '',
      timeline: json['timeline'] ?? '',
      pickupLocation: json['pickup_location'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
    );
  }
}

class FboCartScreen extends StatefulWidget {
  const FboCartScreen({super.key});

  @override
  State<FboCartScreen> createState() => _FboCartScreenState();
}

class _FboCartScreenState extends State<FboCartScreen> {
  List<Order> allOrders = [];
  List<Order> filteredOrders = [];
  bool isLoading = false;
  TextEditingController searchController = TextEditingController();

  // Filter options
  Set<String> selectedStatuses = {};
  String? selectedYear;

  @override
  void initState() {
    super.initState();
    fetchOrders();
    searchController.addListener(_filterOrders);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filterOrders() {
    setState(() {
      filteredOrders = allOrders.where((order) {
        // Search filter
        final searchTerm = searchController.text.toLowerCase();
        final matchesSearch = searchTerm.isEmpty ||
            order.orderId.toString().contains(searchTerm) ||
            order.type.toLowerCase().contains(searchTerm) ||
            order.userName.toLowerCase().contains(searchTerm);

        // Status filter
        final matchesStatus = selectedStatuses.isEmpty ||
            selectedStatuses.contains(order.status.toLowerCase());

        // Year filter
        final matchesYear =
            selectedYear == null || order.date.contains(selectedYear!);

        return matchesSearch && matchesStatus && matchesYear;
      }).toList();
    });
  }

  Future<void> fetchOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('user_id');

    setState(() => isLoading = true);
    allOrders.clear();

    if (token == null || userId == null) {
      print("❌ No token or user_id found. User must log in again.");
      setState(() => isLoading = false);
      return;
    }

    final List<String> statuses = [
      'pending',
      'accepted',
      'assigned',
      'completed'
    ];

    for (String status in statuses) {
      try {
        print("🔹 Fetching orders with status: $status");

        final response = await http.post(
          Uri.parse(ApiConfig.getOrderDetails),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            "id": int.parse(userId),
            "role": "user",
            "status": status,
          }),
        );

        print("📩 Raw Response (${response.statusCode}): ${response.body}");

        if (response.statusCode == 200) {
          final jsonBody = json.decode(response.body);

          print("✅ Parsed Response for status '$status': $jsonBody");

          final List<Order> orders = (jsonBody['data'] is List)
              ? (jsonBody['data'] as List)
                  .map<Order>((json) => Order.fromJson(json))
                  .toList()
              : [];

          print("📦 Orders extracted for '$status': $orders");

          allOrders.addAll(orders);
        } else {
          print(
              "❌ Failed to fetch orders for '$status': ${response.reasonPhrase}");
        }
      } catch (e) {
        print("❌ Error fetching orders for status '$status': $e");
      }
    }

    // Sort orders by date (newest first)
    allOrders.sort((a, b) => b.orderId.compareTo(a.orderId));
    filteredOrders = allOrders;

    setState(() => isLoading = false);

    print("📊 Final All Orders Count: ${allOrders.length}");
    print("📊 Final All Orders Data: $allOrders");
  }

  void _showFilterSheet() {
    // Create temporary filter states
    Set<String> tempStatuses = Set.from(selectedStatuses);
    String? tempYear = selectedYear;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Filters",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          tempStatuses.clear();
                          tempYear = null;
                        });
                      },
                      child: Text(
                        "Clear Filter",
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  "Order Status",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildFilterChip('pending', 'Pending', tempStatuses, (val) {
                      setModalState(() {
                        if (val) {
                          tempStatuses.add('pending');
                        } else {
                          tempStatuses.remove('pending');
                        }
                      });
                    }),
                    _buildFilterChip('accepted', 'Accepted', tempStatuses,
                        (val) {
                      setModalState(() {
                        if (val) {
                          tempStatuses.add('accepted');
                        } else {
                          tempStatuses.remove('accepted');
                        }
                      });
                    }),
                    _buildFilterChip('assigned', 'Assigned', tempStatuses,
                        (val) {
                      setModalState(() {
                        if (val) {
                          tempStatuses.add('assigned');
                        } else {
                          tempStatuses.remove('assigned');
                        }
                      });
                    }),
                    _buildFilterChip('completed', 'Completed', tempStatuses,
                        (val) {
                      setModalState(() {
                        if (val) {
                          tempStatuses.add('completed');
                        } else {
                          tempStatuses.remove('completed');
                        }
                      });
                    }),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  "Order Time",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildYearChip('2025', tempYear, (val) {
                      setModalState(() {
                        tempYear = val ? '2025' : null;
                      });
                    }),
                    _buildYearChip('2024', tempYear, (val) {
                      setModalState(() {
                        tempYear = val ? '2024' : null;
                      });
                    }),
                    _buildYearChip('2023', tempYear, (val) {
                      setModalState(() {
                        tempYear = val ? '2023' : null;
                      });
                    }),
                    _buildYearChip('2022', tempYear, (val) {
                      setModalState(() {
                        tempYear = val ? '2022' : null;
                      });
                    }),
                    _buildYearChip('2021', tempYear, (val) {
                      setModalState(() {
                        tempYear = val ? '2021' : null;
                      });
                    }),
                  ],
                ),
                const SizedBox(height: 36),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedStatuses = tempStatuses;
                            selectedYear = tempYear;
                            _filterOrders();
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor:  AppColors.secondaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Apply",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, Set<String> selected,
      Function(bool) onSelected) {
    final isSelected = selected.contains(value);
    return InkWell(
      onTap: () => onSelected(!isSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle : Icons.add_circle_outline,
              size: 18,
              color: isSelected ? const Color(0xFF7FBF08) : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearChip(
      String year, String? selectedYear, Function(bool) onSelected) {
    final isSelected = selectedYear == year;
    return InkWell(
      onTap: () => onSelected(!isSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              year,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle : Icons.add_circle_outline,
              size: 18,
              color: isSelected ? const Color(0xFF7FBF08) : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderTrackingSheet(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => OrderTrackingSheet(order: order),
    );
  }

  void _cancelOrder(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Order"),
        content: const Text("Are you sure you want to cancel this order?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Yes")),
        ],
      ),
    );

    if (confirmed == true) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.fboColor), // ✅ custom color
                        ),
                        KSvg(
                          svgPath: AppAssetsConstants.splashLogo,
                          height: 30,
                          width: 30,
                          boxFit: BoxFit.cover,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("Cancelling order..."),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('token');
        String? userIdString = prefs.getString('user_id');

        if (token == null || userIdString == null) {
          Navigator.pop(context);
          return;
        }

        int userId = int.tryParse(userIdString) ?? 1;

        final response = await http.post(
          Uri.parse(ApiConfig.CancelOilOrder),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            "user_id": userId,
            "order_id": order.orderId,
          }),
        );

        Navigator.pop(context);

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Order cancelled successfully"),
              backgroundColor: AppColors.secondaryColor,
            ),
          );
          fetchOrders();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to cancel order"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: CommonAppbar(title: "My Orders"),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search By Oil Types',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _showFilterSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.tune, color: Colors.grey[700], size: 22),
                        const SizedBox(width: 6),
                        Text(
                          'Filters',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          // Orders List
          Expanded(
            child: isLoading
                ? const Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.fboColor), // ✅ custom color
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
                : filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined,
                                size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              searchController.text.isNotEmpty ||
                                      selectedStatuses.isNotEmpty ||
                                      selectedYear != null
                                  ? "No Orders Found"
                                  : "No Orders Available",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchOrders,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = filteredOrders[index];
                            return OrderListItem(
                              order: order,
                              onTap: () => _showOrderTrackingSheet(order),
                              onCancel: order.status.toLowerCase() == 'pending'
                                  ? () => _cancelOrder(order)
                                  : null,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class OrderListItem extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const OrderListItem({
    Key? key,
    required this.order,
    required this.onTap,
    this.onCancel,
  }) : super(key: key);

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'assigned':
        return 'On the way';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  String _getOilImageUrl(String oilType) {
    // If order has an oil_image from API, use that
    if (order.oilImage != null && order.oilImage!.isNotEmpty) {
      return order.oilImage!;
    }

    // Otherwise, use default images based on oil type
    // Convert to lowercase and trim for matching
    final type = oilType.toLowerCase().trim();

    if (type.contains('coconut')) {
      return 'https://cdn.pixabay.com/photo/2018/01/05/04/44/food-3062139_1280.jpg';
    } else if (type.contains('palm')) {
      return 'https://pixabay.com/get/gce679d7ef32157793ea257a180186623cb2c748c90826fd25baeafd60191872af0140453d5eb77e9cf3b272e540e06fc34d98e6c3452fb1790832e5a19a75f61_1280.jpg';
    } else if (type.contains('sunflower')) {
      return 'https://cdn.pixabay.com/photo/2020/11/17/14/18/oil-5752467_1280.jpg';
    } else if (type.contains('olive')) {
      return 'https://images.pexels.com/photos/33783/olive-oil-salad-dressing-cooking-olive.jpg?auto=compress&cs=tinysrgb&w=400';
    } else if (type.contains('vegetable')) {
      return 'https://images.pexels.com/photos/4110256/pexels-photo-4110256.jpeg?auto=compress&cs=tinysrgb&w=400';
    } else if (type.contains('used') || type.contains('cooking')) {
      return 'https://cdn.pixabay.com/photo/2016/11/15/22/48/pork-1827747_960_720.jpg';
    } else {
      // Default cooking oil image for any other type
      return 'https://images.pexels.com/photos/4110256/pexels-photo-4110256.jpeg?auto=compress&cs=tinysrgb&w=400';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Oil Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _getOilImageUrl(order.type),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.water_drop_outlined,
                      color: const Color(0xFF7FBF08),
                      size: 30,
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                        color: const Color(0xFF7FBF08),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Order Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusText(order.status),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${order.type} - ${order.quantity} Kg",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (onCancel != null)
                    TextButton(
                      onPressed: onCancel,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        "Cancel Order",
                        style: TextStyle(
                          color: Color(0xFFEF5350),
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Arrow Icon
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

class OrderTrackingSheet extends StatelessWidget {
  final Order order;

  const OrderTrackingSheet({Key? key, required this.order}) : super(key: key);

  List<Map<String, dynamic>> _getTrackingSteps() {
    return [
      {
        'title': 'Collection Requested',
        'subtitle': 'Your order has been placed',
        'date': '${order.date} ${order.time}',
        'status': 'pending',
        'icon': Icons.receipt_long,
      },
      {
        'title': 'Order Accepted',
        'subtitle': 'Your order has been confirmed',
        'date': order.status == 'pending' ? 'Waiting' : 'Accepted',
        'status': 'accepted',
        'icon': Icons.check_circle,
      },
      {
        'title': 'Agent Assigned',
        'subtitle': order.vendorId != null
            ? 'Agent ID: ${order.vendorId}'
            : 'Waiting for Agent assignment',
        'date': order.status == 'assigned' || order.status == 'completed'
            ? 'Assigned'
            : 'Pending',
        'status': 'assigned',
        'icon': Icons.local_shipping,
      },
      {
        'title': 'Collection Completed',
        'subtitle': order.status == 'completed'
            ? 'Oil quality: ${order.oilQuality}'
            : 'Waiting for completion',
        'date': order.status == 'completed' ? 'Completed' : 'Pending',
        'status': 'completed',
        'icon': Icons.task_alt,
      },
    ];
  }

  int _getCurrentStepIndex() {
    switch (order.status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'accepted':
        return 1;
      case 'assigned':
        return 2;
      case 'completed':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentStep = _getCurrentStepIndex();
    final steps = _getTrackingSteps();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Order #${order.orderId}",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                "${order.type} • ${order.quantity} Kg",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Text(
                "₹${order.amount}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7FBF08),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      order.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone_outlined,
                        size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      order.userContact,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.pickupLocation,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Order Tracking",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              final isCompleted = index <= currentStep;
              final isActive = index == currentStep;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? const Color(0xFF7FBF08)
                                : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            step['icon'],
                            color:
                                isCompleted ? Colors.white : Colors.grey[600],
                            size: 20,
                          ),
                        ),
                        if (index < steps.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: isCompleted
                                  ? const Color(0xFF7FBF08)
                                  : Colors.grey[300],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step['title'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isCompleted
                                    ? Colors.black87
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step['subtitle'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step['date'],
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

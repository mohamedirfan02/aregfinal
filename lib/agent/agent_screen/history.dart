import 'package:areg_app/common/app_colors.dart';
import 'package:flutter/material.dart';
import '../agent_service/history_api.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Order>> _ordersFuture;
  final OrderApi _orderApi = OrderApi();
  List<Order> _allOrders = [];
  List<Order> _filteredOrders = [];
  String _selectedStatus = 'All';
  late AnimationController _animationController;

  final List<Map<String, dynamic>> _statusOptions = [
    {'label': 'All', 'icon': Icons.grid_view_rounded},
    {'label': 'Pending', 'icon': Icons.schedule},
    {'label': 'Accepted', 'icon': Icons.check_circle_outline},
    {'label': 'Assigned', 'icon': Icons.person_add},
    {'label': 'Completed', 'icon': Icons.task_alt},
    {'label': 'acknowledged', 'icon': Icons.verified},
    {'label': 'Confirmed', 'icon': Icons.done_all},
    {'label': 'Declined', 'icon': Icons.cancel_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _ordersFuture = fetchOrders();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String? status, bool isDark) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return isDark ? AppColors.darkestGreen : AppColors.lightGreen;

      case 'accepted':
        return isDark ? AppColors.secondaryColor : AppColors.primaryColor;

      case 'declined':
        return isDark ? AppColors.softRed : Colors.redAccent;

      case 'acknowledged':
        return isDark ? AppColors.darkGreen : AppColors.fboColor;

      case 'assigned':
        return isDark ? AppColors.darkestGreen : AppColors.loginColor;

      case 'completed':
        return isDark ? AppColors.secondaryColor : AppColors.lightGreen;

      case 'confirmed':
        return isDark ? AppColors.darkGreen : AppColors.primaryGreen;

      default:
        return isDark ? AppColors.greyColor : AppColors.greyColor.withOpacity(0.6);
    }
  }


  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'accepted':
        return Icons.check_circle_outline;
      case 'declined':
        return Icons.cancel_outlined;
      case 'acknowledged':
        return Icons.verified;
      case 'assigned':
        return Icons.person_add;
      case 'completed':
        return Icons.task_alt;
      case 'confirmed':
        return Icons.done_all;
      default:
        return Icons.help_outline;
    }
  }

  Future<List<Order>> fetchOrders() async {
    try {
      List<dynamic> ordersJson = await _orderApi.fetchOrders();
      List<Order> orders =
      ordersJson.map((json) => Order.fromJson(json)).toList();
      _allOrders = orders;
      _applyFilter();
      return orders;
    } catch (e) {
      debugPrint("Error fetching orders: $e");
      return [];
    }
  }

  void _applyFilter() {
    setState(() {
      if (_selectedStatus == 'All') {
        _filteredOrders = _allOrders;
      } else {
        _filteredOrders = _allOrders
            .where((order) =>
        order.status?.toLowerCase() == _selectedStatus.toLowerCase())
            .toList();
      }
    });
    _animationController.reset();
    _animationController.forward();
  }

  void _showOrderDetails(Order order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getStatusColor(order.status, isDark),
                      _getStatusColor(order.status, isDark).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getStatusIcon(order.status),
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Order #${order.orderId ?? 'N/A'}",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            order.type ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.status ?? 'N/A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (order.oilImage != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          order.oilImage!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    _buildDetailSection(
                      'Order Information',
                      [
                        _buildDetailRow(Icons.shopping_cart, 'Quantity',
                            order.quantity ?? 'N/A', textColor),
                        _buildDetailRow(Icons.water_drop, 'Oil Quality',
                            order.oilQuality ?? 'N/A', textColor),
                        _buildDetailRow(Icons.attach_money, 'Amount',
                            order.amount ?? 'N/A', textColor),
                      ],
                      textColor,
                      isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailSection(
                      'Customer Details',
                      [
                        _buildDetailRow(Icons.person, 'Name',
                            order.userName ?? 'N/A', textColor),
                        _buildDetailRow(Icons.phone, 'Contact',
                            order.userContact ?? 'N/A', textColor),
                        _buildDetailRow(Icons.location_on, 'Address',
                            order.registeredAddress ?? 'N/A', textColor),
                      ],
                      textColor,
                      isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailSection(
                      'Delivery Information',
                      [
                        _buildDetailRow(Icons.calendar_today, 'Date',
                            order.date ?? 'N/A', textColor),
                        _buildDetailRow(Icons.access_time, 'Time',
                            order.time ?? 'N/A', textColor),
                        _buildDetailRow(Icons.timeline, 'Timeline',
                            order.timeline ?? 'N/A', textColor),
                        _buildDetailRow(Icons.location_pin, 'Pickup Location',
                            order.pickupLocation ?? 'N/A', textColor),
                        _buildDetailRow(Icons.local_shipping, 'Agent Status',
                            order.Vendorstatus ?? 'Not Assigned', textColor),
                      ],
                      textColor,
                      isDark,
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

  Widget _buildDetailSection(String title, List<Widget> children,
      Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      IconData icon, String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: textColor.withOpacity(0.7)),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: textColor.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? Colors.grey[900] : AppColors.fboColor,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Order History',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [Colors.grey[900]!, Colors.grey[800]!]
                        : [AppColors.fboColor, AppColors.fboColor.withOpacity(0.8)],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _statusOptions.map((status) {
                    final isSelected = _selectedStatus == status['label'];
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedStatus = status['label'];
                            _applyFilter();
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                              colors: [
                                _getStatusColor(status['label'], isDark),
                                _getStatusColor(status['label'], isDark)
                                    .withOpacity(0.7),
                              ],
                            )
                                : null,
                            color: isSelected
                                ? null
                                : isDark
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSelected
                                ? [
                              BoxShadow(
                                color: _getStatusColor(
                                    status['label'], isDark)
                                    .withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                status['icon'],
                                size: 20,
                                color: isSelected
                                    ? Colors.white
                                    : textColor.withOpacity(0.7),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                status['label'],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : textColor.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          FutureBuilder<List<Order>>(
            future: _ordersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          "Oops! Something went wrong",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Please try again later",
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (_filteredOrders.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          "No orders found",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Try changing the filter",
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final order = _filteredOrders[index];
                      return FadeTransition(
                        opacity: Tween<double>(begin: 0, end: 1).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              (index / _filteredOrders.length) * 0.5,
                              1.0,
                              curve: Curves.easeOut,
                            ),
                          ),
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.3, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Interval(
                                (index / _filteredOrders.length) * 0.5,
                                1.0,
                                curve: Curves.easeOut,
                              ),
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[850] : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _showOrderDetails(order),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              _getStatusColor(
                                                  order.status, isDark),
                                              _getStatusColor(
                                                  order.status, isDark)
                                                  .withOpacity(0.7),
                                            ],
                                          ),
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          _getStatusIcon(order.status),
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Order #${order.orderId ?? 'N/A'}",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "${order.type ?? 'Unknown'} • ${order.quantity ?? 'N/A'}",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color:
                                                textColor.withOpacity(0.7),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(Icons.person,
                                                    size: 14,
                                                    color: textColor
                                                        .withOpacity(0.5)),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    order.userName ?? 'N/A',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: textColor
                                                          .withOpacity(0.6),
                                                    ),
                                                    overflow:
                                                    TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                  order.status, isDark)
                                                  .withOpacity(0.2),
                                              borderRadius:
                                              BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              order.status ?? 'N/A',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: _getStatusColor(
                                                    order.status, isDark),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Icon(
                                            Icons.chevron_right,
                                            color: textColor.withOpacity(0.3),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: _filteredOrders.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class Order {
  final int? orderId;
  final String? type;
  final String? quantity;
  final String? status;
  final String? Vendorstatus;
  final String? userName;
  final String? userContact;
  final String? registeredAddress;
  final String? date;
  final String? time;
  final String? proposedUnitPrice;
  final String? counterUnitPrice;
  final String? amount;
  final String? oilQuality;
  final String? oilImage;
  final String? timeline;
  final String? pickupLocation;

  Order({
    required this.orderId,
    required this.type,
    required this.quantity,
    required this.status,
    required this.Vendorstatus,
    required this.userName,
    required this.userContact,
    required this.registeredAddress,
    required this.date,
    required this.time,
    required this.proposedUnitPrice,
    required this.counterUnitPrice,
    required this.amount,
    required this.oilQuality,
    required this.oilImage,
    required this.timeline,
    required this.pickupLocation,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json["order_id"] as int?,
      type: json["type"] as String? ?? "Unknown",
      quantity: json["quantity"] as String? ?? "0",
      status: json["status"] as String? ?? "",
      Vendorstatus: json["vendor_status"] as String? ?? "not assigned",
      userName: json["user_name"] as String? ?? "No Name",
      userContact: json["user_contact"] as String? ?? "No Contact",
      registeredAddress: json["registered_address"] as String? ?? "No Address",
      date: json["date"] as String? ?? "N/A",
      time: json["time"] as String? ?? "N/A",
      proposedUnitPrice: json["proposed_unit_price"]?.toString() ?? "0",
      counterUnitPrice: json["counter_unit_price"]?.toString() ?? "-",
      amount: json["amount"]?.toString() ?? "0",
      oilQuality: json["oil_quality"] as String? ?? "-",
      oilImage: json["oil_image"] as String?,
      timeline: json["timeline"] as String? ?? "-",
      pickupLocation: json["pickup_location"] as String? ?? "-",
    );
  }
}
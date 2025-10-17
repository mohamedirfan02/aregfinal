import 'package:areg_app/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/shimmer_loader.dart';
import '../agent_service/agent_acknowledgment_service.dart';

class AgentAcknowledgmentScreen extends StatefulWidget {
  const AgentAcknowledgmentScreen({super.key});

  @override
  _AgentAcknowledgmentScreenState createState() =>
      _AgentAcknowledgmentScreenState();
}

class _AgentAcknowledgmentScreenState extends State<AgentAcknowledgmentScreen>
    with SingleTickerProviderStateMixin {
  final AgentAcknowledgmentService _acknowledgmentService =
  AgentAcknowledgmentService();
  List<Map<String, dynamic>> acknowledgmentList = [];
  bool isLoading = true;
  bool hasError = false;
  Map<int, bool> isAcknowledging = {};
  Map<int, bool> oilReceived = {};
  AnimationController? _animationController;
  bool showOverlayLoader = false;


  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    fetchAcknowledgmentDetails();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> fetchAcknowledgmentDetails() async {
    setState(() => isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userIdString = prefs.getString('user_id');
    int? userId = userIdString != null ? int.tryParse(userIdString) : null;

    if (token == null || userId == null) {
      print("❌ Error: Token or User ID is missing or invalid.");
      setState(() {
        hasError = true;
        isLoading = false;
      });
      return;
    }

    final data =
    await _acknowledgmentService.fetchAcknowledgmentDetails(token, userId);

    if (data != null) {
      setState(() {
        acknowledgmentList = data;
        for (var order in acknowledgmentList) {
          oilReceived[order['order_id']] = false;
        }
        isLoading = false;
      });
      _animationController?.forward();
    } else {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> acknowledgeOrder(int orderId) async {
    if (oilReceived[orderId] != true) return;

    setState(() {
      isAcknowledging[orderId] = true;
    });

    bool success = await _acknowledgmentService.acknowledgeOrder(orderId);

    if (success) {
      // Remove the order immediately for better UX
      setState(() {
        acknowledgmentList.removeWhere((order) => order['order_id'] == orderId);
        oilReceived.remove(orderId);
        isAcknowledging.remove(orderId);
      });

      // Show success dialog after UI update
      if (mounted) {
        showResponseDialog("Order acknowledged successfully!", "success");
      }
    } else {
      setState(() {
        isAcknowledging[orderId] = false;
      });

      if (mounted) {
        showResponseDialog("Failed to acknowledge order!", "error");
      }
    }
  }

  void showResponseDialog(String message, String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[850] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                status == "success" ? Icons.check_circle : Icons.error,
                color: status == "success" ? Colors.green : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                status == "success" ? "Success" : "Error",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor:
                status == "success" ? Colors.green : Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                "OK",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    int orderId = order['order_id'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.75,
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
                        AppColors.secondaryColor,
                        AppColors.secondaryColor.withOpacity(0.7),
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
                        child: const Icon(
                          Icons.receipt_long,
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
                              "Order #$orderId",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              order['type'] ?? 'Unknown',
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
                          order['status'] ?? 'N/A',
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
                      _buildDetailSection(
                        'Order Information',
                        [
                          _buildDetailRow(Icons.restaurant, 'Restaurant',
                              order['restaurant_name'] ?? 'N/A', textColor),
                          _buildDetailRow(Icons.shopping_cart, 'Quantity',
                              order['quantity']?.toString() ?? 'N/A', textColor),
                          _buildDetailRow(Icons.info_outline, 'Status',
                              order['status'] ?? 'N/A', textColor),
                        ],
                        textColor,
                        isDark,
                      ),
                      const SizedBox(height: 16),
                      _buildDetailSection(
                        'Customer Details',
                        [
                          _buildDetailRow(Icons.person, 'Name',
                              order['user_name'] ?? 'N/A', textColor),
                          _buildDetailRow(Icons.restaurant_menu, 'Type',
                              order['type'] ?? 'N/A', textColor),
                          _buildDetailRow(Icons.phone, 'Contact',
                              order['user_contact'] ?? 'N/A', textColor),
                          _buildDetailRow(Icons.location_on, 'Address',
                              order['registered_address'] ?? 'N/A', textColor),
                        ],
                        textColor,
                        isDark,
                      ),
                      const SizedBox(height: 16),
                      _buildDetailSection(
                        'Schedule & Payment',
                        [
                          _buildDetailRow(Icons.calendar_today, 'Date',
                              order['date'] ?? 'N/A', textColor),
                          _buildDetailRow(Icons.access_time, 'Time',
                              order['time'] ?? 'N/A', textColor),
                          _buildDetailRow(Icons.payment, 'Payment Method',
                              order['payment_method'] ?? 'N/A', textColor),
                        ],
                        textColor,
                        isDark,
                      ),
                      const SizedBox(height: 24),
                      // Oil Received Checkbox
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (oilReceived[orderId] ?? false)
                                ? AppColors.secondaryColor
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: oilReceived[orderId] ?? false,
                              onChanged: (bool? value) {
                                setState(() {
                                  oilReceived[orderId] = value ?? false;
                                });
                                setModalState(() {});
                              },
                              activeColor: AppColors.secondaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Oil Received",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    "Confirm that you have received the oil",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textColor.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Acknowledge Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: oilReceived[orderId] == true &&
                              isAcknowledging[orderId] != true
                              ? () async {
                            // Immediately close the bottom sheet without waiting for its animation
                            Navigator.of(context).pop();

                            Future.delayed(const Duration(milliseconds: 200), () async {
                              setState(() => showOverlayLoader = true);

                              await acknowledgeOrder(orderId);

                              // Hide loader after the popup closes
                              Future.delayed(const Duration(milliseconds: 300), () {
                                if (mounted) setState(() => showOverlayLoader = false);
                              });
                            });
                          }
                              : null,

                          style: ElevatedButton.styleFrom(
                            backgroundColor: oilReceived[orderId] == true
                                ? AppColors.secondaryColor
                                : Colors.grey.shade400,
                            disabledBackgroundColor: Colors.grey.shade400,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: oilReceived[orderId] == true ? 4 : 0,
                          ),
                          child: isAcknowledging[orderId] == true
                              ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                "Acknowledge Order",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const ShimmerLoader(height: 60, width: 60),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerLoader(height: 20, width: 120),
                    const SizedBox(height: 8),
                    const ShimmerLoader(height: 14, width: 180),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(child: ShimmerLoader(height: 14)),
                        const SizedBox(width: 10),
                        ShimmerLoader(
                            height: 30,
                            width: 30,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Stack(
      children: [
        Scaffold(
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
                    'Acknowledgment',
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
                            : [
                          AppColors.fboColor,
                          AppColors.fboColor.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              if (isLoading)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 200,
                    child: _buildShimmerList(),
                  ),
                )
              else if (hasError)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          "Failed to load data!",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: fetchAcknowledgmentDetails,
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                )
              else if (acknowledgmentList.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Lottie.asset(
                            'assets/animations/no_data.json',
                            width: 200,
                            height: 200,
                            repeat: false,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "No Acknowledgement List yet!",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Orders will appear here when available",
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final order = acknowledgmentList[index];
                          int orderId = order['order_id'];

                          return AnimatedBuilder(
                            animation: _animationController ??
                                AnimationController(vsync: this, duration: Duration.zero),
                            builder: (context, child) {
                              final animation = _animationController != null
                                  ? CurvedAnimation(
                                parent: _animationController!,
                                curve: Interval(
                                  (index / acknowledgmentList.length) * 0.5,
                                  1.0,
                                  curve: Curves.easeOut,
                                ),
                              )
                                  : AlwaysStoppedAnimation(1.0);

                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.3, 0),
                                    end: Offset.zero,
                                  ).animate(animation),
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
                                                      AppColors.secondaryColor,
                                                      AppColors.secondaryColor
                                                          .withOpacity(0.7),
                                                    ],
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.receipt_long,
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
                                                      "Order #$orderId",
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: textColor,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      "${order['type'] ?? 'Unknown'} • ${order['quantity'] ?? 'N/A'}",
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: textColor.withOpacity(0.7),
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
                                                            order['user_name'] ??
                                                                'N/A',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: textColor
                                                                  .withOpacity(0.6),
                                                            ),
                                                            overflow: TextOverflow
                                                                .ellipsis,
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
                                                    padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.secondaryColor
                                                          .withOpacity(0.2),
                                                      borderRadius:
                                                      BorderRadius.circular(20),
                                                    ),
                                                    child: Text(
                                                      order['status'] ?? 'N/A',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color:
                                                        AppColors.secondaryColor,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Icon(
                                                    Icons.chevron_right,
                                                    color:
                                                    textColor.withOpacity(0.3),
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
                          );
                        },
                        childCount: acknowledgmentList.length,
                      ),
                    ),
                  ),
            ],

          ),
        ),
        if (showOverlayLoader)
          Container(
            color: Colors.black.withOpacity(0.4),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
      ],
    );
  }

}
import 'dart:ui';
import 'package:areg_app/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../common/custom_appbar.dart';
import '../../fbo_services/Fbo_Acknowledgment_Service.dart';

class FboAcknowledgmentScreen extends StatefulWidget {
  const FboAcknowledgmentScreen({super.key});

  @override
  _FboAcknowledgmentScreenState createState() => _FboAcknowledgmentScreenState();
}

class _FboAcknowledgmentScreenState extends State<FboAcknowledgmentScreen> {
  List<dynamic> completedOrders = [];
  bool isLoading = true;
  bool hasError = false;
  Map<int, bool> paymentReceived = {}; // ✅ Track Payment Checkbox State
  Set<int> loadingOrders = {}; // Use Set to avoid duplicates

  @override
  void initState() {
    super.initState();
    fetchCompletedOrders();
  }
  void _showTopSnackbar(
      String message, {
        Color backgroundColor = Colors.black87,
        Color textColor = Colors.white,
        Widget? icon,
      }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).viewPadding.top + 16,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: backgroundColor.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      icon,
                      SizedBox(width: 10),
                    ],
                    Expanded( // THIS is the fix
                      child: Text(
                        message,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2)).then((_) => overlayEntry.remove());
  }



  /// ✅ Fetch completed orders
  Future<void> fetchCompletedOrders() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    final response = await FboAcknowledgmentService.fetchCompletedOrders();

    if (response != null) {
      setState(() {
        completedOrders = response;
        isLoading = false;

        for (var order in completedOrders) {
          paymentReceived[order["order_id"]] = false;
        }
      });
    } else {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }


  /// Acknowledge an order
  Future<void> acknowledgeOrder(int orderId) async {
    // Show loading IMMEDIATELY when button is clicked
    setState(() {
      loadingOrders.add(orderId);
    });

    try {
      // Call the API
      bool success = await FboAcknowledgmentService.acknowledgeOrder(orderId);

      if (success) {
        _showTopSnackbar(
          "Order $orderId acknowledged successfully!",
          backgroundColor: Colors.white60,
          textColor: Colors.black,
          icon: Image.asset(
            'assets/icon/smile.png',
            height: 24,
            width: 24,
          ),
        );

        // ✅ Remove the order from the list
        setState(() {
          completedOrders.removeWhere((order) => order["order_id"] == orderId);
        });
      } else {
        _showTopSnackbar(
          "Failed to acknowledge order. Try again!",
          backgroundColor: Colors.white60,
          textColor: Colors.red,
          icon: Image.asset(
            'assets/icon/error.png',
            height: 24,
            width: 24,
          ),
        );
      }
    } catch (e) {
      // Handle any exceptions
      _showTopSnackbar(
        "An error occurred. Please try again!",
        backgroundColor: Colors.white60,
        textColor: Colors.red,
        icon: Image.asset(
          'assets/icon/error.png',
          height: 24,
          width: 24,
        ),
      );
    } finally {
      // ✅ Always remove loading state when done
      setState(() {
        loadingOrders.remove(orderId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
          ? const Center(child: Text("Failed to load completed orders"))
          : completedOrders.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/empty.json',
              width: 200,
              height: 200,
              repeat: false,
            ),
            const SizedBox(height: 20),
            const Text(
              "No completed orders yet!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: completedOrders.length,
          itemBuilder: (context, index) {
            var order = completedOrders[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color:AppColors.primaryColor,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "Order ID: ${order["order_id"]}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.titleColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                   _buildVoucherItem("Restaurant Name:", order['restaurant_name']??'N/A'),
                    _buildVoucherItem("Type:", order['type']),
                    _buildVoucherItem("payment method:", order['payment_method']??''),
                    _buildVoucherItem("Quantity:", "${order['quantity']}"),
                    _buildVoucherItem("Status:", order['status']),
                    //_buildVoucherItem("Unit Price:", "₹${order['proposed_unit_price'] ?? 'N/A'}"),
                    _buildVoucherItem("Name:", order['user_name']),
                    _buildVoucherItem("Oil Quality:", order['oil_quality']),
                    _buildVoucherItem("Address:", order['registered_address'], multiline: true,),
                    _buildVoucherItem("Date:", order['date']),
                    _buildVoucherItem("Time:", order['time']),
                    const SizedBox(height: 15),

                    // Payment Received Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: paymentReceived[order["order_id"]] ?? false,
                          onChanged: (value) {
                            setState(() {
                              paymentReceived[order["order_id"]] = value!;
                            });
                          },
                        ),
                        Text(
                          "Payment Received",
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.titleColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    // Acknowledge Button (Enabled only if Payment Received)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: paymentReceived[order["order_id"]] == true
                            ? () => acknowledgeOrder(order["order_id"])
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          disabledBackgroundColor: Colors.black38,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: loadingOrders.contains(order["order_id"])
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                            : const Text(
                          "Acknowledge",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )

                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }



  Widget _buildVoucherItem(String title, String value, {bool multiline = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4), // Slight vertical padding
      child: Row(
        crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: AppColors.titleColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: AppColors.secondaryColor,
                height: multiline ? 1.4 : 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

}

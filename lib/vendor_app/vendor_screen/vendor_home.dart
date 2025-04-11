import 'package:areg_app/vendor_app/vendor_screen/vendor_cart.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../agent/agent_screen/history.dart';
import '../../agent/common/agent_action_button.dart';
import '../../views/screens/fbo_voucher.dart';
import '../comman/vendor_appbar.dart';
import 'Vendor_Acknowledge.dart';
import 'completed_order_screen.dart'; // Import your custom app bar

class VendorHomeScreen extends StatelessWidget {
  const VendorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold( // ✅ Wrap Scaffold with gradient container

 body: Scaffold(
   backgroundColor: Colors.transparent, // Light green background
      body: SafeArea(
        child: Column(
          children: [
            // ✅ Use Custom Vendor App Bar
            const VendorAppBar(title: 'Agent Home'),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Restaurant Management Card
                   // _buildRestaurantCard(),

                    // ✅ Truck Animation with Date
                    // ✅ Truck Animation with Date (Reduced Top Space)
                    Stack(
                      clipBehavior: Clip.none, // ✅ Allows positioning outside parent
                      children: [
                        Column(
                          children: [
                            SizedBox(
                              //height: screenHeight * 0.5, // ✅ Adjust height
                              child: Lottie.asset(
                                'assets/animations/animation.json',
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 5), // ✅ Reduce space below animation
                            // const Text(
                            //   "Today Wed 8 Feb, 2025",
                            //   style: TextStyle(color: Colors.black54),
                            // ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // 🔹 Total Amount & Oil Collection Section
                    //_buildTotalAmountSection(),

                    const SizedBox(height: 15),

                    // 🔹 Action Buttons Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _customActionButton("Acknowledge", onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const VendorAcknowledge()),
                          );
                        }),
                        _customActionButton("Voucher", onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const VoucherHistoryScreen()),
                          );
                        }),
                      //  _customActionButton("FBO Request", badgeCount: 8),
                       // _customActionButton("Order Assign"),
                        _customActionButton("Completed Orders", onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CompletedOrdersScreen()),
                          );
                        }),
                       // _customActionButton("Collection Data"),
                        _customActionButton("History", onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const HistoryScreen()),
                          );
                        }),
                        _customActionButton("Service data", onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const VendorCartPage()),
                          );
                        }),
                      ],
                    ),
//Acknowledge
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  // // 🔹 Restaurant Management Card
  // Widget _buildRestaurantCard() {
  //   return Container(
  //     padding: const EdgeInsets.all(12),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         colors: [Colors.green.shade200, Colors.green.shade100],
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //       ),
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text(
  //           "Restaurant Management",
  //           style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
  //         ),
  //         const Text(
  //           "For - CareWell",
  //           style: TextStyle(fontSize: 12, color: Colors.black54),
  //         ),
  //         const SizedBox(height: 8),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Row(
  //               children: [
  //                 // Image.asset("assets/images/sample_fbo.png", width: 50), // Replace with your asset
  //                 const SizedBox(width: 8),
  //                 Container(
  //                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  //                   decoration: BoxDecoration(
  //                     color: Colors.green.shade700,
  //                     borderRadius: BorderRadius.circular(8),
  //                   ),
  //                   child: const Text(
  //                     "+8",
  //                     style: TextStyle(color: Colors.white, fontSize: 12),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             Column(
  //               children: [
  //                 const Text("Due date", style: TextStyle(fontSize: 12, color: Colors.black54)),
  //                 const Text("🗓️ June 6, 2025", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
  //               ],
  //             ),
  //             Stack(
  //               alignment: Alignment.center,
  //               children: [
  //                 CircularProgressIndicator(
  //                   value: 0.88, // 88%
  //                   backgroundColor: Colors.grey[300],
  //                   valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
  //                 ),
  //                 const Text("88%", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // // 🔹 Total Amount & Oil Collection Section
  // Widget _buildTotalAmountSection() {
  //   return Container(
  //     padding: const EdgeInsets.all(12),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.grey.shade300,
  //           blurRadius: 6,
  //           spreadRadius: 2,
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: const [
  //                 Text("Total Amount", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
  //                 Text("2528.60 ₹", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
  //               ],
  //             ),
  //             Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: const [
  //                 Text("Oil Collection", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
  //                 Text("250 KG", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
  //               ],
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 8),
  //         // Row(
  //         //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //         //   children: [
  //         //     _customTabButton("Restaurant", true),
  //         //     _customTabButton("Vendor", false),
  //         //   ],
  //         // ),
  //       ],
  //     ),
  //   );
  // }

  // 🔹 Custom Tab Button
  Widget _customTabButton(String text, bool isSelected) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade700 : Colors.green.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 🔹 Custom Action Button
  Widget _customActionButton(String text, {int? badgeCount, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap, // Handle navigation or actions
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade300, Colors.green.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                text,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            if (badgeCount != null)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "+$badgeCount",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

}

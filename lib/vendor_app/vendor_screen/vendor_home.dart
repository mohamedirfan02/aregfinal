// import 'dart:convert';
// import 'dart:ui';
// import 'package:areg_app/common/app_colors.dart';
// import 'package:areg_app/common/floating_chatbot_btn.dart';
// import 'package:areg_app/vendor_app/vendor_screen/vendor_order_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../agent/agent_screen/history.dart';
// import '../../config/api_config.dart';
// import '../../views/screens/fbo_voucher.dart';
// import '../comman/vendor_appbar.dart';
// import 'Vendor_Acknowledge.dart';
// import 'completed_order_screen.dart';
// import 'order_reject.dart';
//
// class VendorHomeScreen extends StatefulWidget {
//   const VendorHomeScreen({super.key});
//
//   @override
//   State<VendorHomeScreen> createState() => _VendorHomeScreenState();
// }
//
// class _VendorHomeScreenState extends State<VendorHomeScreen> {
//   String totalBalance = "₹290,500";
//   String percentageIncrease = "85%";
//   List<Map<String, dynamic>> pendingOrders = [];
//   List<Map<String, dynamic>> approvedOrders = [];
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchAssignedOrders();
//   }
//
//   /// ✅ Fetch all assigned orders from API
//   Future<void> _fetchAssignedOrders() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? token = prefs.getString('token');
//     String? vendorIdString = prefs.getString('vendor_id');
//     int? vendorId =
//     vendorIdString != null ? int.tryParse(vendorIdString) : null;
//
//     if (token == null || vendorId == null) {
//       debugPrint("❌ No token or vendor ID found. User must log in again.");
//       setState(() => _isLoading = false);
//       return;
//     }
//
//     final url = ApiConfig.getVendorAssignedSale(vendorId.toString());
//     debugPrint("Fetching data from: $url");
//
//     try {
//       final response = await http.get(
//         Uri.parse(url),
//         headers: {
//           "Content-Type": "application/json",
//           "Accept": "application/json",
//           "Authorization": "Bearer $token",
//         },
//       );
//
//       debugPrint("Response Status Code: ${response.statusCode}");
//       debugPrint("Response Body: ${response.body}");
//
//       if (response.statusCode == 200) {
//         final jsonData = json.decode(response.body);
//
//         if (jsonData["status"] == "success") {
//           setState(() {
//             pendingOrders =
//                 jsonData["pendingData"] ?? []; // ✅ Fetch Pending Orders
//             approvedOrders =
//                 jsonData["approvedData"] ?? []; // ✅ Fetch Approved Orders
//             _isLoading = false;
//           });
//         } else {
//           debugPrint("❌ API returned an unexpected format");
//           setState(() => _isLoading = false);
//         }
//       } else {
//         debugPrint(
//             "❌ API request failed with status code: ${response.statusCode}");
//         setState(() => _isLoading = false);
//       }
//     } catch (e) {
//       debugPrint("❌ Error fetching data: $e");
//       setState(() => _isLoading = false);
//     }
//   }
//
//   /// 🔄 Refresh the data
//   Future<void> _refreshOrders() async {
//     await _fetchAssignedOrders();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0A0E27),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF0A0E27),
//         elevation: 0,
//         leading: Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Container(
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(color: Colors.white24, width: 1),
//             ),
//             child: const CircleAvatar(
//               backgroundImage: NetworkImage(
//                 'https://via.placeholder.com/150',
//               ),
//             ),
//           ),
//         ),
//         title: const Text(
//           'Joseph Zeng',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.card_giftcard, color: Colors.white70),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: const Icon(Icons.notifications, color: Colors.white70),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Balance Section
//               _buildBalanceSection(),
//               const SizedBox(height: 24),
//
//               // Card Section
//               _buildCardSection(),
//               const SizedBox(height: 24),
//
//               // Action Buttons
//               _buildActionButtons(),
//               const SizedBox(height: 24),
//
//               // Promotional Section
//               _buildPromoSection(),
//               const SizedBox(height: 32),
//
//               // Recent Orders Header
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         'Assigned Orders',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         '${pendingOrders.length} pending',
//                         style: const TextStyle(
//                           color: Colors.white54,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                   GestureDetector(
//                     onTap: _refreshOrders,
//                     child: Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF7C3AED).withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(
//                           color: const Color(0xFF7C3AED).withOpacity(0.3),
//                         ),
//                       ),
//                       child: const Icon(
//                         Icons.refresh,
//                         color: Color(0xFF7C3AED),
//                         size: 20,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//
//               // Recent Orders List
//               if (_isLoading)
//                 Container(
//                   padding: const EdgeInsets.all(40),
//                   child: const Column(
//                     children: [
//                       CircularProgressIndicator(
//                         valueColor: AlwaysStoppedAnimation<Color>(
//                           Color(0xFF7C3AED),
//                         ),
//                       ),
//                       SizedBox(height: 16),
//                       Text(
//                         'Loading orders...',
//                         style: TextStyle(
//                           color: Colors.white70,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ],
//                   ),
//                 )
//               else if (pendingOrders.isEmpty)
//                 Container(
//                   padding: const EdgeInsets.all(40),
//                   child: Column(
//                     children: const [
//                       Icon(Icons.inbox, color: Colors.white30, size: 56),
//                       SizedBox(height: 16),
//                       Text(
//                         'No assigned orders',
//                         style: TextStyle(
//                           color: Colors.white70,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       SizedBox(height: 8),
//                       Text(
//                         'Orders will appear here when assigned',
//                         style: TextStyle(
//                           color: Colors.white54,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 )
//               else
//                 ListView.builder(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   itemCount: pendingOrders.length,
//                   itemBuilder: (context, index) {
//                     return _buildOrderCard(pendingOrders[index]);
//                   },
//                 ),
//
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBalanceSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Balance',
//           style: TextStyle(
//             color: Colors.white70,
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           children: [
//             Text(
//               totalBalance,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 42,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(width: 12),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF10B981).withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               child: Row(
//                 children: const [
//                   Icon(Icons.trending_up, color: Color(0xFF10B981), size: 14),
//                   SizedBox(width: 4),
//                   Text(
//                     '85% All Time Increase',
//                     style: TextStyle(
//                       color: Color(0xFF10B981),
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Widget _buildCardSection() {
//     return Stack(
//       children: [
//         Container(
//           height: 200,
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 const Color(0xFF7C3AED).withOpacity(0.3),
//                 const Color(0xFF3B82F6).withOpacity(0.3),
//               ],
//             ),
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(
//               color: Colors.white.withOpacity(0.2),
//               width: 1.5,
//             ),
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(20),
//             child: BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//               child: Container(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Row(
//                           children: [
//                             Icon(
//                               Icons.contactless,
//                               color: Colors.white,
//                               size: 28,
//                             ),
//                             const SizedBox(width: 12),
//                             const Text(
//                               'VISA',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                         Icon(
//                           Icons.contactless,
//                           color: Colors.white,
//                           size: 28,
//                         ),
//                       ],
//                     ),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           '•••• •••• •••• 4829',
//                           style: TextStyle(
//                             color: Colors.white70,
//                             fontSize: 16,
//                             letterSpacing: 2,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: const [
//                                 Text(
//                                   'Card Holder',
//                                   style: TextStyle(
//                                     color: Colors.white70,
//                                     fontSize: 11,
//                                   ),
//                                 ),
//                                 SizedBox(height: 4),
//                                 Text(
//                                   'Joseph Zeng',
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 14,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: const [
//                                 Text(
//                                   'Expires',
//                                   style: TextStyle(
//                                     color: Colors.white70,
//                                     fontSize: 11,
//                                   ),
//                                 ),
//                                 SizedBox(height: 4),
//                                 Text(
//                                   '12/26',
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 14,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildActionButtons() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceAround,
//       children: [
//         _buildActionButton('Send', Icons.arrow_upward),
//         _buildActionButton('Swap', Icons.swap_vert),
//         _buildActionButton('Receive', Icons.arrow_downward),
//         _buildActionButton('More', Icons.more_horiz),
//       ],
//     );
//   }
//
//   Widget _buildActionButton(String label, IconData icon) {
//     return GestureDetector(
//       onTap: () {},
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: Colors.white.withOpacity(0.2),
//             width: 1,
//           ),
//         ),
//         child: Column(
//           children: [
//             Icon(icon, color: Colors.white70, size: 24),
//             const SizedBox(height: 6),
//             Text(
//               label,
//               style: const TextStyle(
//                 color: Colors.white70,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPromoSection() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             const Color(0xFF1E1B4B),
//             const Color(0xFF2D1B69),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: const Color(0xFF7C3AED).withOpacity(0.3),
//           width: 1,
//         ),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: const [
//               Text(
//                 'Take Control of Your Assets.',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               SizedBox(height: 4),
//               Text(
//                 'Start trading and manage NFTs easily',
//                 style: TextStyle(
//                   color: Colors.white70,
//                   fontSize: 12,
//                 ),
//               ),
//             ],
//           ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//             decoration: BoxDecoration(
//               color: const Color(0xFF7C3AED),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: const Text(
//               'Explore Now',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildOrderCard(Map<String, dynamic> order) {
//     final String restaurantName = order['restaurant_name'] ?? 'Unknown';
//     final String oilType = order['type'] ?? 'Oil';
//     final String quantity = order['quantity'] ?? '0';
//     final String amount = order['amount'] ?? '0';
//     final String userName = order['user_name'] ?? 'N/A';
//     final String userContact = order['user_contact'] ?? 'N/A';
//     final String pickupLocation = order['pickup_location'] ?? 'N/A';
//     final String orderDate = order['date'] ?? 'N/A';
//     final String orderId = order['order_id'].toString();
//
//     return GestureDetector(
//       onTap: () {
//         _showOrderDetails(order);
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 12),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.06),
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(
//             color: Colors.white.withOpacity(0.12),
//             width: 1,
//           ),
//         ),
//         child: Row(
//           children: [
//             // Oil Type Icon
//             Container(
//               width: 56,
//               height: 56,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     const Color(0xFF7C3AED).withOpacity(0.3),
//                     const Color(0xFF3B82F6).withOpacity(0.3),
//                   ],
//                 ),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                   color: const Color(0xFF7C3AED).withOpacity(0.3),
//                   width: 1,
//                 ),
//               ),
//               child: const Icon(
//                 Icons.oil_barrel,
//                 color: Color(0xFF7C3AED),
//                 size: 28,
//               ),
//             ),
//             const SizedBox(width: 14),
//
//             // Order Details
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     restaurantName,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 15,
//                       fontWeight: FontWeight.w600,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 6),
//                   Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 8, vertical: 3),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFF10B981).withOpacity(0.2),
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                         child: Text(
//                           oilType,
//                           style: const TextStyle(
//                             color: Color(0xFF10B981),
//                             fontSize: 11,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Text(
//                         'Order #$orderId',
//                         style: const TextStyle(
//                           color: Colors.white54,
//                           fontSize: 11,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 6),
//                   Row(
//                     children: [
//                       const Icon(Icons.water_drop, color: Colors.white38, size: 14),
//                       const SizedBox(width: 4),
//                       Text(
//                         '$quantity L',
//                         style: const TextStyle(
//                           color: Colors.white54,
//                           fontSize: 12,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       const Icon(Icons.calendar_today, color: Colors.white38, size: 14),
//                       const SizedBox(width: 4),
//                       Text(
//                         orderDate,
//                         style: const TextStyle(
//                           color: Colors.white54,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//
//             // Amount and Arrow
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Text(
//                   '₹${amount}',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF10B981).withOpacity(0.15),
//                     borderRadius: BorderRadius.circular(6),
//                     border: Border.all(
//                       color: const Color(0xFF10B981).withOpacity(0.3),
//                       width: 0.5,
//                     ),
//                   ),
//                   child: const Text(
//                     'Assigned',
//                     style: TextStyle(
//                       color: Color(0xFF10B981),
//                       fontSize: 11,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Icon(
//                   Icons.chevron_right,
//                   color: Colors.white30,
//                   size: 20,
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// 📋 Show order details in a bottom sheet
//   void _showOrderDetails(Map<String, dynamic> order) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (BuildContext context) {
//         return Container(
//           decoration: BoxDecoration(
//             color: const Color(0xFF1A1A2E),
//             borderRadius: const BorderRadius.only(
//               topLeft: Radius.circular(24),
//               topRight: Radius.circular(24),
//             ),
//             border: Border(
//               top: BorderSide(
//                 color: Colors.white.withOpacity(0.1),
//                 width: 1,
//               ),
//             ),
//           ),
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Header
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text(
//                         'Order Details',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       GestureDetector(
//                         onTap: () => Navigator.pop(context),
//                         child: Icon(
//                           Icons.close,
//                           color: Colors.white70,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//
//                   // Restaurant Info
//                   _buildDetailRow('Restaurant', order['restaurant_name'] ?? 'N/A'),
//                   _buildDetailRow('Customer', order['user_name'] ?? 'N/A'),
//                   _buildDetailRow('Contact', order['user_contact'] ?? 'N/A'),
//                   const SizedBox(height: 16),
//                   const Divider(color: Colors.white12),
//                   const SizedBox(height: 16),
//
//                   // Order Info
//                   _buildDetailRow('Order ID', '#${order['order_id']}'),
//                   _buildDetailRow('Oil Type', order['type'] ?? 'N/A'),
//                   _buildDetailRow('Quantity', '${order['quantity']} L'),
//                   _buildDetailRow('Amount', '₹${order['amount']}'),
//                   const SizedBox(height: 16),
//                   const Divider(color: Colors.white12),
//                   const SizedBox(height: 16),
//
//                   // Pickup Info
//                   const Text(
//                     'Pickup Location',
//                     style: TextStyle(
//                       color: Colors.white70,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     order['pickup_location'] ?? 'N/A',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 13,
//                       height: 1.5,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//
//                   // Action Button
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: () => Navigator.pop(context),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF7C3AED),
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       child: const Text(
//                         'Acknowledge Order',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               color: Colors.white54,
//               fontSize: 13,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           Flexible(
//             child: Text(
//               value,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 13,
//                 fontWeight: FontWeight.w600,
//               ),
//               textAlign: TextAlign.end,
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:areg_app/common/app_colors.dart';
import 'package:areg_app/common/floating_chatbot_btn.dart';
import 'package:areg_app/vendor_app/vendor_screen/vendor_order_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../agent/agent_screen/history.dart';
import '../../agent/common/agent_action_button.dart';
import '../../config/api_config.dart';
import '../../views/screens/fbo_voucher.dart';
import '../comman/vendor_appbar.dart';
import 'Vendor_Acknowledge.dart';
import 'completed_order_screen.dart';
import 'order_reject.dart';

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  String oilCollection = "0 KG";
  String todaycount = "0";
  String currentDate = "";

  @override
  void initState() {
    super.initState();
    fetchVendorData();
  }

  Future<void> fetchVendorData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? agentId = prefs.getString('vendor_id');

      if (token == null || agentId == null) {
        print("🚨 Token or Agent ID is null.");
        return;
      }

      print("🔄 Fetching vendor data...");

      var response = await http.post(
        Uri.parse(ApiConfig.getCpHome),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "role": "vendor",
          "id": int.parse(agentId),
        }),
      );

      print("🔹 Response Status Code: ${response.statusCode}");
      print("🔹 Raw Response Body: ${response.body}");

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        setState(() {
          todaycount = "${data["today_count"] ?? 0}";
          oilCollection = "${data["total_quantity"] ?? 0} KG";
          currentDate = data["current_date"] ?? "";
        });

        print(
            "✅ Updated: $todaycount orders, $oilCollection oil, $currentDate");
      } else {
        print("❌ Failed to fetch data: ${response.body}");
      }
    } catch (e) {
      print("🚨 Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Define dynamic colors for light/dark
    final backgroundColor =
    isDark ? theme.scaffoldBackgroundColor : Colors.white;
    final primaryGreen = isDark ? Color(0xFF4CAF50) : AppColors.secondaryColor;
    final secondaryGreen = isDark ? Color(0xFF81C784) : AppColors.secondaryColor;
    final textColorLight = isDark ? Colors.white70 : Colors.white70;
    final textColorWhite = isDark ? Colors.white : Colors.white;
    final textColorDark = isDark ? Colors.white70 : Colors.black87;
    final containerBgColor = isDark ? theme.cardColor : Colors.white;
    final containerBorderColor =
    isDark ? Colors.white12 : Colors.black.withOpacity(0.1);
    final shadowColor = isDark ? Colors.black45 : Colors.black12;

    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: VendorAppBar(title: 'Welcome'),
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
                  color: primaryGreen,
                  image: const DecorationImage(
                    image: AssetImage('assets/image/agent_home.png'),
                    fit: BoxFit.contain,
                  ),
                  border: Border.all(
                    width: 1.28,
                    color: theme.dividerColor.withOpacity(0.2),
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
                              color: textColorLight,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            oilCollection,
                            style: TextStyle(
                              color: textColorWhite,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                    const HistoryScreen()),
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
                              backgroundColor: primaryGreen,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                                side: const BorderSide(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.arrow_outward,
                                size: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 60,),
                    Container(
                      margin: const EdgeInsets.only(
                          top: 20, left: 16, right: 16, bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: containerBgColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: 6,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            currentDate.isNotEmpty
                                ? "Today $currentDate"
                                : "Loading date...",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: textColorDark,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.9, // Responsive width
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        "Today Collection",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.secondaryColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondaryColor,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withAlpha((0.2 * 255).toInt()),
                                            blurRadius: 3,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        "$todaycount Restaurant",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),


                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 20),
                      child: Row(
                        children: [
                          Expanded(
                              child:
                              Divider(color: secondaryGreen, thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              "Service Request",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: primaryGreen,
                              ),
                            ),
                          ),
                          Expanded(
                              child:
                              Divider(color: secondaryGreen, thickness: 1)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: containerBgColor,
                          border:
                          Border.all(color: containerBorderColor, width: 1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _serviceBtn(
                                  context,
                                  title: "Orders",
                                  imagePath: "assets/icon/lg1.png",
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const VendorCartPage()),
                                  ),
                                ),
                                _divider(),
                                _serviceBtn(
                                  context,
                                  title: "Completed",
                                  imagePath: "assets/icon/lg2.png",
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                        const CompletedOrdersScreen()),
                                  ),
                                ),
                                _divider(),
                                _serviceBtn(
                                  context,
                                  title: "Rejected",
                                  imagePath: "assets/icon/lg3.png",
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const OrdersRejected()),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Spacer(flex: 1),
                                _serviceBtn(
                                  context,
                                  title: "Acknowledge",
                                  imagePath: "assets/icon/lg4.png",
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                        const VendorAcknowledge()),
                                  ),
                                ),
                                _divider(),
                                _serviceBtn(
                                  context,
                                  title: "Voucher",
                                  imagePath: "assets/icon/lg5.png",
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                        const VoucherHistoryScreen()),
                                  ),
                                ),
                                const Spacer(flex: 1),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const DraggableChatbotButton(),
          ],
        ));
  }

  Widget _serviceBtn(
      BuildContext ctx, {
        required String title,
        required String imagePath,
        required VoidCallback onTap,
      }) {
    return SizedBox(
      width: 90,
      height: 90,
      child: ActionButton(title: title, imagePath: imagePath, onTap: onTap),
    );
  }

  Widget _divider() => Container(
    height: 60,
    width: 1,
    color:AppColors.secondaryColor.withOpacity(0.5),
  );
}
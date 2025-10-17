// import 'package:areg_app/common/app_colors.dart';
// import 'package:areg_app/common/floating_chatbot_btn.dart';
// import 'package:areg_app/config/api_config.dart';
// import 'package:areg_app/views/screens/fbo_voucher.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
// import 'agent_screen/AcknowledgmentScreen.dart';
// import 'agent_screen/Fbo_DocumentScreen.dart';
// import 'agent_screen/agent_login_request.dart';
// import 'agent_screen/asign_agent.dart';
// import 'agent_screen/fbo_rejected_list.dart';
// import 'agent_screen/fbo_request.dart';
// import 'agent_screen/history.dart';
// import 'agent_screen/total_restaurant.dart';
// import 'agent_screen/total_vendor.dart';
// import 'common/agent_appbar.dart';
//
// class AgentHomeScreen extends StatefulWidget {
//   final String token;
//
//   const AgentHomeScreen({super.key, required this.token});
//
//   @override
//   _AgentHomeScreenState createState() => _AgentHomeScreenState();
// }
//
// class _AgentHomeScreenState extends State<AgentHomeScreen> with SingleTickerProviderStateMixin {
//   String totalAmount = "0.00";
//   String oilCollection = "0";
//   bool isLoading = true;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
//     );
//
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.3),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
//
//     fetchAgentData();
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   Future<void> fetchAgentData() async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       String? agentId = prefs.getString('agent_id');
//
//       var response = await http.post(
//         Uri.parse(ApiConfig.getCpHome),
//         headers: {
//           "Authorization": "Bearer $token",
//           "Content-Type": "application/json",
//         },
//         body: jsonEncode({
//           "role": "agent",
//           "id": int.parse(agentId!),
//         }),
//       );
//
//       if (response.statusCode == 200) {
//         var data = json.decode(response.body);
//         setState(() {
//           totalAmount = "${data["total_amount"] ?? "0.00"}";
//           oilCollection = "${data["total_quantity"] ?? "0"}";
//           isLoading = false;
//         });
//         _animationController.forward();
//       }
//     } catch (e) {
//       print("Error: $e");
//       setState(() => isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenHeight = MediaQuery.of(context).size.height;
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//
//     return Scaffold(
//       backgroundColor: isDark ? const Color(0xFF0A0E21) : const Color(0xFFF5F7FA),
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(60),
//         child: AgentAppBar(title: 'Collection Point'),
//       ),
//       body: RefreshIndicator(
//         onRefresh: fetchAgentData,
//         color: AppColors.fboColor,
//         child: Stack(
//           children: [
//             // Premium gradient background
//             Container(
//               height: screenHeight * 0.4,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: isDark
//                       ? [const Color(0xFF1A237E), const Color(0xFF0D47A1)]
//                       : [AppColors.fboColor, AppColors.fboColor.withOpacity(0.8)],
//                 ),
//               ),
//             ),
//
//             // Decorative circles
//             Positioned(
//               top: -50,
//               right: -50,
//               child: Container(
//                 width: 200,
//                 height: 200,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: Colors.white.withOpacity(0.1),
//                 ),
//               ),
//             ),
//             Positioned(
//               top: 100,
//               left: -30,
//               child: Container(
//                 width: 120,
//                 height: 120,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: Colors.white.withOpacity(0.05),
//                 ),
//               ),
//             ),
//
//             SafeArea(
//               child: CustomScrollView(
//                 physics: const BouncingScrollPhysics(),
//                 slivers: [
//                   // Header Stats Card
//                   SliverToBoxAdapter(
//                     child: FadeTransition(
//                       opacity: _fadeAnimation,
//                       child: SlideTransition(
//                         position: _slideAnimation,
//                         child: _buildHeaderCard(screenWidth, screenHeight, isDark),
//                       ),
//                     ),
//                   ),
//
//                   // Quick Stats Row
//                   SliverToBoxAdapter(
//                     child: FadeTransition(
//                       opacity: _fadeAnimation,
//                       child: _buildQuickStats(context, screenWidth, screenHeight, isDark),
//                     ),
//                   ),
//
//                   // Service Request Section
//                   SliverToBoxAdapter(
//                     child: FadeTransition(
//                       opacity: _fadeAnimation,
//                       child: Column(
//                         children: [
//                           SizedBox(height: screenHeight * 0.025),
//                           _buildSectionHeader("Service Requests", screenWidth, isDark),
//                           SizedBox(height: screenHeight * 0.02),
//                           _buildServiceGrid(context, screenWidth, screenHeight, isDark),
//                           SizedBox(height: screenHeight * 0.025),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             if (isLoading)
//               Container(
//                 color: Colors.black26,
//                 child: Center(
//                   child: CircularProgressIndicator(
//                     valueColor: AlwaysStoppedAnimation<Color>(AppColors.fboColor),
//                   ),
//                 ),
//               ),
//
//             const DraggableChatbotButton(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildHeaderCard(double screenWidth, double screenHeight, bool isDark) {
//     return Container(
//       margin: EdgeInsets.all(screenWidth * 0.05),
//       padding: EdgeInsets.all(screenWidth * 0.06),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: isDark
//               ? [const Color(0xFF1E1E2E), const Color(0xFF2D2D44)]
//               : [Colors.white, Colors.white.withOpacity(0.9)],
//         ),
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [
//           BoxShadow(
//             color: isDark ? Colors.black45 : Colors.black12,
//             blurRadius: 20,
//             offset: const Offset(0, 10),
//             spreadRadius: 0,
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Flexible(
//                 child: Text(
//                   "Total Oil Collected",
//                   style: TextStyle(
//                     color: isDark ? Colors.white70 : Colors.grey.shade600,
//                     fontSize: screenWidth * 0.038,
//                     fontWeight: FontWeight.w500,
//                     letterSpacing: 0.5,
//                   ),
//                 ),
//               ),
//               Container(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: screenWidth * 0.03,
//                   vertical: screenHeight * 0.008,
//                 ),
//                 decoration: BoxDecoration(
//                   color: AppColors.fboColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(
//                     color: AppColors.fboColor.withOpacity(0.3),
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.trending_up,
//                       size: screenWidth * 0.035,
//                       color: AppColors.fboColor,
//                     ),
//                     SizedBox(width: screenWidth * 0.01),
//                     Text(
//                       "Live",
//                       style: TextStyle(
//                         color: AppColors.fboColor,
//                         fontSize: screenWidth * 0.03,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: screenHeight * 0.02),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               TweenAnimationBuilder<double>(
//                 duration: const Duration(milliseconds: 1000),
//                 tween: Tween(begin: 0.0, end: double.tryParse(oilCollection) ?? 0.0),
//                 builder: (context, value, child) {
//                   return Text(
//                     value.toStringAsFixed(0),
//                     style: TextStyle(
//                       color: isDark ? Colors.white : AppColors.secondaryColor,
//                       fontSize: screenWidth * 0.14,
//                       fontWeight: FontWeight.bold,
//                       height: 1,
//                     ),
//                   );
//                 },
//               ),
//               Padding(
//                 padding: EdgeInsets.only(bottom: screenHeight * 0.01, left: screenWidth * 0.02),
//                 child: Text(
//                   "KG",
//                   style: TextStyle(
//                     color: isDark ? Colors.white60 : Colors.grey.shade600,
//                     fontSize: screenWidth * 0.05,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: screenHeight * 0.02),
//           Row(
//             children: [
//               Expanded(
//                 child: _buildInfoChip(
//                   "Revenue",
//                   "₹$totalAmount",
//                   Icons.account_balance_wallet_outlined,
//                   screenWidth,
//                   screenHeight,
//                   isDark,
//                 ),
//               ),
//               SizedBox(width: screenWidth * 0.03),
//               Expanded(
//                 child: _buildActionButton(screenWidth, screenHeight, isDark),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildInfoChip(String label, String value, IconData icon, double screenWidth, double screenHeight, bool isDark) {
//     return Container(
//       padding: EdgeInsets.all(screenWidth * 0.03),
//       decoration: BoxDecoration(
//         color: isDark ? Colors.white.withOpacity(0.05) : AppColors.fboColor.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: EdgeInsets.all(screenWidth * 0.02),
//             decoration: BoxDecoration(
//               color: AppColors.fboColor.withOpacity(0.2),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(icon, size: screenWidth * 0.04, color: AppColors.fboColor),
//           ),
//           SizedBox(width: screenWidth * 0.025),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: TextStyle(
//                     fontSize: screenWidth * 0.028,
//                     color: isDark ? Colors.white60 : Colors.grey.shade600,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 SizedBox(height: screenHeight * 0.002),
//                 Text(
//                   value,
//                   style: TextStyle(
//                     fontSize: screenWidth * 0.035,
//                     fontWeight: FontWeight.bold,
//                     color: isDark ? Colors.white : AppColors.secondaryColor,
//                   ),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildActionButton(double screenWidth, double screenHeight, bool isDark) {
//     return Material(
//       color: AppColors.fboColor,
//       borderRadius: BorderRadius.circular(12),
//       child: InkWell(
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => const HistoryScreen()),
//           );
//         },
//         borderRadius: BorderRadius.circular(12),
//         child: Container(
//           padding: EdgeInsets.all(screenWidth * 0.03),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.history, color: Colors.white, size: screenWidth * 0.045),
//               SizedBox(width: screenWidth * 0.02),
//               Flexible(
//                 child: Text(
//                   'View History',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w600,
//                     fontSize: screenWidth * 0.032,
//                   ),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildQuickStats(BuildContext context, double screenWidth, double screenHeight, bool isDark) {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
//       child: Row(
//         children: [
//           Expanded(
//             child: _buildStatCard(
//               "FBO",
//               "Restaurants",
//               Icons.restaurant_menu,
//               screenWidth,
//               screenHeight,
//               isDark,
//                   () => Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantList())),
//             ),
//           ),
//           SizedBox(width: screenWidth * 0.03),
//           Expanded(
//             child: _buildStatCard(
//               "Rejected",
//               "Requests",
//               Icons.cancel_outlined,
//               screenWidth,
//               screenHeight,
//               isDark,
//                   () => Navigator.push(context, MaterialPageRoute(builder: (_) => FboRejectedList())),
//             ),
//           ),
//           SizedBox(width: screenWidth * 0.03),
//           Expanded(
//             child: _buildStatCard(
//               "Agents",
//               "Active",
//               Icons.people_outline,
//               screenWidth,
//               screenHeight,
//               isDark,
//                   () => Navigator.push(context, MaterialPageRoute(builder: (_) => VendorList())),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatCard(String title, String subtitle, IconData icon, double screenWidth, double screenHeight, bool isDark, VoidCallback onTap) {
//     return Material(
//       color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
//       borderRadius: BorderRadius.circular(16),
//       elevation: isDark ? 0 : 2,
//       shadowColor: Colors.black12,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(16),
//         child: Container(
//           padding: EdgeInsets.all(screenWidth * 0.04),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 padding: EdgeInsets.all(screenWidth * 0.03),
//                 decoration: BoxDecoration(
//                   color: AppColors.fboColor.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   icon,
//                   color: AppColors.fboColor,
//                   size: screenWidth * 0.06,
//                 ),
//               ),
//               SizedBox(height: screenHeight * 0.012),
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: screenWidth * 0.035,
//                   fontWeight: FontWeight.bold,
//                   color: isDark ? Colors.white : AppColors.secondaryColor,
//                 ),
//                 textAlign: TextAlign.center,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               SizedBox(height: screenHeight * 0.002),
//               Text(
//                 subtitle,
//                 style: TextStyle(
//                   fontSize: screenWidth * 0.028,
//                   color: isDark ? Colors.white60 : Colors.grey.shade600,
//                 ),
//                 textAlign: TextAlign.center,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSectionHeader(String title, double screenWidth, bool isDark) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
//       child: Row(
//         children: [
//           Container(
//             width: 4,
//             height: screenWidth * 0.06,
//             decoration: BoxDecoration(
//               color: AppColors.fboColor,
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),
//           SizedBox(width: screenWidth * 0.03),
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: screenWidth * 0.05,
//               fontWeight: FontWeight.bold,
//               color: isDark ? Colors.white : AppColors.secondaryColor,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildServiceGrid(BuildContext context, double screenWidth, double screenHeight, bool isDark) {
//     final services = [
//       ServiceItem("Acknowledge", Icons.check_circle_outline, const Color(0xFF4CAF50),
//               () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentAcknowledgmentScreen()))),
//       ServiceItem("Approval", Icons.verified_outlined, const Color(0xFF2196F3),
//               () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FboLoginRequest()))),
//       ServiceItem("Voucher", Icons.receipt_long_outlined, const Color(0xFFFF9800),
//               () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoucherHistoryScreen()))),
//       ServiceItem("Documents", Icons.description_outlined, const Color(0xFF9C27B0),
//               () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FboDocumentScreen()))),
//       ServiceItem("Order Assign", Icons.assignment_outlined, const Color(0xFFE91E63),
//               () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignAgent()))),
//       ServiceItem("Agent Pending", Icons.pending_actions_outlined, const Color(0xFFFF5722),
//               () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentLoginRequest()))),
//     ];
//
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
//       child: GridView.builder(
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 3,
//           crossAxisSpacing: screenWidth * 0.03,
//           mainAxisSpacing: screenWidth * 0.03,
//           childAspectRatio: 0.85,
//         ),
//         itemCount: services.length,
//         itemBuilder: (context, index) {
//           return _buildPremiumServiceCard(services[index], screenWidth, screenHeight, isDark);
//         },
//       ),
//     );
//   }
//
//   Widget _buildPremiumServiceCard(ServiceItem item, double screenWidth, double screenHeight, bool isDark) {
//     return Material(
//       color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
//       borderRadius: BorderRadius.circular(20),
//       elevation: isDark ? 0 : 3,
//       shadowColor: Colors.black12,
//       child: InkWell(
//         onTap: item.onTap,
//         borderRadius: BorderRadius.circular(20),
//         child: Container(
//           padding: EdgeInsets.symmetric(
//             horizontal: screenWidth * 0.02,
//             vertical: screenHeight * 0.01,
//           ),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(
//               color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
//             ),
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 padding: EdgeInsets.all(screenWidth * 0.032),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: [
//                       item.color.withOpacity(0.8),
//                       item.color,
//                     ],
//                   ),
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                       color: item.color.withOpacity(0.3),
//                       blurRadius: 12,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: Icon(
//                   item.icon,
//                   color: Colors.white,
//                   size: screenWidth * 0.065,
//                 ),
//               ),
//               SizedBox(height: screenHeight * 0.01),
//               Flexible(
//                 child: Text(
//                   item.title,
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: screenWidth * 0.03,
//                     fontWeight: FontWeight.w600,
//                     color: isDark ? Colors.white : AppColors.secondaryColor,
//                     height: 1.2,
//                   ),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class ServiceItem {
//   final String title;
//   final IconData icon;
//   final Color color;
//   final VoidCallback onTap;
//
//   ServiceItem(this.title, this.icon, this.color, this.onTap);
// }

import 'package:areg_app/common/app_colors.dart';
import 'package:areg_app/common/floating_chatbot_btn.dart';
import 'package:areg_app/config/api_config.dart';
import 'package:areg_app/views/screens/fbo_voucher.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'agent_screen/AcknowledgmentScreen.dart';
import 'agent_screen/Fbo_DocumentScreen.dart';
import 'agent_screen/agent_login_request.dart';
import 'agent_screen/asign_agent.dart';
import 'agent_screen/fbo_rejected_list.dart';
import 'agent_screen/fbo_request.dart';
import 'agent_screen/history.dart';
import 'agent_screen/total_restaurant.dart';
import 'agent_screen/total_vendor.dart';
import 'common/agent_appbar.dart';



class AgentHomeScreen extends StatefulWidget {
  final String token;

  const AgentHomeScreen({super.key, required this.token});

  @override
  _AgentHomeScreenState createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen> with SingleTickerProviderStateMixin {
  String totalAmount = "0.00";
  String oilCollection = "0";
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    fetchAgentData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchAgentData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? agentId = prefs.getString('agent_id');

      var response = await http.post(
        Uri.parse(ApiConfig.getCpHome),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "role": "agent",
          "id": int.parse(agentId!),
        }),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          totalAmount = "${data["total_amount"] ?? "0.00"}";
          oilCollection = "${data["total_quantity"] ?? "0"}";
          isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E21) : const Color(0xFFF5F7FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AgentAppBar(title: 'Collection Point'),
      ),
      body: RefreshIndicator(
        onRefresh: fetchAgentData,
        color: AppColors.fboColor,
        child: Stack(
          children: [
            // Premium gradient background with curved bottom
            ClipPath(
              clipper: CurvedBottomClipper(),
              child: Container(
                height: screenHeight * 0.4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF1A237E), const Color(0xFF0D47A1)]
                        : [AppColors.fboColor, AppColors.fboColor.withOpacity(0.8)],
                  ),
                ),
              ),
            ),

            // Decorative circles
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              top: 100,
              left: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header Stats Card
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildHeaderCard(screenWidth, screenHeight, isDark),
                      ),
                    ),
                  ),

                  // Quick Stats Row
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildQuickStats(context, screenWidth, screenHeight, isDark),
                    ),
                  ),

                  // Service Request Section
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          SizedBox(height: screenHeight * 0.025),
                          _buildSectionHeader("Service Requests", screenWidth, isDark),
                          SizedBox(height: screenHeight * 0.02),
                          _buildServiceGrid(context, screenWidth, screenHeight, isDark),
                          SizedBox(height: screenHeight * 0.025),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (isLoading)
              Container(
                color: Colors.black26,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.fboColor),
                  ),
                ),
              ),

            const DraggableChatbotButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(double screenWidth, double screenHeight, bool isDark) {
    return Container(
      margin: EdgeInsets.all(screenWidth * 0.05),
      padding: EdgeInsets.all(screenWidth * 0.06),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E1E2E), const Color(0xFF2D2D44)]
              : [Colors.white, Colors.white.withOpacity(0.9)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black12,
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "Total Oil Collected",
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                    fontSize: screenWidth * 0.038,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03,
                  vertical: screenHeight * 0.008,
                ),
                decoration: BoxDecoration(
                  color: AppColors.fboColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.fboColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: screenWidth * 0.035,
                      color: AppColors.fboColor,
                    ),
                    SizedBox(width: screenWidth * 0.01),
                    Text(
                      "Live",
                      style: TextStyle(
                        color: AppColors.fboColor,
                        fontSize: screenWidth * 0.03,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1000),
                tween: Tween(begin: 0.0, end: double.tryParse(oilCollection) ?? 0.0),
                builder: (context, value, child) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.secondaryColor,
                      fontSize: screenWidth * 0.14,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  );
                },
              ),
              Padding(
                padding: EdgeInsets.only(bottom: screenHeight * 0.01, left: screenWidth * 0.02),
                child: Text(
                  "KG",
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  "Revenue",
                  "₹$totalAmount",
                  Icons.account_balance_wallet_outlined,
                  screenWidth,
                  screenHeight,
                  isDark,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: _buildActionButton(screenWidth, screenHeight, isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon, double screenWidth, double screenHeight, bool isDark) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : AppColors.fboColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.02),
            decoration: BoxDecoration(
              color: AppColors.fboColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: screenWidth * 0.04, color: AppColors.fboColor),
          ),
          SizedBox(width: screenWidth * 0.025),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: screenWidth * 0.028,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: screenHeight * 0.002),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.secondaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(double screenWidth, double screenHeight, bool isDark) {
    return Material(
      color: AppColors.fboColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HistoryScreen()),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(screenWidth * 0.03),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, color: Colors.white, size: screenWidth * 0.045),
              SizedBox(width: screenWidth * 0.02),
              Flexible(
                child: Text(
                  'View History',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: screenWidth * 0.032,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, double screenWidth, double screenHeight, bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              "FBO",
              "Restaurants",
              Icons.restaurant_menu,
              screenWidth,
              screenHeight,
              isDark,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantList())),
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: _buildStatCard(
              "Rejected",
              "Requests",
              Icons.cancel_outlined,
              screenWidth,
              screenHeight,
              isDark,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => FboRejectedList())),
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: _buildStatCard(
              "Agents",
              "Active",
              Icons.people_outline,
              screenWidth,
              screenHeight,
              isDark,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => VendorList())),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String subtitle, IconData icon, double screenWidth, double screenHeight, bool isDark, VoidCallback onTap) {
    return Material(
      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: isDark ? 0 : 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.03),
                decoration: BoxDecoration(
                  color: AppColors.fboColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.fboColor,
                  size: screenWidth * 0.06,
                ),
              ),
              SizedBox(height: screenHeight * 0.012),
              Text(
                title,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.secondaryColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: screenHeight * 0.002),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: screenWidth * 0.028,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, double screenWidth, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Row(
        children: [
          Container(
            width: 4,
            height: screenWidth * 0.06,
            decoration: BoxDecoration(
              color: AppColors.fboColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          Text(
            title,
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceGrid(BuildContext context, double screenWidth, double screenHeight, bool isDark) {
    final services = [
      ServiceItem("Acknowledge", Icons.check_circle_outline, const Color(0xFF4CAF50),
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentAcknowledgmentScreen()))),
      ServiceItem("Approval", Icons.verified_outlined, const Color(0xFF2196F3),
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FboLoginRequest()))),
      ServiceItem("Voucher", Icons.receipt_long_outlined, const Color(0xFFFF9800),
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoucherHistoryScreen()))),
      ServiceItem("Documents", Icons.description_outlined, const Color(0xFF9C27B0),
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FboDocumentScreen()))),
      ServiceItem("Order Assign", Icons.assignment_outlined, const Color(0xFFE91E63),
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignAgent()))),
      ServiceItem("Agent Pending", Icons.pending_actions_outlined, const Color(0xFFFF5722),
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentLoginRequest()))),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: screenWidth * 0.03,
          mainAxisSpacing: screenWidth * 0.03,
          childAspectRatio: 0.85,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          return _buildPremiumServiceCard(services[index], screenWidth, screenHeight, isDark);
        },
      ),
    );
  }

  Widget _buildPremiumServiceCard(ServiceItem item, double screenWidth, double screenHeight, bool isDark) {
    return Material(
      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: isDark ? 0 : 3,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.02,
            vertical: screenHeight * 0.01,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.032),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      item.color.withOpacity(0.8),
                      item.color,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: item.color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  item.icon,
                  color: Colors.white,
                  size: screenWidth * 0.065,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Flexible(
                child: Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.secondaryColor,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ServiceItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  ServiceItem(this.title, this.icon, this.color, this.onTap);
}

// Custom clipper for curved bottom
class CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 60);

    // Create a smooth curve at the bottom
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 30);
    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 60);
    var secondEndPoint = Offset(size.width, size.height - 40);

    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
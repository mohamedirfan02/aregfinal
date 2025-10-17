import 'dart:convert';

import 'package:areg_app/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../models/restaurant_model.dart';
import '../agent_service/fbo_login_request_service.dart';

class FboLoginRequest extends StatefulWidget {
  const FboLoginRequest({Key? key}) : super(key: key);

  @override
  State<FboLoginRequest> createState() => _FboLoginRequestState();
}

class _FboLoginRequestState extends State<FboLoginRequest> {
  late Future<List<Fbo>> futureFboRequests;
  List<Fbo> fboRequests = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    futureFboRequests = fetchFboRequests();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'FBO Login Requests',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.fboColor,
        elevation: 0,
      ),
      body: FutureBuilder<List<Fbo>>(
        future: futureFboRequests,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  SizedBox(height: size.height * 0.02),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/animations/no_data.json',
                    width: size.width * 0.5,
                    height: size.height * 0.25,
                    repeat: false,
                  ),
                  SizedBox(height: size.height * 0.02),
                  const Text(
                    "No FBO Login Requests Found!",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          } else {
            if (fboRequests.isEmpty) {
              fboRequests = snapshot.data!;
            }

            return ListView.builder(
              padding: EdgeInsets.all(size.width * 0.04),
              itemCount: fboRequests.length,
              itemBuilder: (context, index) {
                final fbo = fboRequests[index];
                return _buildFboCard(context, fbo, size);
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildFboCard(BuildContext context, Fbo fbo, Size size) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: size.height * 0.02),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showFboDetailsBottomSheet(context, fbo),
          child: Padding(
            padding: EdgeInsets.all(size.width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.fboColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.restaurant,
                        color: AppColors.fboColor,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: size.width * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fbo.restaurantName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          SizedBox(height: size.height * 0.005),
                          Text(
                            fbo.fullName,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(fbo.status),
                  ],
                ),
                SizedBox(height: size.height * 0.015),
                Divider(color: Colors.grey[300], height: 1),
                SizedBox(height: size.height * 0.015),
                _buildInfoRow(Icons.phone, fbo.contactNumber, size),
                SizedBox(height: size.height * 0.01),
                _buildInfoRow(Icons.email_outlined, fbo.email, size),
                SizedBox(height: size.height * 0.01),
                _buildInfoRow(Icons.location_on_outlined, fbo.address, size, maxLines: 2),
                SizedBox(height: size.height * 0.015),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showFboDetailsBottomSheet(context, fbo),
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Details'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.fboColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Size size, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        SizedBox(width: size.width * 0.02),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showFboDetailsBottomSheet(BuildContext context, Fbo fbo) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FboDetailsBottomSheet(
        fbo: fbo,
        onApprove: (agent, amount) async {
          Navigator.pop(context);
          await _handleStatusUpdate(fbo.id, "approved", agent: agent, amount: amount);
        },
        onReject: (reason) async {
          Navigator.pop(context);
          await _handleStatusUpdate(fbo.id, "rejected", reason: reason);
        },
      ),
    );
  }

  Future<void> _handleStatusUpdate(
      int id,
      String status, {
        String? reason,
        String? agent,
        String? amount,
      }) async {
    if (status == "approved") {
      if (agent == null || agent.isEmpty || amount == null || amount.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select an agent and enter amount"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      isLoading = true;
    });

    await updateFboStatus(
      context,
      id,
      status,
      agent: agent ?? '',
      amount: amount ?? '',
      reason: reason,
    );

    setState(() {
      isLoading = false;
      fboRequests.removeWhere((fbo) => fbo.id == id);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'FBO ${status == "approved" ? "approved" : "rejected"} successfully',
          ),
          backgroundColor: status == "approved" ? Colors.green : Colors.red,
        ),
      );
    }
  }
}

class FboDetailsBottomSheet extends StatefulWidget {
  final Fbo fbo;
  final Function(String agent, String amount) onApprove;
  final Function(String reason) onReject;

  const FboDetailsBottomSheet({
    Key? key,
    required this.fbo,
    required this.onApprove,
    required this.onReject,
  }) : super(key: key);

  @override
  State<FboDetailsBottomSheet> createState() => _FboDetailsBottomSheetState();
}

class _FboDetailsBottomSheetState extends State<FboDetailsBottomSheet> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController agentSearchController = TextEditingController();
  List<AgentInfo> agentsList = [];
  String? selectedAgent;
  bool isLoadingAgents = false;

  @override
  void initState() {
    super.initState();
    _fetchNearestAgents(widget.fbo.address);
  }

  Future<void> _fetchNearestAgents(String address) async {
    setState(() => isLoadingAgents = true);

    const String url = ApiConfig.get_nearest_vendors;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"origin": address}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final List<dynamic> rawAgents = data['data'];

          setState(() {
            agentsList = rawAgents.map((e) => AgentInfo.fromJson(e)).toList();
            isLoadingAgents = false;
          });
        }
      }
    } catch (e) {
      setState(() => isLoadingAgents = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.symmetric(vertical: size.height * 0.015),
                width: size.width * 0.12,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(size.width * 0.05),
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.fboColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.restaurant_menu,
                            color: AppColors.fboColor,
                            size: 32,
                          ),
                        ),
                        SizedBox(width: size.width * 0.04),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.fbo.restaurantName,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              SizedBox(height: size.height * 0.005),
                              Text(
                                widget.fbo.fullName,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: size.height * 0.025),

                    // Contact Information Section
                    _buildSection(
                      "Contact Information",
                      [
                        _buildDetailTile(Icons.phone, "Phone", widget.fbo.contactNumber),
                        _buildDetailTile(Icons.email, "Email", widget.fbo.email),
                        _buildDetailTile(Icons.location_on, "Address", widget.fbo.address),
                      ],
                      size,
                    ),

                    SizedBox(height: size.height * 0.02),

                    // Images Section
                    if (widget.fbo.licenseUrl.isNotEmpty || widget.fbo.restaurantUrl.isNotEmpty)
                      _buildSection(
                        "Documents",
                        [
                          Row(
                            children: [
                              if (widget.fbo.licenseUrl.isNotEmpty)
                                Expanded(
                                  child: _buildImageCard(
                                    "License",
                                    widget.fbo.licenseUrl,
                                    context,
                                    size,
                                  ),
                                ),
                              if (widget.fbo.licenseUrl.isNotEmpty && widget.fbo.restaurantUrl.isNotEmpty)
                                SizedBox(width: size.width * 0.03),
                              if (widget.fbo.restaurantUrl.isNotEmpty)
                                Expanded(
                                  child: _buildImageCard(
                                    "Restaurant",
                                    widget.fbo.restaurantUrl,
                                    context,
                                    size,
                                  ),
                                ),
                            ],
                          ),
                        ],
                        size,
                      ),

                    SizedBox(height: size.height * 0.02),

                    // Branches Section
                    if (widget.fbo.branches.isNotEmpty)
                      _buildSection(
                        "Branches (${widget.fbo.branches.length})",
                        widget.fbo.branches.map((branch) => _buildBranchCard(branch, context, size)).toList(),
                        size,
                      ),

                    SizedBox(height: size.height * 0.02),

                    // Amount Field
                    _buildSection(
                      "Registration Amount",
                      [
                        TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Enter Amount",
                            hintText: "₹0.00",
                            prefixIcon: const Icon(Icons.currency_rupee),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.fboColor, width: 2),
                            ),
                          ),
                        ),
                      ],
                      size,
                    ),

                    SizedBox(height: size.height * 0.02),

                    // Agent Selection
                    _buildSection(
                      "Assign Agent",
                      [
                        isLoadingAgents
                            ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        )
                            : _buildAgentDropdown(size, isDark),
                      ],
                      size,
                    ),

                    SizedBox(height: size.height * 0.03),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showRejectionDialog(context),
                            icon: const Icon(Icons.close),
                            label: const Text("Reject"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: size.height * 0.018),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: size.width * 0.03),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (selectedAgent == null || amountController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Please select agent and enter amount"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              widget.onApprove(selectedAgent!, amountController.text.trim());
                            },
                            icon: const Icon(Icons.check_circle),
                            label: const Text("Approve Request"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: size.height * 0.018),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
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

  Widget _buildSection(String title, List<Widget> children, Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: size.height * 0.012),
        ...children,
      ],
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(String label, String imageUrl, BuildContext context, Size size) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImage(imageUrl: imageUrl),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                height: size.height * 0.18,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(
                      height: size.height * 0.18,
                      color: Colors.grey[200],
                      child: const Icon(Icons.error, size: 50, color: Colors.red),
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchCard(Branch branch, BuildContext context, Size size) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            branch.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildBranchInfo(Icons.location_on, branch.address),
          const SizedBox(height: 6),
          _buildBranchInfo(Icons.assignment, "FSSAI: ${branch.fssaiNo}"),
          if (branch.license.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImage(imageUrl: branch.license),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  branch.license,
                  height: size.height * 0.12,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 40, color: Colors.red),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBranchInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgentDropdown(Size size, bool isDark) {
    return GestureDetector(
      onTap: () => _showAgentSelectionDialog(),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.04,
          vertical: size.height * 0.018,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.person, color: Colors.grey[600]),
            SizedBox(width: size.width * 0.03),
            Expanded(
              child: Text(
                selectedAgent ?? "Select an agent",
                style: TextStyle(
                  fontSize: 15,
                  color: selectedAgent != null
                      ? (isDark ? Colors.white : Colors.black87)
                      : Colors.grey[600],
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  void _showAgentSelectionDialog() {
    final size = MediaQuery.of(context).size;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: size.height * 0.015),
              width: size.width * 0.12,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(size.width * 0.04),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Select Agent",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
              child: TextField(
                controller: agentSearchController,
                decoration: InputDecoration(
                  hintText: "Search agents...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: agentsList.isEmpty
                  ? const Center(child: Text("No agents available"))
                  : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                itemCount: _getFilteredAgents().length,
                itemBuilder: (context, index) {
                  final agent = _getFilteredAgents()[index];
                  final isSelected = selectedAgent == agent.name;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.fboColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.fboColor
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.fboColor.withOpacity(0.2),
                        child: Icon(Icons.person, color: AppColors.fboColor),
                      ),
                      title: Text(
                        agent.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text("${agent.district} • ${agent.distance}"),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: AppColors.fboColor)
                          : null,
                      onTap: () {
                        setState(() {
                          selectedAgent = agent.name;
                          agentSearchController.clear();
                        });
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<AgentInfo> _getFilteredAgents() {
    if (agentSearchController.text.isEmpty) {
      return agentsList;
    }
    return agentsList
        .where((agent) =>
        agent.name.toLowerCase().contains(agentSearchController.text.toLowerCase()))
        .toList();
  }

  void _showRejectionDialog(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning, color: Colors.red),
              ),
              const SizedBox(width: 12),
              const Text("Rejection Reason"),
            ],
          ),
          content: TextField(
            controller: reasonController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Enter reason for rejection",
              hintStyle: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey[600],
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade700, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade300),
              ),
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
            ),
            cursorColor: Colors.red.shade700,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                String reason = reasonController.text.trim();
                if (reason.isNotEmpty) {
                  Navigator.pop(context);
                  widget.onReject(reason);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter a reason"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    amountController.dispose();
    agentSearchController.dispose();
    super.dispose();
  }
}

class AgentInfo {
  final String name;
  final String district;
  final String distance;

  AgentInfo({
    required this.name,
    required this.district,
    required this.distance,
  });

  factory AgentInfo.fromJson(Map<String, dynamic> json) {
    return AgentInfo(
      name: json['name'] ?? '',
      district: json['district'] ?? '',
      distance: json['distance'] ?? '',
    );
  }

  @override
  String toString() => "$name ($district - $distance)";
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Document View'),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
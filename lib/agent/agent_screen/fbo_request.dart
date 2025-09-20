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
  final TextEditingController amountController = TextEditingController();
  TextEditingController agentSearchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  List<AgentInfo> agentsList = [];
  String? selectedAgent;
  List<String> dummyAgents = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    futureFboRequests = fetchFboRequests();
    if (fboRequests.isNotEmpty) {
      fetchNearestAgents(fboRequests[0].address); // preload with first FBO
    }
  }

  Future<void> fetchNearestAgents(String address) async {
    print("🌍 fetchNearestAgents called with address: $address");

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

      print("📤 Request Body: ${jsonEncode({"origin": address})}");
      print("📥 Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final List<dynamic> rawAgents = data['data'];

          setState(() {
            agentsList = rawAgents.map((e) => AgentInfo.fromJson(e)).toList();
          });

          print("✅ Agents loaded: $agentsList");
        } else {
          print("⚠️ Unexpected API status: ${data['status']}");
        }
      } else {
        print("❌ Failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Exception: $e");
    }
  }

  void _showRejectionDialog(BuildContext context, int fboId) {
    final TextEditingController reasonController = TextEditingController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Rejection Reason"),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Enter reason for rejection",
              hintStyle:
                  TextStyle(color: isDark ? Colors.white60 : Colors.grey[600]),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red.shade700, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red.shade300),
              ),
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
                foregroundColor: Colors.white, // Button text color
              ),
              onPressed: () {
                String reason = reasonController.text.trim();
                if (reason.isNotEmpty) {
                  Navigator.pop(context);
                  handleStatusUpdate(fboId, "rejected", reason: reason);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter a reason")),
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

  // void handleStatusUpdate(int fboId, String status, {String? reason}) {
  //   // You can print or send the reason to your backend when available
  //   print("Status: $status for FBO $fboId");
  //   if (reason != null) {
  //     print("Rejection Reason: $reason");
  //   }
  // }

  void handleStatusUpdate(
    int id,
    String status, {
    String? reason,
    String? agent,
    String? amount,
  }) async {
    // ✅ Validate agent and amount only when approving
    if (status == "approved") {
      if (agent == null || agent.isEmpty || amount == null || amount.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Please select an agent and enter amount")),
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
      selectedAgent = null;
      amountController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'FBO ${status == "approved" ? "approved" : "rejected"} successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FBO Login Requests', style: TextStyle(
          color: Colors.white,
        ),),
        backgroundColor: AppColors.secondaryColor,
      ),
      body: FutureBuilder<List<Fbo>>(
        future: futureFboRequests,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
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
              itemCount: fboRequests.length,
              itemBuilder: (context, index) {
                final fbo = fboRequests[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fbo.restaurantName,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Owner: ${fbo.fullName}',
                            style: const TextStyle(fontSize: 16)),
                        Text('Status: ${fbo.status}',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.orange)),
                        const SizedBox(height: 10),
                        if (fbo.licenseUrl.isNotEmpty ||
                            fbo.restaurantUrl.isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (fbo.licenseUrl.isNotEmpty)
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FullScreenImage(
                                              imageUrl: fbo.licenseUrl),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Image.network(
                                        fbo.licenseUrl,
                                        height: 150,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.error,
                                                    size: 50,
                                                    color: Colors.red),
                                      ),
                                    ),
                                  ),
                                ),
                              if (fbo.restaurantUrl.isNotEmpty)
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FullScreenImage(
                                              imageUrl: fbo.restaurantUrl),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Image.network(
                                        fbo.restaurantUrl,
                                        height: 150,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.error,
                                                    size: 50,
                                                    color: Colors.red),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        const SizedBox(height: 10),
                        Text('📞 Contact: ${fbo.contactNumber}',
                            style: const TextStyle(fontSize: 14)),
                        Text('📧 Email: ${fbo.email}',
                            style: const TextStyle(fontSize: 14)),
                        Text('🏠 Address: ${fbo.address}',
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 15),
                        if (fbo.branches.isNotEmpty) ...[
                          const Text(
                            "Branches Details:",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          ...fbo.branches.map((branch) => Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("🏢hotel name: ${branch.name}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    Text("📍Branch Address: ${branch.address}",
                                        style: const TextStyle(fontSize: 14)),
                                    Text("🧾 FSSAI No: ${branch.fssaiNo}",
                                        style: const TextStyle(fontSize: 14)),
                                    const SizedBox(height: 5),
                                    if (branch.license.isNotEmpty)
                                      GestureDetector(
                                        onTap: () {
                                          // Navigate to full-screen image view
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  FullScreenImage(
                                                      imageUrl: branch.license),
                                            ),
                                          );
                                        },
                                        child: Image.network(
                                          branch.license,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(Icons.broken_image,
                                                      size: 40,
                                                      color: Colors.red),
                                        ),
                                      ),
                                    const Divider(thickness: 1),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 10),
                        _buildAmountField(),
                        const SizedBox(height: 10),
                        _buildAgentSearchField(fbo.address),
                        const SizedBox(height: 15),
                        isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.secondaryColor),
                                    onPressed: () => handleStatusUpdate(
                                      fbo.id,
                                      "approved",
                                      agent: selectedAgent,
                                      amount: amountController.text.trim(),
                                    ),
                                    child: const Text("Approve",
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    onPressed: () =>
                                        _showRejectionDialog(context, fbo.id),
                                    child: const Text("Reject",
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              )
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildAmountField() {
    return TextField(
      controller: amountController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: "Enter Amount",
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildAgentSearchField(String address) {
    final ScrollController scrollController = ScrollController();

    return Autocomplete<AgentInfo>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return agentsList;
        }
        return agentsList.where((agent) => agent.name
            .toLowerCase()
            .contains(textEditingValue.text.toLowerCase()));
      },
      displayStringForOption: (AgentInfo option) =>
          "${option.name} (${option.district})",
      onSelected: (AgentInfo selection) {
        setState(() {
          selectedAgent = selection.name;
          agentSearchController.text = selection.name;
        });
      },
      fieldViewBuilder: (BuildContext context,
          TextEditingController textController,
          FocusNode focusNode,
          VoidCallback onFieldSubmitted) {
        agentSearchController = textController;

        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: "Assign Agent",
            border: OutlineInputBorder(),
          ),
          onTap: () async {
            if (agentsList.isEmpty) {
              await fetchNearestAgents(address);
              setState(() {
                // Force Autocomplete to rebuild
                textController.text = " "; // Trigger rebuild with space
                textController.clear(); // Then clear to see full list
              });
            }
            focusNode.requestFocus();
          },
          onChanged: (value) {
            setState(() {
              selectedAgent = value;
            });
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: const BoxConstraints(maxHeight: 250),
              child: Scrollbar(
                controller: scrollController,
                thumbVisibility: true,
                thickness: 6,
                radius: const Radius.circular(6),
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final AgentInfo option = options.elementAt(index);
                    return ListTile(
                      title: Text(option.name),
                      subtitle: Text("${option.district} • ${option.distance}"),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
      initialValue: TextEditingValue(text: selectedAgent ?? ''),
    );
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

// Define the FullScreenImage widget
class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Full Screen Image')),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}

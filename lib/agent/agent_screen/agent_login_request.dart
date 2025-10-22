import 'dart:convert';

import 'package:areg_app/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../agent_service/agent_pendng_login.dart';

class AgentLoginRequest extends StatefulWidget {
  const AgentLoginRequest({super.key});

  @override
  State<AgentLoginRequest> createState() => _AgentLoginRequestState();
}

class _AgentLoginRequestState extends State<AgentLoginRequest> {
  late Future<List<NewAgent>> futureAgents;
  Map<int, String?> loadingStates = {}; // Track loading state per agent

  @override
  void initState() {
    super.initState();
    futureAgents = fetchPendingAgents();
  }

  Future<void> approveOrRejectAgent({
    required int id,
    required String status,
  }) async {
    final url = ApiConfig.vendorApproval(id);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    // Set loading state
    setState(() {
      loadingStates[id] = status;
    });

    print("📤 Sending Approval Request...");
    print("📍 URL: $url");
    print("📦 Request Body: ${jsonEncode({"status": status})}");
    print("🔐 Token: $token");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"status": status}),
      );

      print("📥 Response Status: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        print("✅ Agent $status Success: ${res['message']}");

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Agent successfully $status')),
        );

        // Reload pending agents
        setState(() {
          futureAgents = fetchPendingAgents();
          loadingStates.remove(id);
        });
      } else {
        print("❌ Failed to $status agent: ${response.body}");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to $status agent")),
        );
        setState(() {
          loadingStates.remove(id);
        });
      }
    } catch (e) {
      print("❌ Exception during $status: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
      setState(() {
        loadingStates.remove(id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pending Agent Requests",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.fboColor,
      ),
      body: FutureBuilder<List<NewAgent>>(
        future: futureAgents,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text("Failed to load agent data"));
          } else if (snapshot.data!.isEmpty) {
            return const Center(child: Text("No pending agents"));
          }

          final agents = snapshot.data!;
          return ListView.builder(
            itemCount: agents.length,
            itemBuilder: (context, index) {
              final agent = agents[index];
              final isLoading = loadingStates[agent.id] != null;
              final loadingStatus = loadingStates[agent.id];

              return Card(
                margin: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: agent.profile != null
                                ? NetworkImage(agent.profile!)
                                : null,
                            child: agent.profile == null
                                ? const Icon(Icons.person, size: 30)
                                : null,
                            radius: 30,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(agent.fullName ?? 'N/A',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                Text(agent.email ?? 'N/A',
                                    style: const TextStyle(color: Colors.grey)),
                                Text("📞 ${agent.contactNumber ?? 'N/A'}"),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Text("Address: ${agent.address ?? 'N/A'}"),
                      Text("License Number: ${agent.licenseNumber ?? 'N/A'}"),
                      Text("DOB: ${agent.dob ?? 'N/A'} | Age: ${agent.age ?? 'N/A'}"),
                      Text("Gender: ${agent.gender ?? 'N/A'}"),
                      Text("Pincode: ${agent.pincode ?? 'N/A'}"),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            label: Text(agent.status ?? 'unknown',
                                style: const TextStyle(color: Colors.white)),
                            backgroundColor: (agent.status == 'pending' || agent.status == null)
                                ? Colors.orange
                                : Colors.green,
                          ),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () => approveOrRejectAgent(
                                    id: agent.id ?? 0, status: "approved"),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green),
                                child: isLoading && loadingStatus == "approved"
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                                    : const Text(
                                  "Approve",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () => approveOrRejectAgent(
                                    id: agent.id ?? 0, status: "rejected"),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                                child: isLoading && loadingStatus == "rejected"
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                                    : const Text("Reject",
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class NewAgent {
  final int? id;
  final String? fullName;
  final String? email;
  final String? address;
  final String? contactNumber;
  final String? profile;
  final String? dob;
  final String? age;
  final String? gender;
  final String? licenseNumber;
  final String? pincode;
  final String? status;

  NewAgent({
    this.id,
    this.fullName,
    this.email,
    this.address,
    this.contactNumber,
    this.profile,
    this.dob,
    this.age,
    this.gender,
    this.licenseNumber,
    this.pincode,
    this.status,
  });

  factory NewAgent.fromJson(Map<String, dynamic> json) {
    return NewAgent(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      address: json['address'],
      contactNumber: json['contact_number'],
      profile: json['profile'],
      dob: json['dob'],
      age: json['age'],
      gender: json['gender'],
      licenseNumber: json['license_number'],
      pincode: json['pincode'],
      status: json['status'],
    );
  }
}

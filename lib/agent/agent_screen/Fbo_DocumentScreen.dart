import 'package:areg_app/common/app_colors.dart';
import 'package:flutter/material.dart';
import '../../common/shimmer_loader.dart';
import '../agent_service/fbo_document_service.dart';
import '../common/agent_appbar.dart';

class FboDocumentScreen extends StatefulWidget {
  const FboDocumentScreen({super.key});

  @override
  _FboDocumentScreenState createState() => _FboDocumentScreenState();
}

class _FboDocumentScreenState extends State<FboDocumentScreen> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  // ✅ Track progress separately for each document type
  Map<String, double> downloadProgress = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  /// ✅ Load users from API
  Future<void> _loadUsers() async {
    List<Map<String, dynamic>> fetchedUsers = await FboDocumentService.fetchUsers();
    setState(() {
      users = fetchedUsers;
      isLoading = false;
    });
  }

  /// ✅ Start PDF download with progress
  void _startDownload(int userId, String type) {
    String key = "$userId-$type"; // Unique key for each document type
    setState(() {
      downloadProgress[key] = 0.0; // Initialize progress
    });

    FboDocumentService.downloadPdf(
      userId: userId,
      type: type,
      onProgress: (progress) {
        setState(() {
          downloadProgress[key] = progress;
        });
      },
      onComplete: (errorMessage) {
        if (errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage, style: const TextStyle(color: Colors.red))),
          );
        }
        setState(() {
          downloadProgress.remove(key); // Remove progress after completion
        });
      },
    );
  }
  /// ✅ Build Shimmer UI for Loading State
  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 6, // ✅ Show 6 shimmer placeholders
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerLoader(height: 20, width: 100), // ✅ Fake Order ID
                const SizedBox(height: 10),
                const ShimmerLoader(height: 14), // ✅ Fake Name
                const ShimmerLoader(height: 14, width: 150), // ✅ Fake Address
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Expanded(child: ShimmerLoader(height: 40)), // ✅ Fake PDF Button
                    const SizedBox(width: 10),
                    const Expanded(child: ShimmerLoader(height: 40)), // ✅ Fake Excel Button
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AgentAppBar(title: 'FBO Documents'),
      body: isLoading
          ? _buildShimmerList()
          : users.isEmpty
          ? const Center(child: Text("No users found."))
          : ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          int userId = user["id"];

          return Card(
            elevation: 6,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user["restaurant_name"] ?? "N/A",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user["address"] ?? "N/A",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Download Buttons
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      downloadProgress.containsKey("$userId-selfdeclaration")
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : SizedBox(
                        width: 150, // 👈 Fixed width
                        child: ElevatedButton.icon(
                          onPressed: () => _startDownload(userId, "selfdeclaration"),
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text("Self Declaration", style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:  AppColors.secondaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      downloadProgress.containsKey("$userId-contract")
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : SizedBox(
                        width: 150, // 👈 Same fixed width
                        child: ElevatedButton.icon(
                          onPressed: () => _startDownload(userId, "contract"),
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text("Contract", style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),
          );
        },
      ),
    );

  }
}

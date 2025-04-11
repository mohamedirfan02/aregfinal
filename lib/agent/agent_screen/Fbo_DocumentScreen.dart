import 'package:flutter/material.dart';
import '../../common/shimmer_loader.dart';
import '../agent_service/fbo_document_service.dart';

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
      appBar: AppBar(title: const Text("FBO Users")),
      body: isLoading
          ? _buildShimmerList() // ✅ Show Shimmer While Loading
          : users.isEmpty
          ? const Center(child: Text("No users found."))
          : ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          int userId = user["id"];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text(
                user["restaurant_name"] ?? "N/A",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(user["address"] ?? "N/A"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ Self Declaration PDF Button with Progress Indicator
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                        onPressed: () => _startDownload(userId, "selfdeclaration"),
                      ),
                      if (downloadProgress.containsKey("$userId-selfdeclaration"))
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(value: downloadProgress["$userId-selfdeclaration"]),
                        ),
                    ],
                  ),

                  // ✅ Contract PDF Button with Progress Indicator
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.description, color: Colors.blue),
                        onPressed: () => _startDownload(userId, "contract"),
                      ),
                      if (downloadProgress.containsKey("$userId-contract"))
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(value: downloadProgress["$userId-contract"]),
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

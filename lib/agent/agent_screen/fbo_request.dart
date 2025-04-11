import 'package:flutter/material.dart';
import '../../models/restaurant_model.dart';
import '../agent_service/fbo_login_request_service.dart';

class FboLoginRequest extends StatelessWidget {
  const FboLoginRequest({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FBO Login Requests')),
      body: FutureBuilder<List<Fbo>>(
        future: fetchFboRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No FBO requests found.'));
          } else {
            final fboRequests = snapshot.data!;
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
                        // ✅ Restaurant Name
                        Text(fbo.restaurantName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                        // ✅ Owner and Status
                        Text('Owner: ${fbo.fullName}', style: const TextStyle(fontSize: 16)),
                        Text('Status: ${fbo.status}', style: const TextStyle(fontSize: 16, color: Colors.orange)),

                        const SizedBox(height: 10),

                        // ✅ Display License Image
                        if (fbo.licenseUrl.isNotEmpty)
                          Image.network(fbo.licenseUrl, height: 150, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.error, size: 50, color: Colors.red);
                          }),

                        const SizedBox(height: 10),

                        // ✅ Display Restaurant Image
                        if (fbo.restaurantUrl.isNotEmpty)
                          Image.network(fbo.restaurantUrl, height: 150, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.error, size: 50, color: Colors.red);
                          }),

                        const SizedBox(height: 10),

                        // ✅ Contact Details
                        Text('📞 Contact: ${fbo.contactNumber}', style: const TextStyle(fontSize: 14)),
                        Text('📧 Email: ${fbo.email}', style: const TextStyle(fontSize: 14)),
                        Text('🏠 Address: ${fbo.address}', style: const TextStyle(fontSize: 14)),

                        const SizedBox(height: 15),

                        // ✅ Approve & Reject Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // ✅ Approve Button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: () => updateFboStatus(context, fbo.id, "approved"),
                              child: const Text("Approve"),
                            ),

                            // ✅ Reject Button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () => updateFboStatus(context, fbo.id, "rejected"),
                              child: const Text("Reject"),
                            ),
                          ],
                        ),
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
}

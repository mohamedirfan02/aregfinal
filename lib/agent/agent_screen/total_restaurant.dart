import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../agent_service/total_restaurant_api.dart';

class RestaurantList extends StatefulWidget {
  const RestaurantList({super.key});

  @override
  State<RestaurantList> createState() => _RestaurantListState();
}

class _RestaurantListState extends State<RestaurantList> {
  late Future<List<Restaurant>> futureRestaurants;
  List<Restaurant> allRestaurants = [];
  List<Restaurant> filteredRestaurants = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    futureRestaurants = fetchRestaurants();
    _searchController.addListener(_filterRestaurants);
  }

  void _filterRestaurants() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredRestaurants = allRestaurants.where((r) {
        return r.restaurantName.toLowerCase().contains(query) ||
            r.address.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  Future<void> sendOilRequest(int id) async {
    final url = Uri.parse(ApiConfig.requestRegisteredFbo);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    try {
      print("📤 Sending request for FBO ID: $id");
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'fbo_id': id}),
      );

      if (response.statusCode == 200) {
        print("✅ Oil request sent successfully");
      } else {
        print("❌ Failed to send request: ${response.statusCode} → ${response.body}");
      }
    } catch (e) {
      print("⚠️ Error sending request: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : const Color(0xFF006D04),
        centerTitle: true,
        elevation: 4,
        title: Text(
          'Restaurants List',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.white, // Keep white for consistency
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: FutureBuilder<List<Restaurant>>(
        future: futureRestaurants,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('❌ Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No restaurants found'));
          } else {
            allRestaurants = snapshot.data!;
            filteredRestaurants = _searchController.text.isEmpty
                ? allRestaurants
                : allRestaurants.where((r) {
              final query = _searchController.text.toLowerCase();
              return r.restaurantName.toLowerCase().contains(query) ||
                  r.address.toLowerCase().contains(query);
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Search by restaurant name or address...',
                      hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                      prefixIcon: Icon(Icons.search, color: isDark ? Colors.white70 : Colors.black54),
                      filled: true,
                      fillColor: isDark ? Colors.grey.shade900 : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: const Color(0xFF006D04)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: const Color(0xFF006D04)),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredRestaurants.length,
                    itemBuilder: (context, index) {
                      final r = filteredRestaurants[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade900 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.black54 : Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.restaurantName,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF006D04),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...[
                                "Owner: ${r.fullName}",
                                "Category: ${r.category}",
                                "agreed price: ${r.agreedPrice}",
                                "Status: ${r.status}",
                                "Email: ${r.email}",
                                "Bank: ${r.bankName}",
                                "Account No: ${r.accountNo}",
                                "Contact: ${r.countryCode} ${r.contactNumber}",
                                "License #: ${r.licenseNumber}",
                                "Address: ${r.address}",
                              ].map((text) => Text(
                                text,
                                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                              )),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("License Image", style: TextStyle(fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 6),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => FullScreenImage(imageUrl: r.licenseUrl),
                                              ),
                                            );
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.network(
                                              r.licenseUrl,
                                              height: 120,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                height: 120,
                                                color: Colors.grey[200],
                                                child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Restaurant Image", style: TextStyle(fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 6),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => FullScreenImage(imageUrl: r.restaurantUrl),
                                              ),
                                            );
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.network(
                                              r.restaurantUrl,
                                              height: 120,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                height: 120,
                                                color: Colors.grey[200],
                                                child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () async {
                                  await sendOilRequest(r.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('🛢️ Oil request sent to ${r.restaurantName}')),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF006D04),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text(
                                  'Send Oil Request',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  const FullScreenImage({required this.imageUrl, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: InteractiveViewer(
            child: Image.network(
              imageUrl,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 100),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../agent_service/total_restaurant_api.dart';

class RestaurantList extends StatefulWidget {
  const RestaurantList({super.key});

  @override
  State<RestaurantList> createState() => _RestaurantListState();
}

class _RestaurantListState extends State<RestaurantList> {
  late Future<List<Restaurant>> futureRestaurants;

  @override
  void initState() {
    super.initState();
    futureRestaurants = fetchRestaurants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text('Restaurants'),
        backgroundColor: Colors.teal,
        centerTitle: true,
        elevation: 4,
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
            final restaurants = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: restaurants.length,
              itemBuilder: (context, index) {
                final r = restaurants[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
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
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text("👤 Owner: ${r.fullName}"),
                        Text("🍴 Category: ${r.category}"),
                        Text("✅ Status: ${r.status}"),
                        Text("📧 Email: ${r.email}"),
                        Text("📱 Contact: ${r.countryCode} ${r.contactNumber}"),
                        Text("🔖 License #: ${r.licenseNumber}"),
                        Text("📍 Address: ${r.address}"),
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

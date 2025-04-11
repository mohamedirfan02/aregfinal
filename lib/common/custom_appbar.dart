import 'package:flutter/material.dart';
import '../fbo_services/appbar_api.dart';
import '../views/dashboard/FBO_cartpage.dart';
import '../views/screens/user_notification.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  String? restaurantName;
  String? restaurantImage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurantDetails();
  }

  Future<void> _loadRestaurantDetails() async {
    final apiService = ApiService();
    final restaurantData = await apiService.fetchRestaurantDetails();

    if (restaurantData != null) {
      setState(() {
        restaurantName = restaurantData['retaurant_name']; // ❌ API Typo: Ensure Backend Fixes It
        restaurantImage = restaurantData['restaurant_image'];
        isLoading = false;
      });
    } else {
      setState(() {
        restaurantName = "Unknown";
        restaurantImage = null;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Color(0xFF006D04),
      elevation: 0,
      title: isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (restaurantImage != null)
                ClipOval(
                  child: Image.network(
                    restaurantImage!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported),
                  ),
                )
              else
                const Icon(Icons.restaurant, size: 32),
              const SizedBox(width: 5),
              Text(
                restaurantName ?? "Loading...",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Image.asset("assets/icon/cart.png", width: 24, height: 24),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FboAcknowledgmentScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Image.asset("assets/icon/bell.png", width: 24, height: 24),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FboNotificationScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

}

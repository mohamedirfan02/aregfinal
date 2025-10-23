import 'dart:async';
import 'dart:convert';
import 'package:areg_app/config/api_config.dart';
import 'package:areg_app/core/logger/app_logger.dart';
import 'package:areg_app/secrets/env.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      placeId: json['place_id'],
      description: json['description'],
      mainText: json['structured_formatting']['main_text'],
      secondaryText: json['structured_formatting']['secondary_text'] ?? '',
    );
  }
}

class OrderLocation {
  final int orderId;
  final String restaurantName;
  final String pickupLocation;
  final String type;
  final String quantity;
  final String amount;
  final String userName;
  final String userContact;
  final String timeline;
  final LatLng? coordinates;

  OrderLocation({
    required this.orderId,
    required this.restaurantName,
    required this.pickupLocation,
    required this.type,
    required this.quantity,
    required this.amount,
    required this.userName,
    required this.userContact,
    required this.timeline,
    this.coordinates,
  });
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  Location _locationController = Location();

  // Default location (Hosur, Tamil Nadu)
  static const LatLng _defaultLocation = LatLng(11.9416, 79.8083);

  LatLng? _currentP;
  String? _errorMessage;
  bool _isLoading = true;

  // Orders data
  List<OrderLocation> _orderLocations = [];
  Map<PolylineId, Polyline> _polylines = {};
  int? _selectedOrderId;

  // Search related variables
  final TextEditingController _searchController = TextEditingController();
  List<PlaceSuggestion> _suggestions = [];
  bool _isSearching = false;
  Timer? _debounceTimer;
  final FocusNode _searchFocusNode = FocusNode();
  StreamSubscription<LocationData>? _locationSubscription;

  // Bottom sheet controller
  bool _showOrdersList = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  void _closeOrdersList() {
    _animationController.reverse(); // Slide down
    setState(() {
      _showOrdersList = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      await getLocationUpdate();
      await _fetchAssignedOrders();

      await Future.delayed(Duration(seconds: 1));

      setState(() {
        _isLoading = false;
        if (_currentP == null) {
          _currentP = _defaultLocation;
        }
      });

      if (_currentP != null) {
        _cameraToPosition(_currentP!);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing map: $e';
        _isLoading = false;
        _currentP = _defaultLocation;
      });
      print('Map initialization error: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    _locationSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? _buildLoadingScreen()
          : _errorMessage != null
          ? _buildErrorScreen()
          : Stack(
        children: [
          // Map widget
          GoogleMap(
            onMapCreated: (controller) {
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
              }
            },
            initialCameraPosition: CameraPosition(
              target: _currentP ?? _defaultLocation,
              zoom: 13,
            ),
            markers: _buildMarkers(),
            polylines: Set<Polyline>.of(_polylines.values),
            onTap: (_) {
              _searchFocusNode.unfocus();
              setState(() {
                _suggestions.clear();
              });
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
            style: _getMapStyle(),
          ),
          // Top gradient overlay
          _buildTopGradient(),
          // Search overlay
          _buildSearchOverlay(),
          // Stats card
          _buildStatsCard(),
          // Action buttons
          _buildActionButtons(),
          // Orders list button
          _buildOrdersListButton(),
          // Loading indicator for search
          if (_isSearching) _buildSearchLoader(),
          // Bottom orders list
          _buildOrdersList(),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6A9600), Color(0xFFC3E029)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC3E029)),
              ),
            ),
            SizedBox(height: 24),
            Text(
              "Loading your deliveries...",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, size: 64, color: Colors.red),
          ),
          SizedBox(height: 24),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _errorMessage = null;
                _isLoading = true;
              });
              _initializeMap();
            },
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFC3E029),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMapStyle() {
    // Premium map style (subtle and clean)
    return '''
    [
      {
        "featureType": "poi",
        "elementType": "labels",
        "stylers": [{"visibility": "off"}]
      }
    ]
    ''';
  }

  Widget _buildTopGradient() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.0),
            ],
          ),
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};

    // Current location marker with custom icon effect
    if (_currentP != null) {
      markers.add(
        Marker(
          markerId: MarkerId("_currentLocation"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          position: _currentP!,
          infoWindow: InfoWindow(
            title: "📍 You are here",
            snippet: "Current location",
          ),
        ),
      );
    }

    // Order location markers with different colors based on oil type
    for (var order in _orderLocations) {
      if (order.coordinates != null) {
        markers.add(
          Marker(
            markerId: MarkerId("order_${order.orderId}"),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _getMarkerColor(order.type),
            ),
            position: order.coordinates!,
            infoWindow: InfoWindow(
              title: "🏪 ${order.restaurantName}",
              snippet: "${order.type} • ${order.quantity}KG",
            ),
            onTap: () => _onOrderMarkerTapped(order),
          ),
        );
      }
    }

    return markers;
  }

  double _getMarkerColor(String type) {
    switch (type.toLowerCase()) {
      case 'coconut oil':
        return BitmapDescriptor.hueGreen;
      case 'sunflower oil':
        return BitmapDescriptor.hueYellow;
      case 'palm oil':
        return BitmapDescriptor.hueOrange;
      case 'used cooking oil':
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueViolet;
    }
  }

  Widget _buildSearchOverlay() {
    return Positioned(
      top: 60,
      left: 16,
      right: 16,
      child: Column(
        children: [
          Hero(
            tag: 'search_bar',
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Search locations...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF6A9600), size: 24),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _suggestions.clear();
                        });
                      },
                    )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
            ),
          ),
          // Suggestions list
          if (_suggestions.isNotEmpty)
            Container(
              margin: EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  separatorBuilder: (context, index) => Divider(height: 1, indent: 56),
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    return ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF6A9600).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.location_on, color: Color(0xFF6A9600), size: 20),
                      ),
                      title: Text(
                        suggestion.mainText,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: Text(
                        suggestion.secondaryText,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      onTap: () => _onSuggestionTapped(suggestion),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Positioned(
      top: 140,
      left: 16,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delivery_dining, color: Color(0xFF6A9600), size: 20),
            SizedBox(width: 8),
            Text(
              '${_orderLocations.length} Deliveries',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
      bottom: _showOrdersList ? 420 : 100,
      right: 16,
      child: Column(
        children: [
          if (_selectedOrderId != null)
            Container(
              margin: EdgeInsets.only(bottom: 12),
              child: FloatingActionButton(
                heroTag: "clear_route",
                mini: true,
                onPressed: () {
                  setState(() {
                    _polylines.clear();
                    _selectedOrderId = null;
                  });
                },
                child: Icon(Icons.close, size: 20),
                backgroundColor: Colors.red.shade400,
                elevation: 4,
              ),
            ),
          FloatingActionButton(
            heroTag: "current_location",
            onPressed: () {
              if (_currentP != null) {
                _cameraToPosition(_currentP!);
              }
            },
            child: Icon(Icons.my_location),
            backgroundColor: Color(0xFF6A9600),
            elevation: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersListButton() {
    return Positioned(
      bottom: 30,
      left: 16,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showOrdersList = !_showOrdersList;
          });
          if (_showOrdersList) {
            _animationController.forward();
          } else {
            _animationController.reverse();
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A9600), Color(0xFFC3E029)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFC3E029).withOpacity(0.4),
                blurRadius: 15,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _showOrdersList ? Icons.expand_more : Icons.list,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                _showOrdersList ? 'Hide Orders' : 'View All Orders',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchLoader() {
    return Positioned(
      top: 200,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC3E029)),
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Positioned(
          bottom: -400 + (400 * _slideAnimation.value),
          left: 0,
          right: 0,
          child: Container(
            height: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Drag handle
                Container(
                  margin: EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Deliveries',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Color(0xFFC3E029).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_orderLocations.length}',
                              style: TextStyle(
                                color: Color(0xFFC3E029),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          GestureDetector(
                            onTap: _closeOrdersList,
                            child: Icon(Icons.close, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Orders list
                Expanded(
                  child: _orderLocations.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                        SizedBox(height: 16),
                        Text(
                          'No deliveries available',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _orderLocations.length,
                    itemBuilder: (context, index) {
                      final order = _orderLocations[index];
                      return _buildOrderCard(order);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(OrderLocation order) {
    Color typeColor = _getTypeColor(order.type);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onOrderMarkerTapped(order),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.store,
                        color: typeColor,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.restaurantName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Order #${order.orderId}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '₹${order.amount}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          Icons.opacity,
                          order.type,
                          typeColor,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          Icons.local_drink,
                          '${order.quantity}KG',
                          Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.pickupLocation,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.schedule, size: 16, color: Colors.orange.shade600),
                    SizedBox(width: 4),
                    Text(
                      order.timeline,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade600,
                        fontWeight: FontWeight.w600,
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

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: color),
        SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'coconut oil':
        return Colors.green.shade600;
      case 'sunflower oil':
        return Colors.amber.shade700;
      case 'palm oil':
        return Colors.orange.shade600;
      case 'used cooking oil':
        return Colors.red.shade600;
      default:
        return Color(0xFF6C63FF);
    }
  }

  Future<void> _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition newCameraPosition = CameraPosition(target: pos, zoom: 15);
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(newCameraPosition),
    );
  }

  Future<void> getLocationUpdate() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) {
        print('Location service not enabled');
        return;
      }
    }

    permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        print('Location permission not granted');
        return;
      }
    }

    try {
      LocationData locationData = await _locationController.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        setState(() {
          _currentP = LatLng(
            locationData.latitude!,
            locationData.longitude!,
          );
        });
        AppLoggerHelper.logInfo('Initial location: $_currentP');
      }
    } catch (e) {
      print('Error getting initial location: $e');
    }

    _locationSubscription?.cancel();

    _locationSubscription = _locationController.onLocationChanged.listen((
        LocationData currentLocation,
        ) {
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        setState(() {
          _currentP = LatLng(
            currentLocation.latitude!,
            currentLocation.longitude!,
          );
        });
        AppLoggerHelper.logInfo('Updated location: $_currentP');
      }
    });
  }

  Future<void> _fetchAssignedOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? vendorIdString = prefs.getString('vendor_id');
    int? vendorId = vendorIdString != null ? int.tryParse(vendorIdString) : null;

    if (token == null || vendorId == null) {
      debugPrint("❌ No token or vendor ID found. User must log in again.");
      return;
    }
    final url = ApiConfig.getVendorAssignedSale(vendorId.toString());
    debugPrint("Fetching data from: $url");

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("Response Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData["status"] == "success") {
          List<dynamic> approvedData = jsonData["approvedData"] ?? [];

          List<OrderLocation> orders = [];
          for (var order in approvedData) {
            String pickupLocation = order["pickup_location"] ?? "";
            LatLng? coordinates = await _getCoordinatesFromAddress(pickupLocation);

            orders.add(OrderLocation(
              orderId: order["order_id"],
              restaurantName: order["restaurant_name"] ?? "Unknown Restaurant",
              pickupLocation: pickupLocation,
              type: order["type"] ?? "",
              quantity: order["quantity"] ?? "",
              amount: order["amount"] ?? "",
              userName: order["user_name"] ?? "",
              userContact: order["user_contact"] ?? "",
              timeline: order["timeline"] ?? "",
              coordinates: coordinates,
            ));
          }

          setState(() {
            _orderLocations = orders;
          });

          debugPrint("✅ Loaded ${orders.length} approved orders on map");
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching orders: $e");
    }
  }

  Future<LatLng?> _getCoordinatesFromAddress(String address) async {
    if (address.isEmpty) return null;

    try {
      final String url =
          'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=${Env.apiKey}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
    } catch (e) {
      debugPrint('Error geocoding address: $e');
    }
    return null;
  }

  Future<void> _onOrderMarkerTapped(OrderLocation order) async {
    if (_currentP == null || order.coordinates == null) return;

    setState(() {
      _selectedOrderId = order.orderId;
    });

    _showOrderDetailsSheet(order);
    await _drawRoute(_currentP!, order.coordinates!);
  }

  void _showOrderDetailsSheet(OrderLocation order) {
    Color typeColor = _getTypeColor(order.type);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFC3E029), Color(0xFF8BC34A)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.restaurant, color: Colors.white, size: 28),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.restaurantName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Order #${order.orderId}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            // Order details grid
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          Icons.opacity,
                          'Oil Type',
                          order.type,
                          typeColor,
                        ),
                      ),
                      Container(width: 1, height: 50, color: Colors.grey.shade300),
                      Expanded(
                        child: _buildDetailItem(
                          Icons.local_drink,
                          'Quantity',
                          '${order.quantity} KG',
                          Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 24),
                  _buildDetailRow(
                    Icons.currency_rupee,
                    'Amount',
                    '₹${order.amount}',
                    Colors.green.shade600,
                  ),
                  SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.schedule,
                    'Timeline',
                    order.timeline,
                    Colors.orange.shade600,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Customer details
            Text(
              'Customer Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue.shade700, size: 20),
                      SizedBox(width: 12),
                      Text(
                        order.userName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.phone, color: Colors.blue.shade700, size: 20),
                      SizedBox(width: 12),
                      Text(
                        order.userContact,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Location
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, color: Colors.red.shade400, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    order.pickupLocation,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _polylines.clear();
                        _selectedOrderId = null;
                      });
                    },
                    icon: Icon(Icons.close),
                    label: Text('Close'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      if (order.coordinates != null) {
                        _cameraToPosition(order.coordinates!);
                      }
                    },
                    icon: Icon(Icons.navigation),
                    label: Text('Navigate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF8BC34A),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Future<void> _drawRoute(LatLng origin, LatLng destination) async {
    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: Env.apiKey,
      request: PolylineRequest(
        origin: PointLatLng(origin.latitude, origin.longitude),
        destination: PointLatLng(destination.latitude, destination.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      List<LatLng> routeCoordinates = result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      PolylineId id = PolylineId("route");
      Polyline polyline = Polyline(
        polylineId: id,
        color: Color(0xFF8BC34A),
        points: routeCoordinates,
        width: 5,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      );

      setState(() {
        _polylines[id] = polyline;
      });

      _adjustCameraToRoute(origin, destination);
    } else {
      debugPrint("❌ Route error: ${result.errorMessage}");
    }
  }

  Future<void> _adjustCameraToRoute(LatLng origin, LatLng destination) async {
    final GoogleMapController controller = await _mapController.future;

    double south = origin.latitude < destination.latitude
        ? origin.latitude
        : destination.latitude;
    double north = origin.latitude > destination.latitude
        ? origin.latitude
        : destination.latitude;
    double west = origin.longitude < destination.longitude
        ? origin.longitude
        : destination.longitude;
    double east = origin.longitude > destination.longitude
        ? origin.longitude
        : destination.longitude;

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _searchPlaces(query);
      } else {
        setState(() {
          _suggestions.clear();
        });
      }
    });
  }

  Future<void> _searchPlaces(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final String url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=${Env.apiKey}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _suggestions = (data['predictions'] as List)
                .map((prediction) => PlaceSuggestion.fromJson(prediction))
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error searching places: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _onSuggestionTapped(PlaceSuggestion suggestion) async {
    _searchController.text = suggestion.mainText;
    _searchFocusNode.unfocus();
    setState(() {
      _suggestions.clear();
    });

    try {
      final String url =
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=${suggestion.placeId}&key=${Env.apiKey}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          final LatLng placeLocation = LatLng(location['lat'], location['lng']);

          await _cameraToPosition(placeLocation);
        }
      }
    } catch (e) {
      print('Error getting place details: $e');
    }
  }
}
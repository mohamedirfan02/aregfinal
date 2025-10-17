import 'dart:convert';
import 'package:areg_app/common/app_colors.dart';
import 'package:areg_app/config/api_config.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../fbo_services/oil_request_service.dart';
import '../../services/notification_service.dart';

class OilPlacedScreen extends StatefulWidget {
  const OilPlacedScreen({super.key});

  @override
  _OilPlacedScreenState createState() => _OilPlacedScreenState();
}

class _OilPlacedScreenState extends State<OilPlacedScreen> {
  final NotificationService _notificationService = NotificationService();
  String? selectedOilType;
  String selectedPaymentMethod = "online";
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool isCashSelected = false;
  String selectedAddress = '';
  String? quantityError;
  double _unitPrice = 0.0;
  String? Token;
  bool isSubmitting = false;
  List<String> addressOptions = [];

  @override
  void initState() {
    super.initState();
    _notificationService.init();
    Token = "your_dynamic_token_here";
    _fetchAddresses();
  }

  Future<void> _fetchUnitPrice(String quantity) async {
    if (Token == null || quantity.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    final url = Uri.parse(ApiConfig.getUnitPrice);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $Token',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'id': userId,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final price = double.tryParse(data['price'].toString());

        setState(() {
          _unitPrice = price ?? 0.0;
        });
      } else {
        setState(() {
          _unitPrice = 0.0;
        });
      }
    } catch (e) {
      setState(() {
        _unitPrice = 0.0;
      });
    }
  }

  Future<void> _fetchAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    if (userId == null) {
      print("❌ No user ID found in preferences.");
      return;
    }

    final url = Uri.parse(ApiConfig.getFboAddress(userId));

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        final Map<String, dynamic> addressJson = jsonData['data'][0];
        final AddressResponse addressData =
        AddressResponse.fromJson(addressJson);

        setState(() {
          addressOptions = [
            addressData.restaurantAddress,
            ...addressData.branchAddresses,
          ];
        });
      }
    } catch (e) {
      print("Error fetching addresses: $e");
    }
  }

  Future<void> _submitOilRequest() async {
    if (selectedOilType == null || quantityController.text.isEmpty) {
      _showAwesomeDialog(
          'Error', 'Please fill in all fields.', DialogType.error);
      return;
    }

    final quantity = double.tryParse(quantityController.text);
    if (quantity == null) {
      _showAwesomeDialog(
          'Error', 'Please enter a valid quantity.', DialogType.error);
      return;
    }

    if (quantity < 5) {
      _showAwesomeDialog('Error',
          'Minimum quantity allowed is 5 KG. Please enter at least 5 KG.', DialogType.error);
      return;
    }

    if (selectedAddress.isEmpty) {
      _showAwesomeDialog(
          'Error', 'Please select a pickup address.', DialogType.error);
      return;
    }

    if (isCashSelected && reasonController.text.trim().isEmpty) {
      _showAwesomeDialog(
          'Error', 'Please provide a reason for cash request.', DialogType.error);
      return;
    }

    setState(() => isSubmitting = true);

    final response = await OilRequestService.submitOilRequest(
      type: selectedOilType!,
      quantity: quantityController.text,
      paymentMethod: isCashSelected ? "cash" : "online",
      reason: isCashSelected ? reasonController.text : null,
      dateRange: null,
      address: selectedAddress,
      remarks: remarksController.text,
      counter_unit_price: null,
    );

    setState(() => isSubmitting = false);

    if (response != null && response.containsKey('error')) {
      _showAwesomeDialog('Error', response['error'], DialogType.error);
    } else {
      await _notificationService.showNotification(
        id: 1,
        title: "Oil Request Placed",
        body:
        "Your request for $selectedOilType has been submitted successfully.",
      );
      Navigator.pop(context);
    }
  }

  void _showAwesomeDialog(String title, String message, DialogType type) {
    AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.scale,
      title: title,
      desc: message,
      btnOkOnPress: () {},
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[850] : AppColors.fboColor,
        elevation: 0,
        title: const Text(
          'Request Oil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Oil Details Section
            _buildSectionHeader('Oil Details', Icons.local_drink),
            _buildOilTypeCard(isDark),
            _buildQuantityCard(isDark),

            const SizedBox(height: 20),

            // Pickup Location Section
            _buildSectionHeader('Pickup Location', Icons.location_on),
            _buildPickupLocationCard(isDark),

            const SizedBox(height: 20),

            // Payment & Pricing Section
            _buildSectionHeader('Payment & Pricing', Icons.payment),
            _buildPricingCard(isDark),
            _buildPaymentMethodCard(isDark),

            if (isCashSelected) _buildCashReasonCard(isDark),

            const SizedBox(height: 20),

            // Additional Information
            _buildSectionHeader('Additional Information', Icons.notes),
            _buildRemarksCard(isDark),

            const SizedBox(height: 30),

            // Submit Button
            _buildSubmitButton(isDark),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: AppColors.primaryColor, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOilTypeCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Type of Oil',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _showOilTypeBottomSheet(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedOilType != null
                      ? AppColors.primaryColor.withOpacity(0.5)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.opacity,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedOilType ?? 'Select oil type',
                      style: TextStyle(
                        fontSize: 16,
                        color: selectedOilType != null
                            ? (isDark ? Colors.white : Colors.black87)
                            : Colors.grey,
                        fontWeight: selectedOilType != null
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOilTypeBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final oilTypes = [
      "Used Cooking Oil",
      "Coconut Oil",
      "Sunflower Oil",
      "Palm Oil"
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Select Oil Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            ...oilTypes.map((type) => ListTile(
              leading: Icon(
                Icons.opacity,
                color: AppColors.primaryColor,
              ),
              title: Text(
                type,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              trailing: selectedOilType == type
                  ? Icon(Icons.check_circle, color: AppColors.primaryColor)
                  : null,
              onTap: () {
                setState(() {
                  selectedOilType = type;
                });
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quantity/Servings',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onChanged: (value) async {
              final kg = double.tryParse(value);
              setState(() {
                if (value.isEmpty) {
                  quantityError = null;
                  _unitPrice = 0.0;
                } else if (kg == null) {
                  quantityError = "Please enter a valid number";
                  _unitPrice = 0.0;
                } else if (kg < 5) {
                  quantityError = "Minimum quantity is 5 KG";
                  _unitPrice = 0.0;
                } else {
                  quantityError = null;
                }
              });

              if (kg != null && kg >= 5) {
                await _fetchUnitPrice(kg.toInt().toString());
              }
            },
            decoration: InputDecoration(
              hintText: 'e.g., 5 kg or 10 kg (Min: 5 KG)',
              hintStyle: TextStyle(color: Colors.grey),
              errorText: quantityError,
              prefixIcon: Icon(
                Icons.scale,
                color: AppColors.primaryColor,
              ),
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primaryColor.withOpacity(0.5),
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupLocationCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Select Location',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          if (addressOptions.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No addresses available',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...addressOptions.asMap().entries.map((entry) {
              int index = entry.key;
              String address = entry.value;
              bool isSelected = selectedAddress == address;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedAddress = address;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: index < addressOptions.length - 1 ? 12 : 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryColor
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryColor.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: isSelected
                              ? AppColors.primaryColor
                              : Colors.grey,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              index == 0 ? 'Restaurant Address' : 'Branch Address ${index}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              address,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: AppColors.primaryColor,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPricingCard(bool isDark) {
    double quantity = double.tryParse(quantityController.text) ?? 0.0;
    double totalAmount = quantity * _unitPrice;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rate per KG',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${_unitPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.withOpacity(0.3),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedPaymentMethod = "online";
                      isCashSelected = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: !isCashSelected
                          ? AppColors.primaryColor.withOpacity(0.1)
                          : (isDark ? Colors.grey[800] : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !isCashSelected
                            ? AppColors.primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: !isCashSelected
                              ? AppColors.primaryColor
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Online',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: !isCashSelected
                                ? AppColors.primaryColor
                                : (isDark ? Colors.white70 : Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedPaymentMethod = "cash";
                      isCashSelected = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isCashSelected
                          ? AppColors.primaryColor.withOpacity(0.1)
                          : (isDark ? Colors.grey[800] : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCashSelected
                            ? AppColors.primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.money,
                          color: isCashSelected
                              ? AppColors.primaryColor
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cash',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isCashSelected
                                ? AppColors.primaryColor
                                : (isDark ? Colors.white70 : Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashReasonCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reason for Cash Request',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: reasonController,
            maxLines: 3,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Please explain why you need cash payment...',
              hintStyle: TextStyle(color: Colors.grey),
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemarksCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Remarks (Optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: remarksController,
            maxLines: 3,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Enter any additional information...',
              hintStyle: TextStyle(color: Colors.grey),
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: isSubmitting ? null : _submitOilRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            disabledBackgroundColor: Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: isSubmitting ? 0 : 4,
          ),
          child: isSubmitting
              ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          )
              : const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.send,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                "Submit Request",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddressResponse {
  final String restaurantAddress;
  final List<String> branchAddresses;

  AddressResponse({
    required this.restaurantAddress,
    required this.branchAddresses,
  });

  factory AddressResponse.fromJson(Map<String, dynamic> json) {
    return AddressResponse(
      restaurantAddress: json['restaurant_address'] ?? '',
      branchAddresses: List<String>.from(json['branch_addresses'] ?? []),
    );
  }
}
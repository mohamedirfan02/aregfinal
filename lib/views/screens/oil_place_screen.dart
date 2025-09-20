import 'dart:convert';
import 'package:areg_app/common/app_colors.dart';
import 'package:areg_app/config/api_config.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/custom_home_appbar.dart';
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
  final TextEditingController addressController = TextEditingController();
  final TextEditingController counterController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool isCashSelected = false;
  String? selectedDateRange;
  String selectedAddress = '';
  String? quantityError;
  double _unitPrice = 0.0;
  String? Token;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _notificationService.init();
    // Fetch your token from secure storage or another source
    Token = "your_dynamic_token_here"; // Replace with dynamic token retrieval
    _fetchAddresses(); // Fetch address options from API
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
        print('Failed to fetch price: ${response.body}');
        setState(() {
          _unitPrice = 0.0;
        });
      }
    } catch (e) {
      print('Error fetching price: $e');
      setState(() {
        _unitPrice = 0.0;
      });
    }
  }

  List<String> addressOptions = [];

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

        // Extract the first item from 'data' list
        final Map<String, dynamic> addressJson = jsonData['data'][0];
        final AddressResponse addressData = AddressResponse.fromJson(addressJson);

        setState(() {
          addressOptions = [
            addressData.restaurantAddress,
            ...addressData.branchAddresses,
          ];
        });
      } else {
        print("Failed to load addresses");
      }
    } catch (e) {
      print("Error fetching addresses: $e");
    }
  }



  Future<void> _submitOilRequest() async {
    // Enhanced validation to prevent submission below 5kg
    if (selectedOilType == null || quantityController.text.isEmpty) {
      _showAwesomeDialog('Error', 'Please fill in all fields.', DialogType.error);
      return;
    }

    // Parse and validate quantity
    final quantity = double.tryParse(quantityController.text);
    if (quantity == null) {
      _showAwesomeDialog('Error', 'Please enter a valid quantity.', DialogType.error);
      return;
    }

    // Strict validation for minimum 5kg
    if (quantity < 5) {
      _showAwesomeDialog('Error', 'Minimum quantity allowed is 5 KG. Please enter at least 5 KG.', DialogType.error);
      return;
    }

    // Validate address selection
    if (selectedAddress.isEmpty) {
      _showAwesomeDialog('Error', 'Please select a pickup address.', DialogType.error);
      return;
    }

    // Validate cash request reason
    if (isCashSelected && reasonController.text.trim().isEmpty) {
      _showAwesomeDialog('Error', 'Please provide a reason for cash request.', DialogType.error);
      return;
    }

    setState(() => isSubmitting = true); // 🔄 Show loader

    final response = await OilRequestService.submitOilRequest(
      type: selectedOilType!,
      quantity: quantityController.text,
      paymentMethod: isCashSelected ? "cash" : "online",
      reason: isCashSelected ? reasonController.text : null,
      dateRange: selectedDateRange,
      address: selectedAddress,
      remarks: remarksController.text,
      counter_unit_price: counterController.text.isNotEmpty ? counterController.text : null,
    );

    setState(() => isSubmitting = false); // Stop loader

    if (response != null && response.containsKey('error')) {
      _showAwesomeDialog('Error', response['error'], DialogType.error);
    } else {
      // Optional: show notification
      await _notificationService.showNotification(
        id: 1,
        title: "Oil Request Placed",
        body: "Your request for $selectedOilType has been submitted successfully.",
      );

      // ✅ Automatically go back to previous screen
      Navigator.pop(context);
    }
  }


  void _showAwesomeDialog(String title, String message, DialogType type, {bool isSuccess = false}) {
    AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.scale,
      title: title,
      desc: message,
      btnOkOnPress: () {
        if (isSuccess && mounted) {
          Navigator.pop(context);
          setState(() {
            selectedOilType = null;
            quantityController.clear();
            counterController.clear();
            reasonController.clear();
            selectedPaymentMethod = "online";
            isCashSelected = false;
            _unitPrice = 0.0;
            selectedDateRange = null;
          });
        }
      },
    ).show();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomHomeAppBar(screenWidth: screenWidth),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Oil Information",
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 5),
            Center(
              child: Text(
                "Details",
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 20),
            _buildDropdown(
              "Types of Oil",
              selectedOilType,
              ["Used Cooking Oil", "Coconut Oil", "Sunflower Oil", "Palm Oil"],
                  (value) => setState(() => selectedOilType = value),
            ),
            const SizedBox(height: 10),
            _buildLabeledTextField(
              "Above 5 KG",
              "Quantity (Kg)",
              quantityController,
              errorText: quantityError,
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
            ),
            const SizedBox(height: 10),
            _buildAddressDropdown(),
            const SizedBox(height: 20),
           // _buildRemarks(),
            _buildLabeledTextField(
              "Remarks",
              "Enter any additional information",
              remarksController,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 10),
            _buildAmountDisplay(context),
            const SizedBox(height: 10),
            _buildPaymentMethodSelection(context),

            // _buildLabeledTextField("counter unit price", "counter unit price", counterController),
            const SizedBox(height: 10),
            if (isCashSelected)
              _buildLabeledTextField(
                "Reason for Cash Request",
                "Enter reason",
                reasonController,
                keyboardType: TextInputType.text,
              ),
            const SizedBox(height: 20),
            //////////////////////////////////////////

            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.green[700] : AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isSubmitting ? null : _submitOilRequest,
                child: isSubmitting
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  "Submit Request",
                  style: theme.primaryTextTheme.labelLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
      String label,
      String? selectedValue,
      List<String> items,
      ValueChanged<String?> onChanged,
      ) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black54 : Colors.black26,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedValue,
                  hint: Text(
                    label,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  isExpanded: true,
                  onChanged: onChanged,
                  dropdownColor: isDark ? Colors.grey[850] : Colors.white,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                  items: items.map((item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddressDropdown() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Pickup Address",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black54 : Colors.black26,
                blurRadius: 4,
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: selectedAddress.isNotEmpty ? selectedAddress : null,
            items: addressOptions.map((address) {
              return DropdownMenuItem<String>(
                value: address,
                child: Text(
                  address,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedAddress = value ?? '';
                addressController.text = value ?? '';
              });
            },
            decoration: InputDecoration(
              hintText: "Select Address",
              hintStyle: TextStyle(color: theme.hintColor),
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
              border: InputBorder.none,
            ),
            validator: (value) => (value == null || value.isEmpty)
                ? "Please select a pickup address"
                : null,
            dropdownColor: isDark ? Colors.grey[900] : Colors.white,
          ),
        ),
      ],
    );
  }
  Widget _buildLabeledTextField(
      String label,
      String hint,
      TextEditingController controller, {
        String? errorText,
        VoidCallback? onTap,
        ValueChanged<String>? onChanged,
        TextInputType keyboardType = TextInputType.number,
      }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 5),
            GestureDetector(
              onTap: onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black54 : Colors.black26,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: controller,
                  enabled: onTap == null,
                  keyboardType: keyboardType,
                  onChanged: onChanged,
                  cursorColor: isDark ? Colors.greenAccent : AppColors.primaryColor,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black),
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                    hintText: hint,
                    hintStyle: TextStyle(color: theme.hintColor),
                    border: InputBorder.none,
                    errorText: errorText,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  //
  // Widget _buildDateSelector({
  //   required String label,
  //   required String? selectedDate,
  //   required ValueChanged<String> onDateSelected,
  // }) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         label,
  //         style: const TextStyle(
  //           fontSize: 14,
  //           fontWeight: FontWeight.w500,
  //         ),
  //       ),
  //       const SizedBox(height: 5),
  //       GestureDetector(
  //         onTap: () async {
  //           final pickedDate = await showDatePicker(
  //             context: context,
  //             initialDate: DateTime.now(),
  //             firstDate: DateTime.now(),
  //             lastDate: DateTime.now().add(const Duration(days: 365)),
  //             builder: (context, child) {
  //               return Theme(
  //                 data: Theme.of(context).copyWith(
  //                   colorScheme: ColorScheme.light(
  //                     primary: const Color(0xFF006D04), // ✅ Calendar's main color (your green)
  //                     onPrimary: Colors.white,          // Text color on selected date
  //                     onSurface: Colors.black,          // Text color for regular dates
  //                   ), // Calendar background
  //                   textButtonTheme: TextButtonThemeData(
  //                     style: TextButton.styleFrom(
  //                       foregroundColor: const Color(0xFF006D04), // "OK" and "CANCEL" buttons
  //                     ),
  //                   ),
  //                   datePickerTheme: const DatePickerThemeData(
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.all(Radius.circular(16)),
  //                     ),
  //                   ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
  //                 ),
  //                 child: child!,
  //               );
  //             },
  //           );
  //           if (pickedDate != null) {
  //             final formatted = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
  //             onDateSelected(formatted);
  //           }
  //         },
  //         child: Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.circular(8),
  //             boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
  //           ),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               Text(
  //                 selectedDate ?? "Select a date",
  //                 style: const TextStyle(fontSize: 16),
  //               ),
  //               const Icon(Icons.calendar_today),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }


  Widget _buildAmountDisplay(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double quantity = double.tryParse(quantityController.text) ?? 0.0;
    double totalAmount = quantity * _unitPrice;

    final containerColor = isDark ? Colors.grey[850] : Colors.white;
    final shadowColor = isDark ? Colors.black54 : Colors.black26;
    final textColor = isDark ? Colors.white70 : Colors.black54;
    final amountTextColor = isDark ? Colors.white : Colors.black;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Rate",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: shadowColor, blurRadius: 4)],
              ),
              child: Text(
                "₹${_unitPrice.toStringAsFixed(2)} / Kg",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: amountTextColor),
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "Total Amount",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: shadowColor, blurRadius: 4)],
              ),
              child: Text(
                "₹${totalAmount.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: amountTextColor),
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildPaymentMethodSelection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Payment Method",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
        ),
        Row(
          children: [
            Radio<String>(
              value: "online",
              groupValue: selectedPaymentMethod,
              onChanged: (value) => setState(() {
                selectedPaymentMethod = value!;
                isCashSelected = false;
              }),
              activeColor: AppColors.primaryColor,
            ),
            Text("Online", style: TextStyle(color: textColor)),
            Radio<String>(
              value: "cash",
              groupValue: selectedPaymentMethod,
              onChanged: (value) => setState(() {
                selectedPaymentMethod = value!;
                isCashSelected = true;
              }),
              activeColor:AppColors.primaryColor,
            ),
            Text("Cash Request", style: TextStyle(color: textColor)),
          ],
        ),
      ],
    );
  }

  // Widget _buildRemarks() {
  //   final theme = Theme.of(context);
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         "Remarks",
  //         style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
  //       ),
  //       const SizedBox(height: 8),
  //       TextFormField(
  //         controller: remarksController,
  //         maxLines: 3,
  //         keyboardType: TextInputType.multiline,
  //         decoration: InputDecoration(
  //           hintText: "Enter any additional information...",
  //           border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  //           contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  //         ),
  //       ),
  //     ],
  //   );
  // }


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


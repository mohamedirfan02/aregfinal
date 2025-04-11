import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import '../../common/custom_home_appbar.dart';
import '../../fbo_services/oil_request_service.dart';
import '../../main.dart';

class OilPlacedScreen extends StatefulWidget {
  const OilPlacedScreen({super.key});

  @override
  _OilPlacedScreenState createState() => _OilPlacedScreenState();
}

class _OilPlacedScreenState extends State<OilPlacedScreen> {
  final NotificationService _notificationService = NotificationService(); // Create an instance

  String? selectedOilType;
  String selectedPaymentMethod = "online"; // Default payment method
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController counterController = TextEditingController();

  bool isCashSelected = false; // To show/hide reason field

  String? selectedUnitPriceRange;
  double selectedAmount = 0.0;
  String? selectedDateRange;
  String? selectedAddress;
  // Unit Price Map
  final Map<String, double> unitPriceAmounts = {
    "0 to 100": 250.0,
    "100 to 200": 500.0,
    "200 to 300": 750.0,
    "300 to 400": 1000.0,
  };
  final List<String> dateRanges = ["3 to 7 Days", "8 to 12 Days"];
  final List<String> addressOptions = ["Registered Address", "Live Address", "Suggest Address"];
  @override
  void initState() {
    super.initState();
    _notificationService.init(); // ✅ Initialize notifications
  }

  Future<void> _submitOilRequest() async {
    if (selectedOilType == null || quantityController.text.isEmpty || selectedUnitPriceRange == null) {
      _showAwesomeDialog('Error', 'Please fill in all fields.', DialogType.error);
      return;
    }

    if (isCashSelected && reasonController.text.isEmpty) {
      _showAwesomeDialog('Error', 'Please provide a reason for cash request.', DialogType.error);
      return;
    }

    final response = await OilRequestService.submitOilRequest(
      type: selectedOilType!,
      quantity: quantityController.text,
      paymentMethod: isCashSelected ? "cash" : "online",
      reason: isCashSelected ? reasonController.text : null,
      dateRange: selectedDateRange,
      address: selectedAddress,
      counter_unit_price: counterController.text.isNotEmpty ? counterController.text : null, // ✅ FIXED
    );

    if (response != null && response.containsKey('error')) {
      _showAwesomeDialog('Error', response['error'], DialogType.error);
    } else {
      _showAwesomeDialog('Success', "Oil request submitted successfully.", DialogType.success, isSuccess: true);

      // ✅ Show Local Notification
      await _notificationService.showNotification(
        id: 1,
        title: "Oil Request Placed",
        body: "Your request for $selectedOilType has been submitted successfully.",
      );
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
        if (isSuccess) {
          setState(() {
            selectedOilType = null;
            quantityController.clear();
            counterController.clear();
            reasonController.clear();
            selectedPaymentMethod = "online";
            isCashSelected = false;
            selectedUnitPriceRange = null;
            selectedAmount = 0.0;
            selectedDateRange = null;
            selectedAddress = null;
          });
        }
      },
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width; // ✅ Get screen width

    return Scaffold(
      body: Scaffold(
        resizeToAvoidBottomInset: true, // ✅ Prevents UI overflow when keyboard opens
        backgroundColor: Colors.transparent,
        appBar: CustomHomeAppBar(screenWidth: screenWidth),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(), // ✅ Smooth scrolling
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              //  const SizedBox(height: 100),
                const Center(
                  child: Text(
                    "Oil Information",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 5),
                const Center(
                  child: Text(
                    "Details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 20),

                _buildDropdown("Types of Oil", selectedOilType, ["Used Cooking Oil", "Coconut Oil", "Sunflower Oil", "Palm Oil"], (value) {
                  setState(() {
                    selectedOilType = value;
                  });
                }),

                const SizedBox(height: 10),

                _buildLabeledTextField("Above 5 KG", "Quantity (Kg)", quantityController),
                const SizedBox(height: 20),
                _buildLabeledTextField("counter_unit_price", "counter_unit_price", counterController),

                _buildDropdown("Select Unit", selectedUnitPriceRange, unitPriceAmounts.keys.toList(), (value) {
                  setState(() {
                    selectedUnitPriceRange = value;
                    selectedAmount = unitPriceAmounts[value] ?? 0.0;
                  });
                }),
                const SizedBox(height: 10),

                _buildDropdown("Select Pickup Date Range", selectedDateRange, dateRanges, (value) {
                  setState(() {
                    selectedDateRange = value;
                  });
                }),
                const SizedBox(height: 10),
                _buildDropdown("Select Address", selectedAddress, addressOptions, (value) {
                  setState(() {
                    selectedAddress = value;
                  });
                }),
                const SizedBox(height: 10),

                // ✅ Display Selected Amount
                _buildAmountDisplay(),

                const SizedBox(height: 10),

                _buildPaymentMethodSelection(),

                const SizedBox(height: 10),

                if (isCashSelected)
                  _buildLabeledTextField("Reason for Cash Request", "Enter reason", reasonController),

                const SizedBox(height: 20),

                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D6E1E),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _submitOilRequest,
                    child: const Text(
                      "Submit Request",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String? selectedValue, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              hint: Text(label),
              icon: const Icon(Icons.arrow_drop_down),
              isExpanded: true,
              onChanged: onChanged,
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildLabeledTextField(String label, String hint, TextEditingController controller, {VoidCallback? onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: TextField(
              controller: controller,
              enabled: onTap == null,
              decoration: InputDecoration.collapsed(hintText: hint),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildAmountDisplay() {
    double quantity = double.tryParse(quantityController.text) ?? 0.0;
    double perKgPrice = 50.0;
    double totalAmount = quantity * perKgPrice;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: const Text(
            "Price Per Kg: ₹50",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Text(
            "Total: ₹$totalAmount",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }


  Widget _buildPaymentMethodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Payment Method", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Row(
          children: [
            Radio(
              value: "online",
              groupValue: selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  selectedPaymentMethod = value!;
                  isCashSelected = false;
                });
              },
            ),
            const Text("Online"),
            Radio(
              value: "cash",
              groupValue: selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  selectedPaymentMethod = value!;
                  isCashSelected = true;
                });
              },
            ),
            const Text("Cash Request"),
          ],
        ),
      ],
    );}
}

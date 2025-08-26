import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../common/custom_back_button.dart';
import '../../common/custom_button.dart';
import '../../common/custom_paratext_widget.dart';
import '../../config/api_config.dart';
import '../../fbo_services/user_repository.dart';

class UserCreation extends StatefulWidget {
  const UserCreation({super.key});
  @override
  State<UserCreation> createState() => _UserCreationState();
}
class _UserCreationState extends State<UserCreation> {
  bool _agreedToPrivacy = false;
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _branches = [];// Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController licenseController = TextEditingController();
  final TextEditingController pinCodeController = TextEditingController();
  final TextEditingController oilKgController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController restaurantNameController = TextEditingController();
  final TextEditingController accountNumberController = TextEditingController();
  String? selectedBank;
  bool _isSubmitting = false;
  String _selectedCategory = "Both";
  PhoneNumber _selectedPhoneNumber = PhoneNumber(isoCode: 'IN');// ✅ Image Files for License & Restaurant
  File? _licenseImage;
  File? _restaurantImage;
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7FBF08), // Header background & selected day
              onPrimary: Colors.white,    // Header text color
              onSurface: Colors.black,    // Calendar text
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF7FBF08), // OK / Cancel button text
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        // This assumes you're selecting DOB
        dobController.text = "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";
      });
    }
  }

  final List<String> bankList = ['State Bank of India', 'Bank of India', 'HDFC Bank', 'ICICI Bank', 'Axis Bank', 'Kotak Mahindra Bank', 'Punjab National Bank', 'Canara Bank', 'Bank of Baroda', 'Union Bank of India',];
  /// ✅ Pick Image using `image_picker`
  Future<void> _pickImage({required bool isLicense}) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (isLicense) {
          _licenseImage = File(pickedFile.path);
        } else {
          _restaurantImage = File(pickedFile.path);
        }
      });
    }
  }
  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 48),
                const SizedBox(height: 15),
                Text(
                  "Error",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("OK", style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),
        );
      },
    );
  }
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (!_agreedToPrivacy) {
        _showError("❌ You must agree to the Privacy Policy to continue.");
        return;
      }
      if (_selectedCategory.isEmpty) {
        _showError("❌ Please select a restaurant category.");
        return;
      }
      if (_licenseImage == null || _restaurantImage == null) {
        _showError("❌ Please upload both License and Restaurant images.");
        return;
      }
      if (selectedBank == null || accountNumberController.text.isEmpty) {
        _showError("❌ Please enter bank details.");
        return;
      }

      /// ✅ Show loading indicator immediately
      setState(() {
        _isSubmitting = true;
      });

      try {
        final Position? position = await _getCurrentPosition();
        if (position == null) {
          setState(() => _isSubmitting = false);
          return;
        }

        final distanceVerified = await _verifyAddressRadius(
          latitude: position.latitude,
          longitude: position.longitude,
          registeredAddress: addressController.text.trim(),
        );

        if (!distanceVerified) {
          setState(() => _isSubmitting = false);
          return;
        }

        final role = 'user';
        Map<String, String> userData = {
          "role": role,
          "full_name": nameController.text,
          "email": emailController.text,
          "dob": dobController.text,
          "country_code": _selectedPhoneNumber.isoCode ?? "",
          "contact_number": _selectedPhoneNumber.parseNumber(),
          "restaurant_name": restaurantNameController.text,
          "category": _selectedCategory,
          "license_number": licenseController.text,
          "address": addressController.text,
          "pincode": pinCodeController.text,
          "expected_volume": oilKgController.text,
          "password": passwordController.text,
          "bank_name": selectedBank ?? "",
          "account_no": accountNumberController.text,
        };

        List<Map<String, dynamic>> branchData = _branches.map((branch) => {
          "branch_name": branch['branchName'],
          "branch_address": branch['branchAddress'],
          "branch_fassai_no": branch['fassaiNo'],
        }).toList();

        if (branchData.isNotEmpty) {
          userData['branches'] = jsonEncode(branchData);
        }

        print("📦 User Data: $userData");

        var response = await UserRegistration.registerUser(
          userData,
          _licenseImage!,
          _restaurantImage!,
          branches: _branches,
        );

        print("🚀 API Response: $response");

        if (response.containsKey("error")) {
          _showError(response["error"]);
        } else {
          _sendOTP(_selectedPhoneNumber.phoneNumber ?? "");
        }
      } catch (e) {
        _showError("❌ Something went wrong: $e");
      } finally {
        setState(() => _isSubmitting = false); // ✅ Always stop loading
      }
    }
  }

  void _sendOTP(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      _showError("❌ Enter a valid phone number!");
      return;
    }
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          print("✅ Auto Verification Completed");
        },
        verificationFailed: (FirebaseAuthException e) {
          _showError("❌ ${e.message}");
        },
        codeSent: (String verificationId, int? resendToken) {
          print("✅ SMS OTP Sent!");
          context.go('/OTPVerificationScreen', extra: {"phone": phoneNumber, "verificationId": verificationId});
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print("⏳ Auto Retrieval Timeout: $verificationId");
        },
      );
    } catch (e) {
      _showError("❌ OTP Sending Failed: $e");
    }
  }
  Future<Position?> _getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError("❌Turn on the location you must be inside 500m from your restaurant");
      return null;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError("❌ Location permissions are denied.");
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showError("❌ Location permissions are permanently denied.");
      return null;
    }
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }
  Future<bool> _verifyAddressRadius({
    required double latitude,
    required double longitude,
    required String registeredAddress,
  }) async {
    final url = Uri.parse(ApiConfig.verifyAddressRadius);
    final body = {
      "latitude": latitude.toString(),
      "longitude": longitude.toString(),
      "registered_address": registeredAddress,
    };
    try {
      print("📤 Sending Distance Check Request:");
      print("URL: $url");
      print("BODY: ${jsonEncode(body)}");

      final response = await http.post(
        url,
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json'},
      );

      print("📥 Response Status: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['message']?.toString().toLowerCase() ?? "";

        if (message.contains("within threshold")) {
          return true;
        } else {
          _showError("❌ Your registration address is outside 500m range.");
          return false;
        }
      } else {
        _showError("invalid address Enter address as per in fssai certificate ");
        return false;
      }
    } catch (e) {
      print("❌ Distance API Error: $e");
      _showError("❌ Distance check error: $e");
      return false;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: CustomBackButton(
          onPressed: () => context.go('/RoleScreen'),
        ),
        backgroundColor: Color(0xFF7FBF08),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: SizedBox(
                  width: 150,
                  height: 150,
                  child: Lottie.asset(
                    'assets/animations/start.json',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const CustomText(
                boldText: 'FBO Registration',
              subtext: 'Sign up to get started!',   text: '',
              ),SizedBox(height: 7,),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(restaurantNameController, "Restaurant Name", imageIcon: AssetImage("assets/icon/rest.png"),),
                    _buildTextField(nameController, "Authorizer Name", imageIcon: AssetImage("assets/icon/profile.png"),),
                    _buildTextField(emailController, "Email", imageIcon: AssetImage("assets/icon/mail.png"), isEmail: true),
                    _buildPhoneNumberField(),
                    _buildDateField(context, dobController, "Registration Date",imageIcon: AssetImage("assets/icon/cal.png"),),
                    _buildCategorySelection(),
                    _buildBankSelector(),
                    _buildTextField(accountNumberController, "Account Number", imageIcon: AssetImage("assets/icon/acc.png"),),
                    _buildTextField(licenseController, "FSSAI Number",imageIcon: AssetImage("assets/icon/lic.png"),),
                    _buildTextField(pinCodeController, "Pin Code",imageIcon: AssetImage("assets/icon/location.png"), isPinCode: true),
                    _buildTextField(oilKgController, "Expected Kg",imageIcon: AssetImage("assets/icon/location.png"), isPinCode: true),
                    _buildTextField(addressController, " Main Branch Address", imageIcon: AssetImage("assets/icon/main.png"),),
                    _buildAddBranchButton(),
                    const SizedBox(height: 10),
                    _buildBranchesList(),
                    _buildTextField(passwordController, "Password", imageIcon: AssetImage("assets/icon/password.png"),
                        obscureText: true, isPassword: true),
                    _buildImageUploadSection(isLicense: true),
                    _buildImageUploadSection(isLicense: false),
                    Row(
                      children: [
                        Checkbox(
                          value: _agreedToPrivacy,
                          onChanged: (bool? value) {
                            setState(() {
                              _agreedToPrivacy = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: 'I agree to the ',
                              style: TextStyle(color: Colors.black),
                              children: [
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: Colors.blue,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () async {
                                      final url = Uri.parse('https://ai.thikse.in/enzopik/privacy-policy');
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url, mode: LaunchMode.externalApplication);
                                      }
                                    },
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: CustomSubmitButton(
                        buttonText: 'Submit',
                        onPressed: _submitForm,
                        isLoading: _isSubmitting,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildBankSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: selectedBank,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: "Select Bank",
          prefixIcon: Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              "assets/icon/bank.png", // Update with your image path
              width: 24,
              height: 24,
            ),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: bankList.map((bank) {
          return DropdownMenuItem<String>(
            value: bank,
            child: Text(bank),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedBank = value;
          });
        },
        validator: (value) => value == null ? "Please select a bank" : null,
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Restaurant Category",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Column(
          children: ["veg", "non_veg", "both"].map((category) {
            return RadioListTile<String>(
              title: Row(
                children: [
                  _getCategoryIcon(category), // ✅ Icon for category
                  const SizedBox(width: 8), // Space between icon and text
                  Text(category.toUpperCase()), // ✅ Display category name
                ],
              ),
              value: category,
              groupValue: _selectedCategory,
              onChanged: (String? value) {
                print("Selected category changed to: $value"); // Debugging print statement
                setState(() {
                  _selectedCategory = value!;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
  /// ✅ Function to Get Icons for Categories
  Widget _getCategoryIcon(String category) {
    Color iconColor;
    IconData iconData;
    if (category == "veg") {
      iconColor = Colors.green;
      iconData = Icons.circle;
    } else if (category == "non_veg") {
      iconColor = Colors.red;
      iconData = Icons.circle;
    } else {
      iconColor = Colors.blue;
      iconData = Icons.circle; // Neutral color for "both"
    }
    return Icon(iconData, color: iconColor, size: 18);
  }
  Widget _buildPhoneNumberField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: phoneController,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          labelText: "Phone Number",
          prefixIcon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: InternationalPhoneNumberInput(
              onInputChanged: (PhoneNumber number) {
                setState(() {
                  _selectedPhoneNumber = number;
                });
              },
              selectorConfig: const SelectorConfig(
                selectorType: PhoneInputSelectorType.DROPDOWN,
              ),
              ignoreBlank: true,
              autoValidateMode: AutovalidateMode.disabled,
              initialValue: _selectedPhoneNumber,
              textFieldController: phoneController,
              formatInput: false, // Prevents duplicate input
              inputDecoration: const InputDecoration(
                border: InputBorder.none, // Removes extra borders from the selector
              ),
            ),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
  Widget _buildTextField(
      TextEditingController controller,
      String label,
      {IconData? icon,
        ImageProvider? imageIcon,
        bool obscureText = false,
        bool isPinCode = false,
        bool isPassword = false,
        bool isEmail = false,
        bool isReadOnly = false,
        VoidCallback? onTap}) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        readOnly: isReadOnly,
        onTap: onTap,
        keyboardType: isEmail
            ? TextInputType.emailAddress
            : (isPinCode ? TextInputType.number : TextInputType.text),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: imageIcon != null
              ? Padding(
            padding: const EdgeInsets.all(10),
            child: Image(
              image: imageIcon,
              width: 24,
              height: 24,
            ),
          )
              : (icon != null ? Icon(icon) : null),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (value) =>
        value == null || value.isEmpty ? "Please enter $label" : null,
      ),
    );
  }

  Widget _buildAddBranchButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _showAddBranchDialog,
        icon: const Icon(Icons.add),
        label: const Text("Add Branch"),
      ),
    );
  }
  Future<void> _showAddBranchDialog() async {
    final TextEditingController branchNameController = TextEditingController();
    final TextEditingController branchAddressController = TextEditingController();
    final TextEditingController branchFassaiController = TextEditingController();
    File? branchImage;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Branch'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogTextField(branchNameController, "Branch Name"),
                const SizedBox(height: 10),
                _buildDialogTextField(branchAddressController, "Branch Address"),
                const SizedBox(height: 10),
                _buildDialogTextField(branchFassaiController, "Branch FSSAI No"),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setState(() {
                        branchImage = File(pickedFile.path);
                      });
                    }
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: branchImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        branchImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                        : const Center(child: Icon(Icons.camera_alt, color: Colors.grey, size: 40)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (branchNameController.text.isEmpty ||
                    branchAddressController.text.isEmpty ||
                    branchFassaiController.text.isEmpty ||
                    branchImage == null) {
                  _showError("❌ Please fill all branch fields and upload image!");
                  return;
                }
                setState(() {
                  _branches.add({
                    "branchName": branchNameController.text,
                    "branchAddress": branchAddressController.text,
                    "fassaiNo": branchFassaiController.text,
                    "image": branchImage!,
                  });
                });
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  Widget _buildDialogTextField(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
  Widget _buildBranchesList() {
    return Column(
      children: _branches.map((branch) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: branch['image'] != null
                ? Image.file(branch['image'], width: 50, height: 50, fit: BoxFit.cover)
                : const Icon(Icons.image),
            title: Text(branch['branchName']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Address: ${branch['branchAddress']}"),
                Text("FSSAI No: ${branch['fassaiNo']}"),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
  Widget _buildDateField(
      BuildContext context,
      TextEditingController controller,
      String label, {
        ImageProvider? imageIcon,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => _selectDate(context),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: imageIcon != null
              ? Padding(
            padding: const EdgeInsets.all(10),
            child: Image(
              image: imageIcon,
              width: 24,
              height: 24,
            ),
          )
              : const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (value) =>
        value == null || value.isEmpty ? "$label is required" : null,
      ),
    );
  }

  Widget _buildImageUploadSection({required bool isLicense}) {
    File? selectedImage = isLicense ? _licenseImage : _restaurantImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isLicense ? "Upload FSSAI Image" : "Upload Restaurant Image",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft, // Or Alignment.center if preferred
          child: GestureDetector(
            onTap: () => _pickImage(isLicense: isLicense),
            child: Container(
              height: 80,
              width: 80, // Reduced width
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: selectedImage != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  selectedImage,
                  fit: BoxFit.cover,
                  width: 250,
                  height: 150,
                ),
              )
                  : const Center(
                child: Icon(Icons.camera_alt, color: Colors.grey, size: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }

}

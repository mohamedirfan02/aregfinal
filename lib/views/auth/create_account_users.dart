import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:lottie/lottie.dart';
import '../../common/custom_back_button.dart';
import '../../common/custom_button.dart';
import '../../common/custom_paratext_widget.dart';
import '../../common/custom_scaffold.dart';
import '../../fbo_services/user_repository.dart';

class UserCreation extends StatefulWidget {
  const UserCreation({super.key});

  @override
  State<UserCreation> createState() => _UserCreationState();
}

class _UserCreationState extends State<UserCreation> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController licenseController = TextEditingController();
  final TextEditingController pinCodeController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController restaurantNameController = TextEditingController();

  bool _isSubmitting = false;
  String _selectedCategory = "Both";
  PhoneNumber _selectedPhoneNumber = PhoneNumber(isoCode: 'IN');
  // ✅ Image Files for License & Restaurant
  File? _licenseImage;
  File? _restaurantImage;
  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dobController.text = "${picked.year}-${picked.month}-${picked.day}";
      });
    }
  }
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.red)),
        backgroundColor: Colors.white,
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory.isEmpty) {
        _showError("❌ Please select a restaurant category.");
        return;
      }

      if (_licenseImage == null || _restaurantImage == null) {
        _showError("❌ Please upload both License and Restaurant images.");
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

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
        "password": passwordController.text,
      };

      print("User Data: $userData");

      var response = await UserRegistration.registerUser(
        userData,
        _licenseImage!,
        _restaurantImage!,

      );

      print("🚀 API Response: $response");

      if (response.containsKey("error")) {
        _showError(response["error"]);
      } else {
        _sendOTP(_selectedPhoneNumber.phoneNumber ?? "");
      }
      setState(() => _isSubmitting = false);
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
                  width: 250,
                  height: 250,
                  child: Lottie.asset(
                    'assets/animations/start.json',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const CustomText(
                boldText: 'FBO Registration',
                text: '', subtext: 'Sign up to get started!',
              ),SizedBox(height: 7,),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(restaurantNameController, "Restaurant Name", Icons.restaurant),
                    _buildTextField(nameController, "Authorizer Name", Icons.person),
                    _buildTextField(emailController, "Email", Icons.email, isEmail: true),
                    _buildPhoneNumberField(),
                    _buildDateField(context, dobController, "Registration Date"),
                    _buildCategorySelection(),
                    _buildTextField(licenseController, "FSSAI Number", Icons.assignment),
                    _buildTextField(pinCodeController, "Pin Code", Icons.pin_drop, isPinCode: true),
                    _buildTextField(addressController, "Address", Icons.location_city),
                    _buildTextField(passwordController, "Password", Icons.lock,
                        obscureText: true, isPassword: true),
                    _buildImageUploadSection(isLicense: true),
                    _buildImageUploadSection(isLicense: false),
                    const SizedBox(height: 30),
                    Center(
                      child: _isSubmitting
                          ? const CircularProgressIndicator()
                          : CustomSubmitButton(
                        buttonText: 'Submit',
                        onPressed: _submitForm,
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
  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {bool obscureText = false, bool isPinCode = false, bool isPassword = false, bool isEmail = false, bool isReadOnly = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        readOnly: isReadOnly,
        onTap: onTap,
        keyboardType: isEmail ? TextInputType.emailAddress : (isPinCode ? TextInputType.number : TextInputType.text),
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
        validator: (value) => value == null || value.isEmpty ? "Please enter $label" : null,
      ),
    );
  }
  Widget _buildDateField(BuildContext context, TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => _selectDate(context),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (value) => value == null || value.isEmpty ? "$label is required" : null,
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

        GestureDetector(
          onTap: () => _pickImage(isLicense: isLicense),
          child: Container(
            height: 150,
            width: double.infinity,
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
              ),
            )
                : const Center(
              child: Icon(Icons.camera_alt, color: Colors.grey, size: 40),
            ),
          ),
        ),
      ],
    );
  }

}

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../common/custom_back_button.dart';
import '../../common/custom_button.dart';
import '../../common/custom_paratext_widget.dart';
import '../../fbo_services/user_repository.dart';

class VendorCreation extends StatefulWidget {
  const VendorCreation({super.key});

  @override
  State<VendorCreation> createState() => _VendorCreationState();
}

class _VendorCreationState extends State<VendorCreation> {
  final _formKey = GlobalKey<FormState>();
  bool _agreedToPrivacy = false;

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController(); // ✅ Email Controller
  final TextEditingController licenseController = TextEditingController();
  final TextEditingController pinCodeController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  //final TextEditingController restaurantNameController = TextEditingController();

  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  String? selectedGender;
  bool _isSubmitting = false;
  PhoneNumber _selectedPhoneNumber = PhoneNumber(isoCode: 'IN'); // Default India

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(color: Colors.red))),
    );
  }

  // ✅ Select Date of Birth & Calculate Age
  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        ageController.text = _calculateAge(dobController.text).toString(); // ✅ Auto-fill Age
      });
    }
  }
  // ✅ Calculate Age from DOB
  int _calculateAge(String dob) {
    if (dob.isEmpty) return 0;

    DateTime birthDate = DateTime.parse(dob);
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;

    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (!_agreedToPrivacy) {
        _showError("❌ You must agree to the Privacy Policy to continue.");
        return;
      }
      setState(() {
        _isSubmitting = true;
      });

      final role = 'vendor';

      int age = _calculateAge(dobController.text);
      if (age < 18) {
        _showError("❌ You must be at least 18 years old.");
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      Map<String, String> userData = {
        "role": role,
        "full_name": nameController.text,
        "email": emailController.text,
        "dob": dobController.text,
        "age": age.toString(), // ✅ Age Sent
        "gender": selectedGender ?? "Male",
        "country_code": _selectedPhoneNumber.isoCode ?? "",
        "contact_number": _selectedPhoneNumber.parseNumber(),
        "license_number": licenseController.text,
        "address": addressController.text,
        "pincode": pinCodeController.text,
        "password": passwordController.text,
      };

      print("User Data: $userData");

      var response = await UserRegistration.registerVendor(userData, _selectedImage);
      print("🚀 API Response: $response");

      if (response.containsKey("error")) {
        _showError(response["error"]);
      } else {
        _sendOTP(_selectedPhoneNumber.phoneNumber ?? "");
      }
      setState(() {
        _isSubmitting = false;
      });
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
          print("❌ Phone Verification Failed: ${e.message}");
          _showError("❌ ${e.message}");
        },
        codeSent: (String verificationId, int? resendToken) {
          print("✅ SMS OTP Sent!");

          context.go('/OTPVerificationScreen', extra: {
            "phone": phoneNumber,
            "verificationId": verificationId
          });
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
                    width: 150,
                    height: 150,
                    child: Lottie.asset(
                      'assets/animations/start.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const CustomText(
                  boldText: 'Agent Registration',
                  subtext: 'Create your new account',
                  text: '',
                ),    const SizedBox(height: 10),
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage:
                      _selectedImage != null ? FileImage(_selectedImage!) : null,
                      child: _selectedImage == null
                          ? Icon(Icons.camera_alt, size: 40)
                          : null,
                    ),
                  ),
                ),


                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(nameController, "Full Name",null, iconImagePath: 'assets/icon/profile.png'),
                      _buildTextField(emailController, "Email", Icons.email, isEmail: true, iconImagePath: 'assets/icon/mail.png'),
                      _buildDateField(context, dobController, "Date of Birth", iconImagePath: 'assets/icon/cal.png'),
                      _buildTextField(ageController, "Age", Icons.cake, readOnly: true),
                     // _buildGenderSelection(),
                      _buildPhoneNumberField(),
                      _buildTextField(licenseController, "License Number", Icons.assignment, iconImagePath: 'assets/icon/lic.png'),
                      _buildTextField(pinCodeController, "Pin Code", Icons.pin_drop, isPinCode: true, iconImagePath: 'assets/icon/location.png'),
                      _buildTextField(addressController, "Address", Icons.location_city),
                      _buildTextField(passwordController, "Password", Icons.lock, obscureText: true, isPassword: true, iconImagePath: 'assets/icon/password.png'),
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
                                        final url = Uri.parse('https://ai.thikse.in/privacy-policy');
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
                      Center(
                        child: _isSubmitting
                            ? const CircularProgressIndicator()
                            : CustomSubmitButton(
                          buttonText: 'Submit',
                          onPressed: _submitForm,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }


  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData? icon, {
        bool obscureText = false,
        bool isPinCode = false,
        bool isPassword = false,
        bool isEmail = false,
        bool readOnly = false,
        String? iconImagePath,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        readOnly: readOnly,
        keyboardType: isEmail
            ? TextInputType.emailAddress
            : (isPinCode ? TextInputType.number : TextInputType.text),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: iconImagePath != null
              ? Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset(
              iconImagePath,
              width: 24,
              height: 24,
            ),
          )
              : Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFF7FBF08), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please enter $label";
          }
          if (isEmail &&
              !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                  .hasMatch(value)) {
            return "Enter a valid email";
          }
          return null;
        },
      ),
    );
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

  Widget _buildDateField(
      BuildContext context,
      TextEditingController controller,
      String label, {
        String? iconImagePath,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => _selectDate(context),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: iconImagePath != null
              ? Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset(
              iconImagePath,
              width: 24,
              height: 24,
            ),
          )
              : const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFF7FBF08), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
        ),
        validator: (value) =>
        value == null || value.isEmpty ? "$label is required" : null,
      ),
    );
  }

}

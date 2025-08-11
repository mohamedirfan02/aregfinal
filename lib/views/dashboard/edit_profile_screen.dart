import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../../agent/common/common_appbar.dart';
import '../../common/custom_textformfield.dart';
import '../../config/api_config.dart';

class EditProfileScreen extends StatefulWidget {
  //final Map<String, dynamic>? userDetails;
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _contactController;
  bool isReadyToSubmit = false;
  bool isUploading = false; // Add loading state

  Future<void> _updateProfile() async {
    if (isUploading) return; // Prevent multiple submissions

    setState(() {
      isUploading = true;
    });

    final url = Uri.parse(ApiConfig.UpdateProfile);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? role = prefs.getString('role');
    int? userId = int.tryParse(prefs.getString('user_id') ?? '');

    if (userId == null) {
      setState(() {
        isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ User ID not found in preferences")),
      );
      return;
    }

    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', url);

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Add text fields
      request.fields['id'] = userId.toString();
      request.fields['role'] = role ?? '';
      request.fields['full_name'] = _nameController.text.trim();
      request.fields['email'] = _emailController.text.trim();
      request.fields['contact_number'] = _contactController.text.trim();

      // Add image file if selected
      if (_imageFile != null) {
        var imageFile = await http.MultipartFile.fromPath(
          'profile', // This should match your API parameter name
          _imageFile!.path,
        );
        request.files.add(imageFile);
        debugPrint("📷 Adding image file: ${_imageFile!.path}");
      }
      debugPrint("🔐 Token: $token");

      debugPrint("📤 Sending multipart data to API:");
      debugPrint("📤 Fields: ${request.fields}");
      debugPrint("📤 Files: ${request.files.length} file(s)");

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint("📥 Response status: ${response.statusCode}");
      debugPrint("📥 Response body: ${response.body}");

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Profile updated successfully")),
        );

        _nameController.clear();
        _emailController.clear();
        _contactController.clear();
        setState(() {
          _imageFile = null; // Clear selected image
        });

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context, true);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ${responseBody['message'] ?? 'Update failed'}")),
        );
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Exception caught during API call: $e");
      debugPrint("🪱 Stack trace: $stackTrace");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to update profile: $e")),
      );
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // debugPrint("🧾 userDetails: $details");
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _contactController = TextEditingController();
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _contactController.addListener(_validateForm);
  }

  void _validateForm() {
    final filled = _nameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _contactController.text.trim().isNotEmpty;

    if (filled != isReadyToSubmit) {
      setState(() {
        isReadyToSubmit = filled;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compress image to reduce file size
        maxWidth: 1024,   // Limit image dimensions
        maxHeight: 1024,
      );
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
        });
        debugPrint("📷 Image selected: ${picked.path}");
      }
    } catch (e) {
      debugPrint('📷 Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error selecting image: $e")),
      );
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_validateForm);
    _emailController.removeListener(_validateForm);
    _contactController.removeListener(_validateForm);

    _nameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _imageFile != null
        ? FileImage(_imageFile!)
        : const AssetImage('assets/image/profile.jpg') as ImageProvider;

    return Scaffold(
      appBar: const CommonAppbar(title: "Edit Profile"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildProfileImage(imageProvider),
              const SizedBox(height: 10),
              Text(
                _imageFile != null ?   "Edit Photo" : "Upload Photo",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _imageFile != null ? Colors.green : Colors.black,
                ),
              ),
              const SizedBox(height: 30),
              CustomTextFormField(
                controller: _nameController,
                hintText: 'Enter your name',
                iconData: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              CustomTextFormField(
                controller: _emailController,
                hintText: 'Enter your email',
                iconData: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a valid Email ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              CustomTextFormField(
                controller: _contactController,
                hintText: 'Enter your phone number',
                iconData: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your contact number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: isUploading ? null : () {
                  if (_formKey.currentState!.validate()) {
                    _updateProfile();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isUploading
                        ? Colors.grey.shade400
                        : isReadyToSubmit
                        ? const Color(0xFF006D04)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isUploading
                      ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Updating...",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                      : const Text(
                    "Submit",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(ImageProvider imageProvider) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: imageProvider,
            backgroundColor: Colors.grey,
            onBackgroundImageError: (exception, stackTrace) {
              debugPrint("🔥 Image Load Error: $exception");
            },
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: _imageFile != null ? Colors.green : Colors.grey,
                child: Icon(
                  _imageFile != null ? Icons.check : Icons.edit,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
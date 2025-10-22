import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SharedPrefsService {
  // Save login data
  static Future<void> saveLoginData(Map<String, dynamic> response) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Save simple fields
    await prefs.setString('token', response['token']);
    await prefs.setString('role', response['role']);
    await prefs.setInt('vendor_id', response['details']['id']);
    await prefs.setString('email', response['details']['email']);

    // Save full vendor details as JSON string
    String vendorDetails = jsonEncode(response['details']);
    await prefs.setString('vendor_details', vendorDetails);

    print('✅ Vendor data saved in SharedPreferences!');
  }

  // Get vendor details
  static Future<Map<String, dynamic>?> getVendorDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? vendorDetails = prefs.getString('vendor_details');
    if (vendorDetails != null) {
      return jsonDecode(vendorDetails);
    }
    return null;
  }

  // Get token
  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

import '../config/api_config.dart';

class VoucherService {

  /// ✅ Fetch acknowledged vouchers for dynamic roles (user, vendor, agent)
  Future<List<Map<String, dynamic>>> fetchVouchers() async {
    await checkStoredData(); // ✅ Debug stored values

    const String apiUrl = ApiConfig.getOrderDetails;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      String? token = prefs.getString('token');
      String? role = prefs.getString('role'); // Get dynamic role
      String? userIdString = prefs.getString('user_id'); // ✅ Retrieve as STRING

      print("✅ Token: $token, Role: $role, User ID (String): $userIdString"); // Debugging Output

      if (token == null || role == null || userIdString == null) {
        throw Exception("❌ Authentication token, role, or user ID is missing.");
      }

      // ✅ Convert userId safely from String to int
      int? userId = int.tryParse(userIdString);
      if (userId == null) {
        throw Exception("❌ Invalid User ID format. Expected an integer.");
      }

      final requestData = {
        "role": role,
        "id": userId,
        "status": "acknowledged",
      };

      print("📤 Sending request to $apiUrl with data: $requestData");

      final response = await Dio().post(
        apiUrl,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer $token",
          },
        ),
        data: requestData,
      );


      print("🔹 Response Status Code: ${response.statusCode}");
      print("🔹 Raw Response Body: ${response.data}");

      if (response.statusCode == 200) {
        final data = response.data;
        if (data["status"] == "success" && data["data"] is List) {
          return List<Map<String, dynamic>>.from(data["data"].map((voucher) =>
          {
            "order_id": voucher["order_id"],
            "type": voucher["type"],
            "quantity": voucher["quantity"],
            "status": voucher["status"],
            "user_id": voucher["user_id"],
            "vendor_id": voucher["vendor_id"],
            "unit_price": voucher["proposed_unit_price"] ?? "N/A",
            "user_name": voucher["user_name"],
            "address": voucher["registered_address"] ?? "N/A",
            "user_contact": voucher["user_contact"] ?? "N/A",
            "amount": voucher["amount"] ?? "N/A",
            "date": voucher["date"],
            "time": voucher["time"],
          }));
        } else {
          throw Exception("❌ Invalid API response format.");
        }
      } else {
        throw Exception("❌ Failed with Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching vouchers: $e");
      throw Exception("❌ Error fetching vouchers: $e");
    }
  }

  /// ✅ Debug stored SharedPreferences values
  Future<void> checkStoredData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString('token');
    String? role = prefs.getString('role');
    String? userIdString = prefs.getString('user_id'); // ✅ Retrieve as STRING

    print("✅ Stored Token: $token");
    print("✅ Stored Role: $role");
    print("✅ Stored User ID (String): $userIdString");

    if (token == null || role == null || userIdString == null) {
      print("❌ Missing User ID or Token");
    } else {
      print("✅ Token: $token, Role: $role, User ID: $userIdString");
    }
  }


  Future<String> downloadVoucher(
      int orderId, {
        required String format,
        DateTime? fromDate,
        DateTime? toDate,
      }) async {
    const String apiUrl = ApiConfig.DownloadAcknowledgedVoucher;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? role = prefs.getString('role');
      String? userId = prefs.getString('user_id');

      if (token == null || role == null || userId == null) {
        throw Exception("❌ Authentication token, role, or user ID is missing.");
      }

      if (format == "excel" && role != "agent") {
        throw Exception("❌ Only agents can download vouchers in Excel format.");
      }

      final requestData = {
        "role": role,
        "id": int.parse(userId),
        "order_id": orderId,
        "format": format,
        if (fromDate != null) "from_date": fromDate.toIso8601String().split('T').first,
        if (toDate != null) "to_date": toDate.toIso8601String().split('T').first,
      };

      print("📤 Sending download request to $apiUrl with data: $requestData");

      final response = await Dio().post(
        apiUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            "Content-Type": "application/json",
            "Accept": format == "pdf"
                ? "application/pdf"
                : "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "Authorization": "Bearer $token",
          },
        ),
        data: requestData,
      );


      if (response.statusCode == 200) {
        String fileExtension = format == "pdf" ? "pdf" : "xlsx";
        Directory? dir = await getExternalStorageDirectory();
        String filePath = "${dir?.path}/voucher_$orderId.$fileExtension";
        final File file = File(filePath);
        await file.writeAsBytes(response.data);

        print("✅ Voucher saved at: $filePath");
        return filePath;
      } else {
        throw Exception("❌ Failed to download. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error downloading voucher: $e");
      throw Exception("❌ Error downloading voucher: $e");
    }
  }


  /// ✅ Open the downloaded file
  void openFile(String filePath) {
    try {
      OpenFilex.open(filePath); // ✅ Use OpenFilex to open PDF/Excel
    } catch (e) {
      print("❌ Error opening file: $e");
    }
  }

  /// ✅ Open Downloads Folder (for Android 11+)
  void openDownloadsFolder() {
    final intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      data: "content://com.android.externalstorage.documents/document/primary%3ADownload",
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    intent.launch();
  }
}

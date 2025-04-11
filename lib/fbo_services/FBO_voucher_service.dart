import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

class VoucherService {
  final String baseUrl = "https://enzopik.thikse.in/api";

  /// ✅ Fetch acknowledged vouchers for dynamic roles (user, vendor, agent)
  Future<List<Map<String, dynamic>>> fetchVouchers() async {
    await checkStoredData(); // ✅ Debug stored values

    const String apiUrl = "https://enzopik.thikse.in/api/get-order-details";

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

      final response = await Dio().post(
        apiUrl,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer $token",
          },
        ),
        data: {
          "role": role, // ✅ Dynamic role
          "id": userId, // ✅ Now correctly an int
          "status": "acknowledged", // ✅ Added status
        },
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


  /// ✅ Download voucher (supports both PDF & Excel formats)
  Future<String> downloadVoucher(int orderId, {required String format}) async {
    const String apiUrl = "https://enzopik.thikse.in/api/download-acknowledged-voucher";

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? role = prefs.getString('role'); // Get dynamic role
      String? userId = prefs.getString('user_id'); // Get dynamic ID

      if (token == null || role == null || userId == null) {
        throw Exception("❌ Authentication token, role, or user ID is missing.");
      }

      // ✅ Allow Excel downloads ONLY for agents
      if (format == "excel" && role != "agent") {
        throw Exception("❌ Only agents can download vouchers in Excel format.");
      }

      final response = await Dio().post(
        apiUrl,
        options: Options(
          responseType: ResponseType.bytes, // ✅ Get file as bytes
          headers: {
            "Content-Type": "application/json",
            "Accept": format == "pdf" ? "application/pdf" : "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "Authorization": "Bearer $token",
          },
        ),
        data: {
          "role": role, // ✅ Dynamic role
          "id": int.parse(userId), // ✅ Dynamic ID
          "order_id": orderId,
          "format": format, // ✅ Specify format (pdf or excel)
        },
      );

      if (response.statusCode == 200) {
        String filePath;
        String fileExtension = format == "pdf" ? "pdf" : "xlsx";

        // ✅ Save in `/storage/emulated/0/Download` (Android 10 and below)
        if (Platform.version.contains("10") || Platform.version.contains("9")) {
          Directory downloadsDir = Directory("/storage/emulated/0/Download");
          if (!downloadsDir.existsSync()) {
            downloadsDir.createSync(recursive: true);
          }
          filePath = "${downloadsDir.path}/voucher_$orderId.$fileExtension";
        }
        // ✅ Android 11+ → Use Scoped Storage
        else {
          Directory? dir = await getExternalStorageDirectory();
          filePath = "${dir?.path}/voucher_$orderId.$fileExtension";
        }

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

  // Future<void> checkStoredData() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String? token = prefs.getString('token');
  //   String? role = prefs.getString('role');
  //   String? userId = prefs.getString('user_id');
  //
  //   print("✅ Stored Token: $token");
  //   print("✅ Stored Role: $role");
  //   print("✅ Stored User ID: $userId");
  // }
}

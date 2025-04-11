import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_filex/open_filex.dart';

class FboDocumentService {
  static const String _baseUrl = "https://enzopik.thikse.in/api";

  /// ✅ Fetch user data from API
  static Future<List<Map<String, dynamic>>> fetchUsers() async {
    const String apiUrl = "$_baseUrl/users/all";

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        print("❌ No authentication token found.");
        return [];
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData["status"] == "success" && jsonData["data"] is List) {
          return List<Map<String, dynamic>>.from(jsonData["data"]);
        }
      } else {
        throw Exception("❌ Failed to load users. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching users: $e");
    }
    return [];
  }

  /// ✅ Download PDF with Progress
  static Future<void> downloadPdf({
    required int userId,
    required String type,
    required Function(double) onProgress,
    required Function(String?) onComplete,
  }) async {
    String apiUrl = "$_baseUrl/download$type/$userId";
    String fileName = "${type.toLowerCase()}_$userId.pdf";

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        print("❌ No authentication token found.");
        return;
      }

      Dio dio = Dio();
      Directory? directory = await getExternalStorageDirectory();
      String filePath = "${directory?.path}/$fileName";

      await dio.post(
        apiUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/pdf",
            "Content-Type": "application/json",
          },
        ),
        onReceiveProgress: (count, total) {
          double progress = (count / total);
          onProgress(progress);
        },
      ).then((response) async {
        if (response.statusCode == 200) {
          File file = File(filePath);
          await file.writeAsBytes(response.data);
          print("✅ PDF saved at: $filePath");
          OpenFilex.open(filePath);
          onComplete(null);
        } else {
          print("❌ Failed to download PDF. Status Code: ${response.statusCode}");
          onComplete("Failed to download.");
        }
      });
    } catch (e) {
      print("❌ Error downloading PDF: $e");
      onComplete("Error downloading PDF.");
    }
  }
}

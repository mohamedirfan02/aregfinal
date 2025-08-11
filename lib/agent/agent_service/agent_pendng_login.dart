import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';
import '../agent_screen/agent_login_request.dart';

Future<List<NewAgent>> fetchPendingAgents() async {
  const String url = ApiConfig.new_agent;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final List<dynamic> data = jsonData['data'];
      return data.map((e) => NewAgent.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load agents');
    }
  } catch (e) {
    print('Error fetching agents: $e');
    return [];
  }
}

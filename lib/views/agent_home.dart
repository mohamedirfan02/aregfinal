import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AgentPage extends StatelessWidget {
  final Map<String, dynamic> agentDetails;

  const AgentPage({super.key, required this.agentDetails});

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final fullName = agentDetails['full_name'] ?? 'Agent';
    final email = agentDetails['email'] ?? 'No Email';
    final age = agentDetails['age'] ?? 'Not specified';
    final gender = agentDetails['gender'] ?? 'Not specified';
    final contactNumber = agentDetails['contact_number'] ?? 'Not specified';

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome $fullName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Full Name: $fullName'),
            Text('Email: $email'),
            Text('Age: $age'),
            Text('Gender: $gender'),
            Text('Contact Number: $contactNumber'),
          ],
        ),
      ),
    );
  }
}

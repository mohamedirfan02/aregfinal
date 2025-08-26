import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF006D04),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Effective Date: May 30, 2025',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 24),
            _PolicySection(
              title: '1. Introduction',
              content:
              'Welcome to Enzopik, developed by areg@enzopik. We value your privacy and are committed to protecting your personal information. This Privacy Policy explains how we collect, use, and safeguard your data when you use our mobile application.',
            ),
            SizedBox(height: 24),
            _PolicySection(
              title: '2. Information We Collect',
              content:
              'Personal Information: such as your name, email address, and phone number (if voluntarily provided).\n\nDevice Information: including device model, operating system version, unique device identifiers.\n\nUsage Data: such as IP address, app interactions, crash logs, and feature usage patterns.\n\nLocation Data: We may collect and process precise or live location data from your device to provide location-based services. This includes GPS data. You can control location permissions through your device settings.',
            ),
            SizedBox(height: 24),
            _PolicySection(
              title: '3. How We Use Your Information',
              content:
              'We use the information collected through Enzopik to:\n\n• Provide core app functionality and improve performance.\n• Respond to user inquiries and support requests.\n• Analyze app usage to enhance user experience.\n• Ensure the security and integrity of our services.',
            ),
            SizedBox(height: 24),
            _PolicySection(
              title: '4. Data Sharing and Security',
              content:
              'We do not share your personal information with third parties except as required by law or with your explicit consent. We implement industry-standard security measures to protect your data from unauthorized access or disclosure.',
            ),
            SizedBox(height: 24),
            _PolicySection(
              title: '5. Your Rights and Choices',
              content:
              'You have the right to:\n\n• Access the personal data we hold about you.\n• Request correction or deletion of your data.\n• Withdraw consent for data processing where applicable.\n\nTo exercise any of these rights, please contact us at founder@thikse.org.',
            ),
            SizedBox(height: 24),
            _PolicySection(
              title: '6. Children\'s Privacy',
              content:
              'Enzopik is not intended for children under the age of 13. We do not knowingly collect personal information from children. If you believe your child has provided personal data, please contact us immediately.',
            ),
            SizedBox(height: 24),
            _PolicySection(
              title: '7. Changes to This Policy',
              content:
              'We may update this Privacy Policy periodically to reflect changes in our practices or legal obligations. We encourage you to review this page regularly. Updates will be posted here with a revised effective date.',
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;

  const _PolicySection({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

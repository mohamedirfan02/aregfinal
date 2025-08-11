import 'package:flutter/material.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({Key? key}) : super(key: key);

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String? selectedLanguage;

  final List<String> suggestedLanguages = ['English(US)', 'English(UK)'];
  final List<String> otherLanguages = [
    'Tamil',
    'Marathi',
    'Hindi',
    'Telugu',
    'Malayalam',
    'Kanadam',
    'Bengali',
    'Gujarati',
    'Odia',
    'Punjabi',
  ];

  void _onLanguageSelected(String? language) {
    if (language != null) {
      setState(() {
        selectedLanguage = language;
      });
    }
  }


  void _onSubmit() {
    if (selectedLanguage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Language set to: $selectedLanguage')),
      );
    }
  }

  Widget _buildLanguageTile(String language) {
    return RadioListTile<String>(
      value: language,
      groupValue: selectedLanguage,
      onChanged: _onLanguageSelected,
      title: Text(language),
      activeColor: const Color(0xFF7FBF08), // Green active color
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitEnabled = selectedLanguage != null;

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
          'Language',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Suggested',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...suggestedLanguages.map(_buildLanguageTile).toList(),
            const Divider(),
            const Text(
              'Other',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView(
                children: otherLanguages.map(_buildLanguageTile).toList(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitEnabled ? _onSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSubmitEnabled
                      ? const Color(0xFF006D04)
                      : Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Submit',
                  style: TextStyle(
                    color: isSubmitEnabled ? Colors.white :Color(0xFF006D04),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

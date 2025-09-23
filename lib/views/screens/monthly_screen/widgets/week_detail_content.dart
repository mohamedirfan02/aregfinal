// widgets/week_detail_content.dart
import 'package:flutter/material.dart';
import 'details_list.dart';

class WeekDetailContent extends StatelessWidget {
  final Map<String, dynamic> week;

  const WeekDetailContent({Key? key, required this.week}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final oilTypes = (week['oil_types'] ?? []) as List<dynamic>;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOilTypesChips(oilTypes, isDarkMode),
        const SizedBox(height: 12),
        _buildInfoBoxes(isDarkMode),
        const SizedBox(height: 12),
        DetailsList(details: week['details'] ?? []),
      ],
    );
  }

  Widget _buildOilTypesChips(List<dynamic> oilTypes, bool isDarkMode) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: oilTypes.map((oil) {
        return Chip(
          backgroundColor: isDarkMode
              ? const Color(0xFF2C2C2C)
              : const Color(0xFFF4FBF2),
          label: Text(
            "${oil['type']}: ${oil['quantity']} Kg",
            style: TextStyle(
              color: isDarkMode ? Colors.white : const Color(0xFF006D04),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoBoxes(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildInfoBox("Online Transfer", week['online'].toString(), isDarkMode),
        _buildInfoBox("Cash Amount", week['cash'].toString(), isDarkMode),
      ],
    );
  }

  Widget _buildInfoBox(String label, String value, bool isDarkMode) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.white60 : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : const Color(0xFF006D04),
          ),
        ),
      ],
    );
  }
}
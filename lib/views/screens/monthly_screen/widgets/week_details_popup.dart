// widgets/week_details_popup.dart
import 'package:flutter/material.dart';
import 'week_detail_content.dart';

class WeekDetailsPopup {
  static void show(BuildContext context, Map<String, dynamic> week) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDragHandle(),
              _buildHeader(week),
              const Divider(height: 24),
              WeekDetailContent(week: week),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 50,
        height: 5,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }

  static Widget _buildHeader(Map<String, dynamic> week) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${week['week']?.toUpperCase() ?? 'Week'} - ₹${week['revenue']}",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF006D04),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Total Oil: ${week['quantity']} Kg",
          style: const TextStyle(fontSize: 14, color: Color(0xFF7FBF08)),
        ),
      ],
    );
  }
}
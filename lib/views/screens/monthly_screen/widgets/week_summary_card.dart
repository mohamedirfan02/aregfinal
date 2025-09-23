// widgets/week_summary_card.dart
import 'package:flutter/material.dart';
import 'week_detail_content.dart';
import 'week_details_popup.dart';

class WeekSummaryCard extends StatelessWidget {
  final Map<String, dynamic> week;

  const WeekSummaryCard({Key? key, required this.week}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Card(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: isTablet
              ? _buildTabletView(context, isDarkMode)
              : _buildMobileView(isDarkMode),
        ),
      ),
    );
  }

  Widget _buildTabletView(BuildContext context, bool isDarkMode) {
    return InkWell(
      onTap: () => WeekDetailsPopup.show(context, week),
      child: ListTile(
        title: Text(
          "${week['week']?.toUpperCase() ?? 'Week'} - Revenue: ₹${week['revenue'] ?? 0}",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : const Color(0xFF006D04),
          ),
        ),
        subtitle: Text(
          "Total Oil: ${week['quantity'] ?? 0} Kg",
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.white70 : const Color(0xFF006D04),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      ),
    );
  }

  Widget _buildMobileView(bool isDarkMode) {
    return ExpansionTile(
      title: Text(
        "${week['week']?.toUpperCase() ?? 'Week'} - Revenue: ₹${week['revenue'] ?? 0}",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : const Color(0xFF006D04),
        ),
      ),
      subtitle: Text(
        "Total Oil: ${week['quantity'] ?? 0} Kg",
        style: TextStyle(
          fontSize: 14,
          color: isDarkMode ? Colors.white70 : const Color(0xFF006D04),
        ),
      ),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        WeekDetailContent(week: week),
      ],
    );
  }
}
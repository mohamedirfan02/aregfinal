// widgets/weekly_revenue_chart.dart
import 'package:areg_app/views/screens/monthly_screen/utils/chart_utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeeklyRevenueChart extends StatelessWidget {
  final List<dynamic> weeklyData;

  const WeeklyRevenueChart({Key? key, required this.weeklyData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: isDarkMode
                  ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF7FBF08),
                  const Color(0xFF6A9600),
                ],
              )
                  : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFFFDF7),
                  const Color(0xFFF8F5E8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.3)
                      : const Color(0xFF7FBF08).withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white.withOpacity(0.8),
                  blurRadius: 10,
                  offset: const Offset(-5, -5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPremiumHeader(isDarkMode),
                const SizedBox(height: 8),
                _buildTotalRevenue(screenWidth, isDarkMode),
                const SizedBox(height: 20),
                _buildChartContainer(screenWidth, isDarkMode),
                const SizedBox(height: 20),
                _buildPremiumSummaryRow(isDarkMode),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumHeader(bool isDarkMode) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF7FBF08),
                const Color(0xFF6A9600),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.oil_barrel_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Used Oil Collection Revenue",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : const Color(0xFF6A9600),
              ),
            ),
            Text(
              "Monthly Performance Overview",
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white60 : const Color(0xFF6A9600),
              ),
            ),
          ],
        ),
        const Spacer(),
        _buildTrendIndicator(isDarkMode),
      ],
    );
  }

  Widget _buildTrendIndicator(bool isDarkMode) {
    final isIncreasing = weeklyData.length > 1 &&
        weeklyData.last['revenue'] >= weeklyData[weeklyData.length - 2]['revenue'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isIncreasing
            ? const Color(0xFF4CAF50).withOpacity(0.1)
            : const Color(0xFFFF5252).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isIncreasing
              ? const Color(0xFF4CAF50).withOpacity(0.3)
              : const Color(0xFFFF5252).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isIncreasing ? Icons.trending_up : Icons.trending_down,
            color: isIncreasing ? const Color(0xFF4CAF50) : const Color(0xFFFF5252),
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            isIncreasing ? "↗" : "↘",
            style: TextStyle(
              color: isIncreasing ? const Color(0xFF4CAF50) : const Color(0xFFFF5252),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRevenue(double screenWidth, bool isDarkMode) {
    final totalRevenue = ChartUtils.sumByField(weeklyData, 'revenue');

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    const Color(0xFF7FBF08),
                    const Color(0xFF6A9600),
                  ],
                ).createShader(bounds),
                child: Text(
                  "₹${NumberFormat('#,##0').format(totalRevenue)}",
                  style: TextStyle(
                    fontSize: screenWidth < 360 ? 24 : 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                "${weeklyData.length} weeks of data",
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white60 : const Color(0xFF6A9600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartContainer(double screenWidth, bool isDarkMode) {
    return Container(
      height: screenWidth < 400 ? 200 : 250,
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.black.withOpacity(0.3)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : const Color(0xFF6A9600).withOpacity(0.2),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: _buildPremiumLineChart(screenWidth, isDarkMode),
    );
  }

  Widget _buildPremiumLineChart(double screenWidth, bool isDarkMode) {
    List<FlSpot> revenueSpots = [];
    List<FlSpot> quantitySpots = [];
    double maxRevenue = 0;
    double maxQuantity = 0;

    for (int i = 0; i < weeklyData.length; i++) {
      final revenue = (weeklyData[i]['revenue'] ?? 0).toDouble();
      final quantity = (weeklyData[i]['quantity'] ?? 0).toDouble();

      revenueSpots.add(FlSpot(i.toDouble(), revenue));
      quantitySpots.add(FlSpot(i.toDouble(), quantity * 20)); // Scale quantity for visibility

      if (revenue > maxRevenue) maxRevenue = revenue;
      if (quantity * 20 > maxQuantity) maxQuantity = quantity * 20;
    }

    final maxY = [maxRevenue, maxQuantity].reduce((a, b) => a > b ? a : b) * 1.2;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: weeklyData.length < 4 ? screenWidth - 100 : weeklyData.length * 80,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : const Color(0xFF6A9600).withOpacity(0.2),
                strokeWidth: 1,
                dashArray: [5, 5],
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  interval: maxY / 4,
                  getTitlesWidget: (value, _) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '₹${(value / 1000).toStringAsFixed(0)}k',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white60 : const Color(0xFF6A9600),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 40,
                  getTitlesWidget: (value, _) {
                    final index = value.toInt();
                    if (index >= 0 && index < weeklyData.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'W${index + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDarkMode ? Colors.white70 : const Color(0xFF6A9600),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${weeklyData[index]['quantity']}kg',
                              style: TextStyle(
                                fontSize: 8,
                                color: isDarkMode ? Colors.white70 : const Color(0xFF6A9600),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              // Revenue line
              LineChartBarData(
                spots: revenueSpots,
                isCurved: true,
                curveSmoothness: 0.35,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF7FBF08),
                    const Color(0xFFC3E029),
                  ],
                ),
                barWidth: 4,
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF7FBF08).withOpacity(0.3),
                      const Color(0xFFC3E029).withOpacity(0.05),
                    ],
                  ),
                ),
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 6,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: const Color(0xFF7FBF08),
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
              //  tooltipBgColor: isDarkMode ? Colors.grey[800] : Colors.white,
                tooltipRoundedRadius: 12,
                tooltipPadding: const EdgeInsets.all(8),
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final weekIndex = spot.x.toInt();
                    if (weekIndex >= 0 && weekIndex < weeklyData.length) {
                      final week = weeklyData[weekIndex];
                      return LineTooltipItem(
                        'Week ${weekIndex + 1}\n₹${week['revenue']}\n${week['quantity']}kg oil',
                        TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      );
                    }
                    return null;
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumSummaryRow(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.black.withOpacity(0.2)
            : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : const Color(0xFF7FBF08).withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPremiumSummaryCard(
            "Online Payments",
            ChartUtils.sumByField(weeklyData, 'online'),
            Icons.credit_card,
            const Color(0xFF4CAF50),
            isDarkMode,
          ),
          Container(
            height: 40,
            width: 1,
            color: isDarkMode ? Colors.white.withOpacity(0.2) : const Color(0xFF7FBF08).withOpacity(0.3),
          ),
          _buildPremiumSummaryCard(
            "Cash Payments",
            ChartUtils.sumByField(weeklyData, 'cash'),
            Icons.money,
            const Color(0xFF6A9600),
            isDarkMode,
          ),
          Container(
            height: 40,
            width: 1,
            color: isDarkMode ? Colors.white.withOpacity(0.2) : const Color(0xFF7FBF08).withOpacity(0.3),
          ),
          _buildPremiumSummaryCard(
            "Total Oil",
            ChartUtils.sumByField(weeklyData, 'quantity'),
            Icons.oil_barrel,
            const Color(0xFF7FBF08),
            isDarkMode,
            suffix: "kg",
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSummaryCard(
      String label,
      int value,
      IconData icon,
      Color color,
      bool isDarkMode,
      {String suffix = ""}
      ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            suffix.isEmpty ? "₹$value" : "$value$suffix",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFFC3E029),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDarkMode ? Colors.white60 : const Color(0xFFC3E029),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
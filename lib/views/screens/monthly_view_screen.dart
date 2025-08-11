import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../../common/custom_appbar.dart';
import '../../fbo_services/monthly_sale_service.dart';

class MonthlyViewPage extends StatefulWidget {
  final int month;

  const MonthlyViewPage({Key? key, required this.month}) : super(key: key);

  @override
  _MonthlyViewPageState createState() => _MonthlyViewPageState();
}

class _MonthlyViewPageState extends State<MonthlyViewPage> {
  bool isLoading = true;
  bool hasError = false;
  List<dynamic> weeklyData = [];
  bool isEmptyData = false;

  @override
  void initState() {
    super.initState();
    _fetchMonthlyData();
  }

  final ThemeData appTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF006D04),
    hintColor: const Color(0xFFB2DFDB),
    scaffoldBackgroundColor: Colors.white,
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF006D04),
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF4FBF2),
      labelStyle: const TextStyle(color: Color(0xFF006D04)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );

  final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF006D04),
    hintColor: const Color(0xFFB2DFDB),
    scaffoldBackgroundColor: Colors.black,
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        color: Colors.white70,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      labelStyle: const TextStyle(color: Color(0xFFB2DFDB)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
    ),
  );
  Future<void> _fetchMonthlyData() async {
    final data = await MonthlySaleService.fetchMonthlyData(widget.month);

    if (data != null && data["status"] == "success") {
      final dynamic rawData = data["data"];

      setState(() {
        if (rawData is List && rawData.isEmpty) {
          isEmptyData = true;
        } else if (rawData is List && rawData.isNotEmpty) {
          weeklyData = rawData;
        } else {
          weeklyData = [];
        }
        isLoading = false;
      });
    } else {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
   // final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
          ? Center(
        child: Text(
          "❌ Failed to load data",
          style: TextStyle(color: Colors.red.shade400),
        ),
      )
          : isEmptyData
          ? _buildEmptyUI()
          : _buildResponsiveLayout(context),
    );
  }

  // Widget _buildWeeklyListView() {
  //   return ListView.builder(
  //     itemCount: weeklyData.length,
  //     itemBuilder: (context, index) {
  //       final week = weeklyData[index];
  //       return _buildWeekSummaryCard(week);
  //     },
  //   );
  // }
  Widget _buildWeekSummaryCard(Map<String, dynamic> week) {
    //final oilTypes = (week['oil_types'] ?? []) as List<dynamic>;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return _buildAnimatedCard(
      Card(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: isTablet
              ? InkWell(
            onTap: () => _showWeekDetailsPopup(context, week),
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
          )
              : ExpansionTile(
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
              _buildWeekDetailContent(week),
            ],
          ),
        ),
      ),
    );
  }

  void _showWeekDetailsPopup(BuildContext context, Map<String, dynamic> week) {
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
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
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
              const Divider(height: 24),
              _buildWeekDetailContent(week),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildWeekDetailContent(Map<String, dynamic> week) {
    final oilTypes = (week['oil_types'] ?? []) as List<dynamic>;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
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
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildInfoBox("Online Transfer", week['online'].toString(), isDarkMode),
            _buildInfoBox("Cash Amount", week['cash'].toString(), isDarkMode),
          ],
        ),
        const SizedBox(height: 12),
        _buildDetailsList(context, week['details'] ?? []),
      ],
    );
  }


  Widget _buildWeeklyRevenueChart() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;

        return Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 700), // limit max width on wide screens
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FCFF),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "Total Revenue",
                      style: TextStyle(fontSize: 14, color: Color(0xFF7FBF08)),
                    ),
                    const Spacer(),
                    Icon(
                      weeklyData.length > 1 &&
                          weeklyData.last['revenue'] < weeklyData[weeklyData.length - 2]['revenue']
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: weeklyData.length > 1 &&
                          weeklyData.last['revenue'] < weeklyData[weeklyData.length - 2]['revenue']
                          ? Colors.red
                          : Color(0xFF006D04),
                      size: 20,
                    )
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "₹${NumberFormat('#,##0').format(_sumByField('revenue'))}",
                  style: TextStyle(
                    fontSize: screenWidth < 360 ? 20 : 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF006D04),
                  ),
                ),
                const SizedBox(height: 12),
                AspectRatio(
                  aspectRatio: screenWidth < 400 ? 1.2 : 1.6,
                  child: _buildLineChart(screenWidth),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildChartSummary("Online", _sumByField('online')),
                    _buildChartSummary("Cash", _sumByField('cash')),
                    _buildChartSummary("Total Oil", _sumByField('quantity')),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _buildLineChart(double screenWidth) {
    List<FlSpot> revenueSpots = [];
    double maxRevenue = 0;

    for (int i = 0; i < weeklyData.length; i++) {
      final revenue = (weeklyData[i]['revenue'] ?? 0).toDouble();
      revenueSpots.add(FlSpot(i.toDouble(), revenue));
      if (revenue > maxRevenue) maxRevenue = revenue;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 8),
      child: SizedBox(
        width: weeklyData.length * 60, // Dynamic width based on weeks
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxRevenue * 1.2,
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, _) => Text('${value.toInt()}'),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 36,
                  getTitlesWidget: (value, _) {
                    final index = value.toInt();
                    if (index >= 0 && index < weeklyData.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Week ${index + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7FBF08),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: revenueSpots,
                isCurved: true,
                color: const Color(0xFF006D04),
                barWidth: 3,
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFF006D04).withOpacity(0.1),
                ),
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: const Color(0xFF006D04),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartSummary(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold,color:Color(0xFF006D04), fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color:Color(0xFF7FBF08), fontSize: 12,fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
  int _sumByField(String field) {
    return weeklyData.fold<int>(
      0,
          (sum, item) => sum + ((item[field] ?? 0) as num).toInt(),
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
  Widget _buildDetailsList(BuildContext context, List<dynamic> details) {
    final screenHeight = MediaQuery.of(context).size.height;
    //final maxHeight = screenHeight * 0.5; // max 50% of screen height

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: details.length,
        separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
        itemBuilder: (context, index) {
          final detail = details[index];
          final oilTypes = (detail['oil_types'] ?? []) as List<dynamic>;
          final oilName = oilTypes.isNotEmpty ? oilTypes[0]['type'] ?? 'Unknown Oil' : 'Unknown Oil';
          final oilQuantity = detail['quantity']?.toString() ?? '0';
          final date = detail['date'] ?? '';
          final time = detail['time']?.substring(0, 5) ?? '';
          final online = detail['online'] ?? 0;
          final cash = detail['cash'] ?? 0;
          final totalAmount = online + cash;

          // Adapt font size by screen height (smaller on smaller screens)
          double baseFontSize = screenHeight < 600 ? 12 : 14;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2), // reduced vertical padding
            title: Text(
              "$date at $time",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF006D04),
                fontSize: baseFontSize + 2,
              ),
            ),
            subtitle: Text(
              "Oil: $oilName \nQuantity: $oilQuantity Kg",
              style: TextStyle(
                color: const Color(0xFF7FBF08),
                fontSize: baseFontSize,
              ),
            ),
            trailing: SizedBox(
              height: 56,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Online: $online",
                      style: TextStyle(
                        color: const Color(0xFF006D04),
                        fontSize: 12,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      "Cash: $cash",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      "Total: $totalAmount",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }





  Widget _buildEmptyUI() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset("assets/animations/empty.json", width: 200),
          const SizedBox(height: 10),
          const Text(
            "No Data Available",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          const Text("There is no sales data available for this month."),
        ],
      ),
    );
  }
  Widget _buildAnimatedCard(Widget child) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: child,
    );
  }
  Widget _buildResponsiveLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final chart = _buildWeeklyRevenueChart();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          chart,
          const SizedBox(height: 12),
          screenWidth < 600
              ? Column(
            children: weeklyData.map((week) => _buildWeekSummaryCard(week)).toList(),
          )
              : GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 320,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: weeklyData.length,
            itemBuilder: (context, index) {
              final week = weeklyData[index];
              return _buildWeekSummaryCard(week);
            },
          ),
        ],
      ),
    );
  }

}

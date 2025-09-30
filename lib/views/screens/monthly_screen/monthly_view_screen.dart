// monthly_view_page.dart
import 'package:areg_app/agent/common/common_appbar.dart';
import 'package:areg_app/common/app_colors.dart';
import 'package:areg_app/common/custom_appbar.dart';
import 'package:areg_app/core/storage/app_assets_constant.dart';
import 'package:areg_app/fbo_services/monthly_sale_service.dart';
import 'package:areg_app/views/screens/widgets/k_svg.dart';
import 'package:flutter/material.dart';
import 'widgets/weekly_revenue_chart.dart';
import 'widgets/week_summary_card.dart';
import 'widgets/empty_data_widget.dart';

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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: CommonAppbar(title: "Monthly History"),
      ),
      body: isLoading
          ? const Center(child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.fboColor), // ✅ custom color
          ),
          KSvg(
            svgPath: AppAssetsConstants.splashLogo,
            height: 30,
            width: 30,
            boxFit: BoxFit.cover,
          ),
        ],
      ),)
          : hasError
          ? Center(
        child: Text(
          "❌ Failed to load data",
          style: TextStyle(color: Colors.red.shade400),
        ),
      )
          : isEmptyData
          ? const EmptyDataWidget()
          : _buildResponsiveLayout(context),
    );
  }

  Widget _buildResponsiveLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final chart = WeeklyRevenueChart(weeklyData: weeklyData);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          chart,
          const SizedBox(height: 12),
          screenWidth < 600
              ? Column(
            children: weeklyData
                .map((week) => WeekSummaryCard(week: week))
                .toList(),
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
              return WeekSummaryCard(week: week);
            },
          ),
        ],
      ),
    );
  }
}
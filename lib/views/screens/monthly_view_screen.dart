import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../common/custom_GradientContainer.dart';
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
  Map<String, dynamic>? monthlyData;
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
          monthlyData = rawData[0];
        } else {
          monthlyData = {};
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
    return GradientContainer(
     child:  Scaffold(
        backgroundColor: Colors.transparent, // Keep transparency for gradient
       appBar: CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : hasError
            ? const Center(
            child: Text("❌ Failed to load data", style: TextStyle(color: Colors.red)))
            : isEmptyData
            ? _buildEmptyUI()
            : _buildMonthlyDataView(),
      ),
      ),
    );
  }
  Widget _buildEmptyUI() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min, // Prevent unnecessary stretching
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





  Widget _buildMonthlyDataView() {
    if (monthlyData == null || monthlyData!.isEmpty) {
      return _buildEmptyUI();
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildPaymentStats(),
          const SizedBox(height: 20),
          _buildOilDetails(),
          const SizedBox(height: 20),
          _buildTransactionList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade300, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Total Balance > ${_getMonthName(widget.month)} 2025",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "₹${monthlyData?['revenue'] ?? 0}",
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              CircleAvatar(
                backgroundColor: Colors.green.shade100,
                radius: 30,
                child: Text(
                  "${monthlyData?['quantity'] ?? 0} KG",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatBox("Online Pay", monthlyData?['online'] ?? 0, Colors.blueAccent),
        _buildStatBox("Cash Pay", monthlyData?['cash'] ?? 0, Colors.orangeAccent),
      ],
    );
  }

  Widget _buildStatBox(String label, int amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            Text("₹$amount", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: (amount / 10000).clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade300,
              color: color,
              minHeight: 6,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOilDetails() {
    List<dynamic> oilTypes = monthlyData?['oil_types'] ?? [];
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 8)],
      ),
      child: Column(
        children: oilTypes.map((oil) {
          return _buildOilItem(oil['type'], "${oil['quantity']} KG");
        }).toList(),
      ),
    );
  }

  Widget _buildOilItem(String name, String quantity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          CircleAvatar(radius: 6, backgroundColor: Colors.green),
          const SizedBox(width: 8),
          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(quantity, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    List<dynamic> transactions = monthlyData?['details'] ?? [];
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        var detail = transactions[index];
        List<dynamic> oilDetails = detail['oil_types'] ?? [];
        String oilInfo = oilDetails.map((oil) => "${oil['type']} / ${oil['quantity']} KG").join("\n");

        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${detail['date']}, ${detail['time'].substring(0, 5)}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(oilInfo, style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text("Total Kg: ${detail['quantity']}", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    return ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][month - 1];
  }
}

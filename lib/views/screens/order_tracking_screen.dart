import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';

void main() => runApp(MaterialApp(home: OrderTrackingScreen()));

class OrderTrackingScreen extends StatefulWidget {
  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final List<OrderStep> orderSteps = [
    OrderStep("Request Placed", "April 2, 2025 - 10:00 AM", true),
    OrderStep("Request Confirmed", "April 2, 2025 - 11:30 AM", true),
    OrderStep("Accepted by Agent", "April 3, 2025 - 9:00 AM", true),
    OrderStep("Assumed Pick Date", "April 4, 2025 - 8:00 AM", false),
    OrderStep("Collected", "", false),
  ];

  List<bool> _visibleList = [];

  @override
  void initState() {
    super.initState();
    _visibleList = List.generate(orderSteps.length, (_) => false);
    _runAnimation();
  }

  void _runAnimation() async {
    for (int i = 0; i < orderSteps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) {
        setState(() {
          _visibleList[i] = true;
        });
      }
    }
  }

  void _handleCancel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Request"),
        content: const Text("Are you sure you want to cancel this request?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Request Cancelled")),
              );
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track Order')),
      body: ListView.builder(
        itemCount: orderSteps.length,
        itemBuilder: (context, index) {
          final step = orderSteps[index];
          final isFirst = index == 0;
          final isLast = index == orderSteps.length - 1;
          final isActive = step.isCompleted;

          return AnimatedOpacity(
            opacity: _visibleList[index] ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: Column(
              children: [
                TimelineTile(
                  alignment: TimelineAlign.manual,
                  lineXY: 0.1,
                  isFirst: isFirst,
                  isLast: isLast,
                  beforeLineStyle: LineStyle(
                    color: isActive ? Colors.green : Colors.grey,
                    thickness: 6,
                  ),
                  indicatorStyle: IndicatorStyle(
                    width: 30,
                    color: isActive ? Colors.green : Colors.grey,
                    iconStyle: IconStyle(
                      iconData: isActive
                          ? Icons.check
                          : Icons.radio_button_unchecked,
                      color: Colors.white,
                    ),
                  ),
                  endChild: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        if (isActive)
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isActive
                                ? Colors.black
                                : Colors.grey.shade700,
                            fontSize: 16,
                          ),
                        ),
                        if (step.time.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              step.time,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (index == 2)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 10),
                    child: ElevatedButton(
                      onPressed: _handleCancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 24),
                        shadowColor: Colors.redAccent.withOpacity(0.5),
                      ),
                      child: const Text(
                        "Cancel Request",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class OrderStep {
  final String title;
  final String time;
  final bool isCompleted;

  OrderStep(this.title, this.time, this.isCompleted);
}

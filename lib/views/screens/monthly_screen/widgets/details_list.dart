// widgets/details_list.dart
import 'package:flutter/material.dart';

class DetailsList extends StatelessWidget {
  final List<dynamic> details;

  const DetailsList({Key? key, required this.details}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: details.length,
        separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
        itemBuilder: (context, index) {
          final detail = details[index];
          return _buildDetailItem(context, detail);
        },
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, Map<String, dynamic> detail) {
    final screenHeight = MediaQuery.of(context).size.height;
    final oilTypes = (detail['oil_types'] ?? []) as List<dynamic>;
    final oilName = oilTypes.isNotEmpty ? oilTypes[0]['type'] ?? 'Unknown Oil' : 'Unknown Oil';
    final oilQuantity = detail['quantity']?.toString() ?? '0';
    final date = detail['date'] ?? '';
    final time = detail['time']?.substring(0, 5) ?? '';
    final online = detail['online'] ?? 0;
    final cash = detail['cash'] ?? 0;
    final totalAmount = online + cash;

    double baseFontSize = screenHeight < 600 ? 12 : 14;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
                style: const TextStyle(
                  color: Color(0xFF006D04),
                  fontSize: 12,
                  height: 1.1,
                ),
              ),
              Text(
                "Cash: $cash",
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  height: 1.1,
                ),
              ),
              Text(
                "Total: $totalAmount",
                style: const TextStyle(
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
  }
}
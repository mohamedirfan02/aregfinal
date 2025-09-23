// utils/chart_utils.dart
class ChartUtils {
  /// Sums up values for a specific field in the weekly data
  static int sumByField(List<dynamic> weeklyData, String field) {
    return weeklyData.fold<int>(
      0,
          (sum, item) => sum + ((item[field] ?? 0) as num).toInt(),
    );
  }

  /// Calculates the maximum value for a specific field
  static double getMaxValue(List<dynamic> weeklyData, String field) {
    double max = 0;
    for (var item in weeklyData) {
      final value = (item[field] ?? 0).toDouble();
      if (value > max) max = value;
    }
    return max;
  }

  /// Gets the trend direction based on recent data
  static bool isIncreasing(List<dynamic> weeklyData, String field) {
    if (weeklyData.length < 2) return true;

    final current = weeklyData.last[field] ?? 0;
    final previous = weeklyData[weeklyData.length - 2][field] ?? 0;

    return current >= previous;
  }
}
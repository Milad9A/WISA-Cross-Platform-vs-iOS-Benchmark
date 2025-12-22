import 'dart:math';

/// Utility class for statistical calculations
class StatisticsUtils {
  StatisticsUtils._();

  /// Calculate the average of a list of integers
  static double average(List<int> values) {
    if (values.isEmpty) return 0;
    final sum = values.fold<int>(0, (sum, value) => sum + value);
    return sum / values.length;
  }

  /// Calculate the minimum value
  static int min(List<int> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a < b ? a : b);
  }

  /// Calculate the maximum value
  static int max(List<int> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a > b ? a : b);
  }

  /// Calculate the standard deviation
  static double standardDeviation(List<int> values) {
    if (values.length < 2) return 0;
    final avg = average(values);
    final sumSquares = values.fold<double>(
      0,
      (sum, value) => sum + (value - avg) * (value - avg),
    );
    return sqrt(sumSquares / values.length);
  }

  /// Format microseconds to milliseconds string
  static String formatMicroseconds(int microseconds) {
    return '${(microseconds / 1000).toStringAsFixed(2)} ms';
  }

  /// Format microseconds to milliseconds with 1 decimal
  static String formatMicrosecondsShort(double microseconds) {
    return '${(microseconds / 1000).toStringAsFixed(1)}ms';
  }

  /// Format time as HH:MM:SS
  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }
}

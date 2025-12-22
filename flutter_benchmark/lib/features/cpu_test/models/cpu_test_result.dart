/// Model class representing a CPU test result
class CPUTestResult {
  final int executionTimeUs;
  final int primeCount;
  final DateTime timestamp;

  const CPUTestResult({
    required this.executionTimeUs,
    required this.primeCount,
    required this.timestamp,
  });

  /// Execution time in milliseconds
  double get executionTimeMs => executionTimeUs / 1000;

  /// Format execution time as string
  String get formattedTime => '${executionTimeMs.toStringAsFixed(2)} ms';

  /// Check if the result is valid (correct prime count)
  bool get isValid => primeCount == 78498;
}

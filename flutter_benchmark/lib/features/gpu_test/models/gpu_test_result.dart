/// Model class representing GPU test results
class GPUTestResult {
  final int totalFrameCount;
  final int droppedFrameCount;
  final double averageFrameTimeUs;
  final int maxFrameTimeUs;
  final int? batteryStart;
  final int? batteryEnd;
  final DateTime timestamp;

  const GPUTestResult({
    required this.totalFrameCount,
    required this.droppedFrameCount,
    required this.averageFrameTimeUs,
    required this.maxFrameTimeUs,
    this.batteryStart,
    this.batteryEnd,
    required this.timestamp,
  });

  /// Calculate jank percentage
  double get jankPercentage =>
      totalFrameCount > 0 ? (droppedFrameCount / totalFrameCount) * 100 : 0;

  /// Calculate estimated FPS
  double get estimatedFps =>
      averageFrameTimeUs > 0 ? 1000000 / averageFrameTimeUs : 0;

  /// Average frame time in milliseconds
  double get averageFrameTimeMs => averageFrameTimeUs / 1000;

  /// Max frame time in milliseconds
  double get maxFrameTimeMs => maxFrameTimeUs / 1000;

  /// Battery drain percentage
  String get batteryDrain {
    if (batteryStart != null && batteryEnd != null) {
      return '${batteryStart! - batteryEnd!}%';
    }
    return 'N/A';
  }

  /// Check if performance is good (FPS >= 55)
  bool get isGoodPerformance => estimatedFps >= 55;

  /// Check if jank rate is acceptable (<5%)
  bool get isAcceptableJank => jankPercentage < 5;
}

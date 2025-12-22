/// Benchmark configuration constants
///
/// These values are used to ensure identical test conditions
/// between Flutter and Native iOS implementations.
class BenchmarkConfig {
  BenchmarkConfig._();

  // CPU Test Configuration
  static const int sievePrimeLimit = 1000000; // 1 million
  static const int expectedPrimeCount = 78498; // Known result for validation
  static const int maxTestHistory = 10;

  // GPU Test Configuration
  static const int gpuTestItemCount = 1000;
  static const int scrollDurationSeconds = 30;
  static const int imageCycleCount = 10;
  static const double listCacheExtent = 200.0;

  // FPS Configuration
  static const int targetFrameTimeUs = 16667; // 60 FPS = 16.67ms per frame
  static const int jankThresholdUs = 16667; // >16.67ms is considered jank
  static const double goodFpsThreshold = 55.0;
  static const double jankPercentageThreshold = 5.0;

  // Image paths
  static String getImagePath(int index) => 'assets/images/img_$index.jpg';
}

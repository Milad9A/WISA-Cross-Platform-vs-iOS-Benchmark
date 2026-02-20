import 'package:flutter/services.dart';

/// Service for getting memory usage via platform channel
class MemoryService {
  static const _channel = MethodChannel('flutter_benchmark/memory');

  /// Get current memory usage in bytes
  /// Returns null if unavailable
  static Future<int?> getMemoryUsageBytes() async {
    try {
      final result = await _channel.invokeMethod<int>('getMemoryUsage');
      return result;
    } catch (e) {
      return null;
    }
  }

  /// Get current memory usage in megabytes
  /// Returns null if unavailable
  static Future<double?> getMemoryUsageMB() async {
    final bytes = await getMemoryUsageBytes();
    if (bytes != null) {
      return bytes / (1024 * 1024);
    }
    return null;
  }
}

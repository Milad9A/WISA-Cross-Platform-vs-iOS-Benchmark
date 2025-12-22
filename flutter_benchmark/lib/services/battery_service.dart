import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service for accessing device battery level via platform channel
class BatteryService {
  static const MethodChannel _channel = MethodChannel(
    'flutter_benchmark/battery',
  );

  /// Get the current battery level as a percentage (0-100)
  /// Returns null if battery level is not available
  static Future<int?> getBatteryLevel() async {
    try {
      final int level = await _channel.invokeMethod('getBatteryLevel');
      return level;
    } on PlatformException catch (e) {
      debugPrint('Battery level not available: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Battery level error: $e');
      return null;
    }
  }

  /// Calculate battery drain between two measurements
  static String calculateDrain(int? startLevel, int? endLevel) {
    if (startLevel != null && endLevel != null) {
      final int delta = startLevel - endLevel;
      return '$delta%';
    }
    return 'N/A';
  }
}

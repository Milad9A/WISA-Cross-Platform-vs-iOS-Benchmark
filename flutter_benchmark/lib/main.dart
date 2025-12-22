import 'package:flutter/material.dart';
import 'app.dart';

/// Global timestamp for app startup measurement
final int appStartTimestamp = DateTime.now().microsecondsSinceEpoch;

void main() {
  // Record the exact start time when main() is called
  final int mainStartTime = DateTime.now().microsecondsSinceEpoch;

  WidgetsFlutterBinding.ensureInitialized();

  runApp(BenchmarkApp(mainStartTime: mainStartTime));
}

import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';

/// Main application widget
class BenchmarkApp extends StatelessWidget {
  final int mainStartTime;

  const BenchmarkApp({super.key, required this.mainStartTime});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Benchmark',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      theme: AppTheme.lightTheme,
      home: HomeScreen(mainStartTime: mainStartTime),
    );
  }
}

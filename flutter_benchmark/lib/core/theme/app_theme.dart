import 'package:flutter/material.dart';

/// App theme configuration
class AppTheme {
  AppTheme._();

  // Colors
  static const Color scaffoldBackground = Color(0xFF121212);
  static const Color cardBackground = Color(0xFF1E1E1E);
  static const Color cardBackgroundLight = Color(0xFF2A2A2A);

  // Feature colors
  static const Color primaryBlue = Colors.blue;
  static const Color cpuTestColor = Colors.orange;
  static const Color gpuTestColor = Colors.purple;
  static const Color successColor = Colors.greenAccent;
  static const Color errorColor = Colors.redAccent;
  static const Color warningColor = Colors.amber;

  /// Dark theme configuration
  static ThemeData get darkTheme => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: scaffoldBackground,
    cardColor: cardBackground,
    useMaterial3: true,
  );

  /// Light theme configuration
  static ThemeData get lightTheme => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
  );

  /// Get accent color for feature
  static Color getAccentColor(Color baseColor) {
    if (baseColor == Colors.green) return Colors.greenAccent;
    if (baseColor == Colors.blue) return Colors.lightBlueAccent;
    if (baseColor == Colors.orange) return Colors.orangeAccent;
    if (baseColor == Colors.purple) return Colors.purpleAccent;
    return baseColor;
  }
}

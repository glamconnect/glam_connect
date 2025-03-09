import 'package:flutter/material.dart';

/// AppColor provides a centralized place for all color definitions in the app.
/// Use these colors instead of hardcoded values to maintain consistency.
class AppColor {
  // Primary colors
  static const Color primary = Color(0xFF962B49);
  static const Color primaryLight = Color(0xFFCD3B64);
  static const Color primaryDark = Color(0xFF742138);

  // Accent colors
  static const Color accent = Color(0xFFFFC107); // Amber
  static const Color accentLight = Color(0xFFFFD54F); // Light Amber
  static const Color accentDark = Color(0xFFFF8F00); // Dark Amber

  // Text colors
  static const Color textPrimary = Color(0xFF212121); // Near Black
  static const Color textSecondary = Color(0xFF757575); // Dark Grey
  static const Color textLight = Color(0xFFFFFFFF); // White

  // Background colors
  static const Color background = Color(0xFFF5F5F5); // Light Grey
  static const Color card = Color(0xFFFFFFFF); // White
  static const Color divider = Color(0xFFBDBDBD); // Medium Grey

  // Status colors
  static const Color success = Color(0xFF4CAF50); // Green
  static const Color warning = Color(0xFFFFC107); // Amber
  static const Color error = Color(0xFFE53935); // Red
  static const Color info = Color(0xFF2196F3); // Blue

  // Social media colors
  static const Color facebook = Color(0xFF1877F2);
  static const Color google = Color(0xFFDB4437);
  static const Color twitter = Color(0xFF1DA1F2);

  // Transparent colors
  static Color primaryTransparent(double opacity) =>
      primary.withOpacity(opacity);
  static Color backgroundTransparent(double opacity) =>
      background.withOpacity(opacity);
}

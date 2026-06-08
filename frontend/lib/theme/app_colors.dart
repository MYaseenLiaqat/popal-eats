import 'package:flutter/material.dart';

/// FYP design tokens — dark theme with gold primary and green secondary.
abstract final class AppColors {
  static const background = Color(0xFF0E0E12);
  static const surface = Color(0xFF1A1A22);
  static const surfaceLight = Color(0xFF242430);
  static const gold = Color(0xFFF5C518);
  static const goldDark = Color(0xFFD4A017);
  static const green = Color(0xFF3DDC84);
  static const greenMuted = Color(0xFF2A9D5C);
  static const textPrimary = Color(0xFFF5F5F7);
  static const textSecondary = Color(0xFFB0B0BC);
  static const error = Color(0xFFE57373);

  static const cardRadius = 16.0;
  static const screenPadding = 16.0;

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5C518), Color(0xFFD4A017)],
  );

  static const surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF242430), Color(0xFF1A1A22)],
  );

  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A2418), Color(0xFF1A1A22)],
  );
}

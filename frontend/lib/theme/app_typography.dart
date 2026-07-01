import 'package:flutter/material.dart';

/// Unified typography scale for the Popal Eats design system.
///
/// This is the single source of truth for the app's text hierarchy. [AppTheme]
/// consumes [buildTextTheme] so every screen shares identical titles, section
/// headers, card titles, body copy, and captions.
abstract final class AppTypography {
  static const double pageTitle = 28; // Page / hero titles — Bold
  static const double sectionTitle = 20; // Section headers — SemiBold
  static const double cardTitle = 17; // Card titles — SemiBold
  static const double body = 15; // Body copy — Regular
  static const double caption = 13; // Captions / labels — Medium

  static TextTheme buildTextTheme({
    required Color primary,
    required Color secondary,
  }) {
    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: pageTitle,
        fontWeight: FontWeight.w800,
        color: primary,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.3,
        height: 1.2,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: primary,
        height: 1.25,
      ),
      titleLarge: TextStyle(
        fontSize: sectionTitle,
        fontWeight: FontWeight.w700,
        color: primary,
        height: 1.25,
      ),
      titleMedium: TextStyle(
        fontSize: cardTitle,
        fontWeight: FontWeight.w600,
        color: primary,
        height: 1.3,
      ),
      titleSmall: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: primary,
        height: 1.3,
      ),
      bodyLarge: TextStyle(fontSize: body, color: primary, height: 1.4),
      bodyMedium: TextStyle(fontSize: 14, color: secondary, height: 1.4),
      bodySmall: TextStyle(fontSize: caption, color: secondary, height: 1.35),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      labelMedium: TextStyle(
        fontSize: caption,
        fontWeight: FontWeight.w500,
        color: secondary,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondary,
      ),
    );
  }
}

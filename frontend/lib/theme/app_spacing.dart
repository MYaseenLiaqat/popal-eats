import 'package:flutter/widgets.dart';

/// Unified spacing scale (8pt grid) for the Popal Eats design system.
///
/// Use these tokens for padding, gaps, and section rhythm so every screen
/// breathes the same way.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Standard outer screen padding.
  static const EdgeInsets screen = EdgeInsets.all(lg);

  /// Standard inner card padding.
  static const EdgeInsets card = EdgeInsets.all(lg);

  /// Common vertical gaps as ready-to-use widgets.
  static const SizedBox gapXs = SizedBox(height: xs);
  static const SizedBox gapSm = SizedBox(height: sm);
  static const SizedBox gapMd = SizedBox(height: md);
  static const SizedBox gapLg = SizedBox(height: lg);
  static const SizedBox gapXl = SizedBox(height: xl);
}

import 'app_colors.dart';

/// Unified corner-radius scale for the Popal Eats design system.
///
/// Every surface should consume these values instead of hardcoding radii so
/// cards, buttons, inputs, and sheets stay visually consistent app-wide.
abstract final class AppRadius {
  static const double xs = 8;
  static const double sm = 10;
  static const double md = AppColors.buttonRadius; // 14 — buttons & inputs
  static const double lg = AppColors.cardRadius; // 18 — cards & sheets
  static const double xl = 24;
  static const double pill = 999;
}

import 'package:flutter/material.dart';

/// Popal Eats design tokens — premium dark emerald theme.
abstract final class AppColors {
  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const background = Color(0xFF0D1117);
  static const surface = Color(0xFF161B22);
  static const surfaceLight = Color(0xFF21262D);

  // ── Accent (emerald) ─────────────────────────────────────────────────────
  static const accent = Color(0xFF2ECC71);
  static const accentHover = Color(0xFF27AE60);
  static const accentPressed = Color(0xFF229954);
  static const accentSubtle = Color(0xFF0D2B1A);

  /// Text/icons on accent-colored surfaces (buttons, badges).
  static const onAccent = Color(0xFFFFFFFF);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFFF0F6FC);
  static const textSecondary = Color(0xFF7D8590);

  // ── Borders ──────────────────────────────────────────────────────────────
  static const border = Color(0xFF21262D);
  static const borderStrong = Color(0xFF30363D);

  // ── Navigation ───────────────────────────────────────────────────────────
  static const navBg = Color(0xFF0D1117);
  static const navActive = Color(0xFF2ECC71);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const error = Color(0xFFE57373);

  // ── Layout & motion ──────────────────────────────────────────────────────
  static const cardRadius = 18.0;
  static const buttonRadius = 16.0;
  static const inputRadius = 16.0;
  static const buttonHeight = 56.0;
  static const screenPadding = 16.0;
  static const animDuration = Duration(milliseconds: 220);
  static const animCurve = Curves.easeOutCubic;

  // ── Gradients ────────────────────────────────────────────────────────────
  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
  );

  static const surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF21262D), Color(0xFF161B22)],
  );

  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D2B1A), Color(0xFF161B22)],
  );

  // ── Shadows ──────────────────────────────────────────────────────────────
  static List<BoxShadow> cardShadow({bool elevated = false}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: elevated ? 0.35 : 0.22),
          blurRadius: elevated ? 16 : 10,
          offset: Offset(0, elevated ? 6 : 4),
        ),
      ];

  static List<BoxShadow> accentGlow({double alpha = 0.35}) => [
        BoxShadow(
          color: accent.withValues(alpha: alpha),
          blurRadius: 14,
          spreadRadius: 0,
        ),
      ];
}

import 'package:flutter/material.dart';

/// Popal Eats — warm cream, gold, and chocolate palette (light + dark).
abstract final class AppColors {
  // ── Brand anchors ─────────────────────────────────────────────────────────
  static const brandCream = Color(0xFFF8F4EC);
  static const brandGold = Color(0xFFE9C46A);
  static const brandGoldMid = Color(0xFFC9952F);
  static const brandGoldDark = Color(0xFF9A6B3A);
  static const brandChocolate = Color(0xFF3D2B1F);
  static const brandChocolateMuted = Color(0xFF7A6556);
  static const brandCard = brandGold;
  static const brandCardInner = Color(0xFFFFFFFF);
  static const brandButton = brandGoldMid;
  static const brandButtonHover = brandGoldDark;
  static const brandButtonPressed = Color(0xFF6B4423);

  // ── Light theme ───────────────────────────────────────────────────────────
  static const lightBackground = brandCream;
  static const lightSurface = brandGold;
  static const lightSurfaceLight = brandCardInner;
  static const lightAccent = brandButton;
  static const lightAccentHover = brandButtonHover;
  static const lightAccentPressed = brandButtonPressed;
  static const lightTextPrimary = brandChocolate;
  static const lightTextSecondary = brandChocolateMuted;
  static const lightTextOnCard = Color(0xFFFFFFFF);
  static const lightTextOnInner = brandChocolate;
  static const lightTextOnInnerMuted = brandChocolateMuted;
  static const lightBorder = Color(0xFFE0D4C4);
  static const lightBorderStrong = Color(0xFFC9B89E);

  // ── Dark theme ────────────────────────────────────────────────────────────
  static const darkBackground = Color(0xFF1A120E);
  static const darkSurface = Color(0xFF2C2018);
  static const darkSurfaceLight = Color(0xFF3D2E24);
  static const darkAccent = brandGold;
  static const darkAccentHover = Color(0xFFF0D080);
  static const darkAccentPressed = brandGoldDark;
  static const darkTextPrimary = brandCream;
  static const darkTextSecondary = Color(0xFFC4B5A8);
  static const darkBorder = Color(0xFF4A382E);
  static const darkBorderStrong = Color(0xFF5C4638);

  // ── Default tokens (dark — legacy AppColors.* references) ─────────────────
  static const background = darkBackground;
  static const surface = darkSurface;
  static const surfaceLight = darkSurfaceLight;
  static const accent = darkAccent;
  static const accentHover = darkAccentHover;
  static const accentPressed = darkAccentPressed;
  static const accentSubtle = Color(0xFF4A382E);
  static const onAccent = Color(0xFFFFFFFF);
  static const textPrimary = darkTextPrimary;
  static const textSecondary = darkTextSecondary;
  static const border = darkBorder;
  static const borderStrong = darkBorderStrong;
  static const navBg = darkBackground;
  static const navActive = brandGold;

  static const error = Color(0xFFD32F2F);
  static const chartProtein = Color(0xFFE9C46A);
  static const chartCarbs = Color(0xFFC9952F);
  static const chartWater = Color(0xFF8B7355);

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
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [brandGold, brandGoldDark],
  );

  static const lightAccentGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [brandGold, brandButtonPressed],
  );

  static const surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkSurfaceLight, darkSurface],
  );

  static const lightSurfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandGold, brandGoldDark],
  );

  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkSurface, darkBackground],
  );

  static const lightHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandGold, brandGoldDark],
  );

  /// Text color that contrasts with [background] (chocolate or white).
  static Color contrastOn(Color background) =>
      background.computeLuminance() > 0.45
          ? brandChocolate
          : Colors.white;

  // ── Shadows ──────────────────────────────────────────────────────────────
  static List<BoxShadow> cardShadow({bool elevated = false}) => [
        BoxShadow(
          color: brandChocolate.withValues(alpha: elevated ? 0.22 : 0.10),
          blurRadius: elevated ? 16 : 10,
          offset: Offset(0, elevated ? 6 : 4),
        ),
      ];

  static List<BoxShadow> accentGlow({double alpha = 0.35}) => [
        BoxShadow(
          color: brandGold.withValues(alpha: alpha),
          blurRadius: 14,
          spreadRadius: 0,
        ),
      ];
}

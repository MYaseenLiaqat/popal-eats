import 'package:flutter/material.dart';

/// Popal Eats — warm cream, gold, and chocolate palette (light + dark).
abstract final class AppColors {
  // ── Brand anchors ─────────────────────────────────────────────────────────
  static const brandCream = Color(0xFFF8F4EC);
  static const brandGold = Color(0xFFE6B84D);
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
  static const darkBackground = Color(0xFF15110F);
  static const darkSurface2 = Color(0xFF1D1714); // secondary surface
  static const darkSurface = Color(0xFF241B17); // cards
  static const darkSurfaceLight = Color(0xFF2B211C); // elevated cards
  static const darkAccent = brandGold;
  static const darkAccentHover = Color(0xFFF2C75B);
  static const darkAccentPressed = Color(0xFFD8A53D);
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFFD5D5D5);
  static const darkTextMuted = Color(0xFFAAAAAA);
  static const darkTextHint = Color(0xFF8C8C8C);
  static const darkBorder = Color(0xFF4A382D);
  static const darkBorderStrong = Color(0xFF63503F);
  static const darkCardBorder = Color(0x33E6B84D); // thin subtle gold

  // ── Default tokens (dark — legacy AppColors.* references) ─────────────────
  static const background = darkBackground;
  static const surface2 = darkSurface2;
  static const surface = darkSurface;
  static const surfaceLight = darkSurfaceLight;
  static const cardBorder = darkCardBorder;
  static const accent = darkAccent;
  static const accentHover = darkAccentHover;
  static const accentPressed = darkAccentPressed;
  static const accentSubtle = Color(0xFF4A382E);
  // Content that sits on top of the gold [accent] — near-black for legibility.
  static const onAccent = Color(0xFF15110F);
  static const textPrimary = darkTextPrimary;
  static const textSecondary = darkTextSecondary;
  static const textMuted = darkTextMuted;
  static const textHint = darkTextHint;
  static const border = darkBorder;
  static const borderStrong = darkBorderStrong;
  static const navBg = darkSurface2;
  static const navActive = brandGold;

  static const error = Color(0xFFE45A5A);
  static const success = Color(0xFF46C36F);
  static const onAccentDark = Color(0xFF15110F);
  static const chartProtein = brandGold;
  static const chartCarbs = Color(0xFFC9952F);
  static const chartWater = Color(0xFFB89A6E);

  // ── Layout & motion ──────────────────────────────────────────────────────
  static const cardRadius = 18.0;
  static const buttonRadius = 14.0;
  static const inputRadius = 14.0;
  static const buttonHeight = 52.0;
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

  /// Text color that contrasts with [background] (near-black or white).
  static Color contrastOn(Color background) =>
      background.computeLuminance() > 0.5
          ? const Color(0xFF17110E)
          : Colors.white;

  /// A single representative color for a gradient (mid-point blend), used to
  /// decide readable foreground colors on gradient surfaces.
  static Color representativeColor(Gradient gradient) {
    final colors = gradient.colors;
    if (colors.isEmpty) return surface;
    if (colors.length == 1) return colors.first;
    return Color.lerp(colors.first, colors.last, 0.5) ?? colors.first;
  }

  // ── Shadows ──────────────────────────────────────────────────────────────
  static List<BoxShadow> cardShadow({bool elevated = false}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: elevated ? 0.40 : 0.28),
          blurRadius: elevated ? 20 : 12,
          offset: Offset(0, elevated ? 8 : 4),
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

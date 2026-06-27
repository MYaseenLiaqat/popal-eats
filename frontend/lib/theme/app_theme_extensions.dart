import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Extended design tokens accessible via `Theme.of(context).extension<PopalThemeExtension>()`.
@immutable
class PopalThemeExtension extends ThemeExtension<PopalThemeExtension> {
  const PopalThemeExtension({
    required this.surface2,
    required this.accentSubtle,
    required this.border,
    required this.borderStrong,
    required this.navBg,
    required this.navActive,
    required this.cardRadius,
    required this.buttonRadius,
    required this.inputRadius,
    required this.buttonHeight,
    required this.cardHoverLift,
    required this.animDuration,
    required this.animCurve,
  });

  final Color surface2;
  final Color accentSubtle;
  final Color border;
  final Color borderStrong;
  final Color navBg;
  final Color navActive;
  final double cardRadius;
  final double buttonRadius;
  final double inputRadius;
  final double buttonHeight;
  final double cardHoverLift;
  final Duration animDuration;
  final Curve animCurve;

  static const defaults = PopalThemeExtension(
    surface2: AppColors.surfaceLight,
    accentSubtle: AppColors.accentSubtle,
    border: AppColors.border,
    borderStrong: AppColors.borderStrong,
    navBg: AppColors.navBg,
    navActive: AppColors.navActive,
    cardRadius: AppColors.cardRadius,
    buttonRadius: AppColors.buttonRadius,
    inputRadius: AppColors.inputRadius,
    buttonHeight: AppColors.buttonHeight,
    cardHoverLift: 5,
    animDuration: AppColors.animDuration,
    animCurve: AppColors.animCurve,
  );

  @override
  PopalThemeExtension copyWith({
    Color? surface2,
    Color? accentSubtle,
    Color? border,
    Color? borderStrong,
    Color? navBg,
    Color? navActive,
    double? cardRadius,
    double? buttonRadius,
    double? inputRadius,
    double? buttonHeight,
    double? cardHoverLift,
    Duration? animDuration,
    Curve? animCurve,
  }) {
    return PopalThemeExtension(
      surface2: surface2 ?? this.surface2,
      accentSubtle: accentSubtle ?? this.accentSubtle,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      navBg: navBg ?? this.navBg,
      navActive: navActive ?? this.navActive,
      cardRadius: cardRadius ?? this.cardRadius,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      inputRadius: inputRadius ?? this.inputRadius,
      buttonHeight: buttonHeight ?? this.buttonHeight,
      cardHoverLift: cardHoverLift ?? this.cardHoverLift,
      animDuration: animDuration ?? this.animDuration,
      animCurve: animCurve ?? this.animCurve,
    );
  }

  @override
  PopalThemeExtension lerp(ThemeExtension<PopalThemeExtension>? other, double t) {
    if (other is! PopalThemeExtension) return this;
    return PopalThemeExtension(
      surface2: Color.lerp(surface2, other.surface2, t)!,
      accentSubtle: Color.lerp(accentSubtle, other.accentSubtle, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      navBg: Color.lerp(navBg, other.navBg, t)!,
      navActive: Color.lerp(navActive, other.navActive, t)!,
      cardRadius: cardRadius + (other.cardRadius - cardRadius) * t,
      buttonRadius: buttonRadius + (other.buttonRadius - buttonRadius) * t,
      inputRadius: inputRadius + (other.inputRadius - inputRadius) * t,
      buttonHeight: buttonHeight + (other.buttonHeight - buttonHeight) * t,
      cardHoverLift: cardHoverLift + (other.cardHoverLift - cardHoverLift) * t,
      animDuration: animDuration,
      animCurve: animCurve,
    );
  }
}

extension PopalThemeContext on BuildContext {
  PopalThemeExtension get popalTheme =>
      Theme.of(this).extension<PopalThemeExtension>() ?? PopalThemeExtension.defaults;
}

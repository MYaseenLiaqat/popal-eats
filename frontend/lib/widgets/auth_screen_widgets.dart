import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_logo.dart';
import 'ui/app_ui_widgets.dart';

class AuthBrandedHeader extends StatelessWidget {
  const AuthBrandedHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final headerGradient =
        isLight ? AppColors.lightHeaderGradient : AppColors.headerGradient;
    final onCard = isLight ? AppColors.lightTextOnCard : AppColors.textPrimary;

    return ModernCard(
      gradient: headerGradient,
      borderColor: AppColors.brandGoldDark.withValues(alpha: 0.35),
      child: Column(
        children: [
          const AppLogo(size: 88),
          const SizedBox(height: 16),
          Text(
            'Popal Eats',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: onCard,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: onCard,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: onCard.withValues(alpha: 0.88),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class AuthFormCard extends StatelessWidget {
  const AuthFormCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    if (isLight) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.brandCardInner,
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
          border: Border.all(color: AppColors.lightBorder),
          boxShadow: AppColors.cardShadow(),
        ),
        padding: const EdgeInsets.all(16),
        child: child,
      );
    }
    return ModernCard(
      borderColor: AppColors.surfaceLight.withValues(alpha: 0.8),
      child: child,
    );
  }
}

/// Gold inner panel for content nested inside green [ModernCard]s.
class CardInnerSurface extends StatelessWidget {
  const CardInnerSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bg = isLight ? AppColors.brandCardInner : AppColors.surfaceLight;
    final onBg = AppColors.contrastOn(bg);
    final theme = Theme.of(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLight
              ? AppColors.lightTextOnInnerMuted.withValues(alpha: 0.25)
              : AppColors.border,
        ),
      ),
      child: Theme(
        data: theme.copyWith(
          textTheme: theme.textTheme.apply(
            bodyColor: onBg,
            displayColor: onBg,
          ),
          iconTheme: IconThemeData(color: onBg.withValues(alpha: 0.85)),
          inputDecorationTheme: theme.inputDecorationTheme.copyWith(
            fillColor: isLight ? AppColors.brandCream : theme.inputDecorationTheme.fillColor,
            hintStyle: TextStyle(color: onBg.withValues(alpha: 0.6)),
            labelStyle: TextStyle(color: onBg.withValues(alpha: 0.8)),
          ),
        ),
        child: child,
      ),
    );
  }
}

InputDecoration authInputDecoration(
  BuildContext context, {
  required String label,
  IconData? icon,
  String? hint,
}) {
  final isLight = Theme.of(context).brightness == Brightness.light;
  final fill = isLight ? AppColors.brandCream : AppColors.surface;
  final onFill = AppColors.contrastOn(fill);
  final border = isLight ? AppColors.lightBorder : AppColors.borderStrong;

  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: TextStyle(color: onFill.withValues(alpha: 0.85)),
    hintStyle: TextStyle(color: onFill.withValues(alpha: 0.55)),
    prefixIcon: icon != null ? Icon(icon, color: onFill.withValues(alpha: 0.75)) : null,
    filled: true,
    fillColor: fill,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppColors.inputRadius),
      borderSide: BorderSide(color: border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppColors.inputRadius),
      borderSide: BorderSide(color: border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppColors.inputRadius),
      borderSide: BorderSide(color: AppColors.brandGoldDark, width: 1.5),
    ),
  );
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.surfaceLight.withValues(alpha: 0.8))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(child: Divider(color: AppColors.surfaceLight.withValues(alpha: 0.8))),
      ],
    );
  }
}

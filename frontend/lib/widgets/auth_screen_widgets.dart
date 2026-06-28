import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
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
    return ModernCard(
      gradient: AppColors.headerGradient,
      borderColor: AppColors.accent.withValues(alpha: 0.4),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.restaurant,
              size: 40,
              color: AppColors.onAccent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Popal Eats',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
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
    return ModernCard(
      borderColor: AppColors.surfaceLight.withValues(alpha: 0.8),
      child: child,
    );
  }
}

InputDecoration authInputDecoration({
  required String label,
  IconData? icon,
  String? hint,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon != null ? Icon(icon, color: AppColors.accent) : null,
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppColors.inputRadius),
      borderSide: const BorderSide(color: AppColors.borderStrong),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppColors.inputRadius),
      borderSide: const BorderSide(color: AppColors.borderStrong),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppColors.inputRadius),
      borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
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

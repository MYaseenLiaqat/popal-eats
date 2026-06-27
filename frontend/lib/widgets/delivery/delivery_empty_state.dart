import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Premium empty state when no active delivery exists.
class DeliveryEmptyState extends StatelessWidget {
  const DeliveryEmptyState({super.key, this.onBrowseRestaurants});

  final VoidCallback? onBrowseRestaurants;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Illustration(),
            const SizedBox(height: 28),
            Text(
              'No active deliveries',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Place an order from the Order tab and track it live — from kitchen to your door.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
              textAlign: TextAlign.center,
            ),
            if (onBrowseRestaurants != null) ...[
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: onBrowseRestaurants,
                icon: const Icon(Icons.restaurant_menu_rounded),
                label: const Text('Browse Restaurants'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.onAccent,
                  minimumSize: const Size(double.infinity, AppColors.buttonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.buttonRadius),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.18),
            AppColors.accentSubtle,
          ],
        ),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
        boxShadow: AppColors.accentGlow(alpha: 0.12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.two_wheeler_rounded,
            size: 72,
            color: AppColors.accent.withValues(alpha: 0.35),
          ),
          Positioned(
            bottom: 28,
            right: 32,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
              ),
              child: const Icon(Icons.delivery_dining, color: AppColors.accent, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

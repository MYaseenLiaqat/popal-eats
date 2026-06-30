import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'delivery_constants.dart';

/// Order status card — shows backend-driven status only (no fake ETA).
class DeliveryEtaCard extends StatelessWidget {
  const DeliveryEtaCard({super.key, required this.snapshot});

  final DeliveryTrackingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accent.withValues(alpha: 0.12),
              AppColors.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentSubtle,
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
              ),
              child: Icon(
                snapshot.isDelivered ? Icons.check_circle_outline : Icons.local_shipping_outlined,
                color: AppColors.accent,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order status',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    snapshot.statusLabel,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

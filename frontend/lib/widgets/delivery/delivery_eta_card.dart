import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'delivery_constants.dart';

/// ETA card with pulse animation and animated delivery bike.
class DeliveryEtaCard extends StatefulWidget {
  const DeliveryEtaCard({super.key, required this.snapshot});

  final DeliveryTrackingSnapshot snapshot;

  @override
  State<DeliveryEtaCard> createState() => _DeliveryEtaCardState();
}

class _DeliveryEtaCardState extends State<DeliveryEtaCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snap = widget.snapshot;
    final etaLabel = snap.isDelivered
        ? 'Arrived'
        : '${snap.remainingMinutes} min${snap.remainingMinutes == 1 ? '' : 's'} remaining';

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accent.withValues(alpha: 0.12 + _pulse.value * 0.06),
                  AppColors.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.35 + _pulse.value * 0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.08 + _pulse.value * 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _AnimatedBike(pulse: _pulse.value),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated arrival',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        etaLabel,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _MetricChip(
                            icon: Icons.straighten_rounded,
                            label: '${snap.distanceKm.toStringAsFixed(1)} km left',
                          ),
                          const SizedBox(width: 8),
                          _MetricChip(
                            icon: Icons.speed_rounded,
                            label: '${snap.avgSpeedKmh.toStringAsFixed(0)} km/h avg',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedBike extends StatelessWidget {
  const _AnimatedBike({required this.pulse});

  final double pulse;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(pulse * 4, 0),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accentSubtle,
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
          boxShadow: AppColors.accentGlow(alpha: 0.15 + pulse * 0.1),
        ),
        child: const Icon(Icons.two_wheeler_rounded, color: AppColors.accent, size: 28),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

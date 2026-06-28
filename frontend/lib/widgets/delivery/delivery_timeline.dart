import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'delivery_constants.dart';

/// Seven-step animated delivery timeline.
class DeliveryTimeline extends StatelessWidget {
  const DeliveryTimeline({super.key, required this.current});

  final DeliveryTimelineStage current;

  static const _stages = [
    (DeliveryTimelineStage.orderPlaced, 'Order Placed', Icons.receipt_long_outlined),
    (DeliveryTimelineStage.restaurantAccepted, 'Restaurant Accepted', Icons.thumb_up_alt_outlined),
    (DeliveryTimelineStage.preparing, 'Preparing', Icons.restaurant_outlined),
    (DeliveryTimelineStage.riderAssigned, 'Rider Assigned', Icons.person_pin_circle_outlined),
    (DeliveryTimelineStage.pickedUp, 'Picked Up', Icons.shopping_bag_outlined),
    (DeliveryTimelineStage.nearYou, 'Near You', Icons.near_me_outlined),
    (DeliveryTimelineStage.delivered, 'Delivered', Icons.check_circle_outline),
  ];

  int get _currentIndex {
    for (var i = 0; i < _stages.length; i++) {
      if (_stages[i].$1 == current) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final active = _currentIndex;

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderStrong.withValues(alpha: 0.55)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery progress',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            ...List.generate(_stages.length, (index) {
              final stage = _stages[index];
              final done = index <= active;
              final isCurrent = index == active;
              final isLast = index == _stages.length - 1;

              return _TimelineStep(
                label: stage.$2,
                icon: stage.$3,
                done: done,
                isCurrent: isCurrent,
                showConnector: !isLast,
                connectorDone: index < active,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep extends StatefulWidget {
  const _TimelineStep({
    required this.label,
    required this.icon,
    required this.done,
    required this.isCurrent,
    required this.showConnector,
    required this.connectorDone,
  });

  final String label;
  final IconData icon;
  final bool done;
  final bool isCurrent;
  final bool showConnector;
  final bool connectorDone;

  @override
  State<_TimelineStep> createState() => _TimelineStepState();
}

class _TimelineStepState extends State<_TimelineStep> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    if (widget.isCurrent && !widget.done) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _TimelineStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent && !widget.done) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                final scale = widget.isCurrent && !widget.done ? 1.0 + _pulse.value * 0.08 : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.done ? AppColors.accent : AppColors.surfaceLight,
                      border: Border.all(
                        color: widget.isCurrent
                            ? AppColors.accent
                            : widget.done
                                ? AppColors.accent
                                : AppColors.borderStrong.withValues(alpha: 0.5),
                        width: widget.isCurrent ? 2 : 1,
                      ),
                      boxShadow: widget.isCurrent ? AppColors.accentGlow(alpha: 0.2) : null,
                    ),
                    child: Icon(
                      widget.done ? Icons.check_rounded : widget.icon,
                      size: 16,
                      color: widget.done ? AppColors.onAccent : AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
            if (widget.showConnector)
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 2,
                height: 24,
                color: widget.connectorDone ? AppColors.accent : AppColors.surfaceLight,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 7, bottom: widget.showConnector ? 10 : 0),
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: widget.done || widget.isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: widget.done || widget.isCurrent ? null : AppColors.textSecondary,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../theme/app_colors.dart';
import 'delivery_constants.dart';

/// Animated live status chips (Preparing, On the way, etc.).
class DeliveryLiveStatusChips extends StatelessWidget {
  const DeliveryLiveStatusChips({super.key, required this.active});

  final DeliveryLiveStatus active;

  static const _items = [
    (DeliveryLiveStatus.preparing, 'Preparing', Icons.restaurant, Color(0xFF3498DB)),
    (DeliveryLiveStatus.cooking, 'Cooking', Icons.local_fire_department_outlined, Color(0xFFE67E22)),
    (DeliveryLiveStatus.pickedUp, 'Picked Up', Icons.shopping_bag_outlined, Color(0xFF9B59B6)),
    (DeliveryLiveStatus.onTheWay, 'On the way', Icons.delivery_dining_outlined, Color(0xFF2ECC71)),
    (DeliveryLiveStatus.nearYou, 'Near you', Icons.near_me_outlined, Color(0xFF1ABC9C)),
    (DeliveryLiveStatus.delivered, 'Delivered', Icons.check_circle_outline, AppColors.accent),
  ];

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final item = _items[index];
            final isActive = item.$1 == active;
            return _StatusChip(
              label: item.$2,
              icon: item.$3,
              color: item.$4,
              isActive: isActive,
            );
          },
        ),
      ),
    );
  }
}

class _StatusChip extends StatefulWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isActive,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isActive;

  @override
  State<_StatusChip> createState() => _StatusChipState();
}

class _StatusChipState extends State<_StatusChip> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isActive) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _StatusChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.isActive && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = widget.isActive ? 0.12 + _pulse.value * 0.18 : 0.0;
        return AnimatedContainer(
          duration: AppColors.animDuration,
          curve: AppColors.animCurve,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isActive
                ? widget.color.withValues(alpha: 0.18)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isActive
                  ? widget.color.withValues(alpha: 0.55 + glow)
                  : AppColors.borderStrong.withValues(alpha: 0.4),
            ),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: glow),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.isActive ? widget.color : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isActive ? widget.color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Large status card with restaurant info and countdown.
class DeliveryStatusCard extends StatelessWidget {
  const DeliveryStatusCard({
    super.key,
    required this.order,
    required this.restaurantName,
    this.restaurantImageUrl,
    required this.snapshot,
    required this.countdownLabel,
  });

  final Order order;
  final String restaurantName;
  final String? restaurantImageUrl;
  final DeliveryTrackingSnapshot snapshot;
  final String countdownLabel;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Hero(
        tag: 'delivery-status-${order.id}',
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
              boxShadow: AppColors.cardShadow(elevated: true),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _RestaurantLogo(imageUrl: restaurantImageUrl, name: restaurantName),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurantName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Order #${order.id}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    _CountdownBadge(label: countdownLabel),
                  ],
                ),
                const SizedBox(height: 16),
                DeliveryLiveStatusChips(active: snapshot.liveStatus),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RestaurantLogo extends StatelessWidget {
  const _RestaurantLogo({this.imageUrl, required this.name});

  final String? imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.surfaceLight,
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        image: imageUrl != null && imageUrl!.isNotEmpty
            ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: imageUrl == null || imageUrl!.isEmpty
          ? Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'R',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            )
          : null,
    );
  }
}

class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accentSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          const Icon(Icons.schedule_rounded, color: AppColors.accent, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

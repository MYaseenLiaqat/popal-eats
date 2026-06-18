import 'package:flutter/material.dart';

import '../../models/food_feed_item.dart';
import '../../theme/app_colors.dart';
import '../../utils/price_formatter.dart';
import '../ui/app_ui_widgets.dart';

/// Large visual card for the home food feed.
class FoodFeedCard extends StatelessWidget {
  const FoodFeedCard({
    super.key,
    required this.item,
    this.onTap,
    this.imageHeight = 260,
  });

  final FoodFeedItem item;
  final VoidCallback? onTap;
  final double imageHeight;

  Color _chipColor(FoodFeedKind kind) {
    switch (kind) {
      case FoodFeedKind.recommended:
        return AppColors.green;
      case FoodFeedKind.trending:
        return AppColors.gold;
      case FoodFeedKind.groupDecision:
        return AppColors.green;
      case FoodFeedKind.friendPlaceholder:
        return AppColors.textSecondary;
      case FoodFeedKind.discover:
        return AppColors.gold;
    }
  }

  IconData _placeholderIcon(FoodFeedKind kind) {
    switch (kind) {
      case FoodFeedKind.groupDecision:
        return Icons.groups_outlined;
      case FoodFeedKind.friendPlaceholder:
        return Icons.favorite_border;
      case FoodFeedKind.discover:
        return Icons.explore_outlined;
      default:
        return Icons.restaurant_menu;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = item.kind == FoodFeedKind.friendPlaceholder;
    final isDiscover = item.kind == FoodFeedKind.discover;
    final showImage = !isPlaceholder && !isDiscover;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ModernCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        borderColor: _chipColor(item.kind).withValues(alpha: 0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showImage)
              Stack(
                children: [
                  DishImageBanner(
                    imageUrl: item.imageUrl,
                    height: imageHeight,
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _KindChip(
                      label: item.kindLabel,
                      color: _chipColor(item.kind),
                    ),
                  ),
                ],
              )
            else
              Container(
                height: isPlaceholder ? 140 : 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.surfaceLight.withValues(alpha: 0.5),
                      AppColors.surface.withValues(alpha: 0.9),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppColors.cardRadius),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        _placeholderIcon(item.kind),
                        size: 48,
                        color: _chipColor(item.kind).withValues(alpha: 0.7),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _KindChip(
                        label: item.kindLabel,
                        color: _chipColor(item.kind),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (item.restaurantName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.storefront_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.restaurantName!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.subtitle!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                    ),
                  ],
                  if (item.price != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      PriceFormatter.format(item.price!),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                  if (onTap != null && !isPlaceholder) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          isDiscover ? 'Browse' : 'View',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: AppColors.gold,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

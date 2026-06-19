import 'package:flutter/material.dart';

import '../../models/food_feed_item.dart';
import '../../theme/app_colors.dart';
import '../../utils/price_formatter.dart';
import '../ui/app_ui_widgets.dart';

/// Instagram-style food feed card — image-first, minimal copy.
class FoodFeedCard extends StatelessWidget {
  const FoodFeedCard({
    super.key,
    required this.item,
    this.onTap,
    this.imageHeight = 340,
  });

  final FoodFeedItem item;
  final VoidCallback? onTap;
  final double imageHeight;

  Color _accent(FoodFeedKind kind) {
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

  @override
  Widget build(BuildContext context) {
    if (item.kind == FoodFeedKind.friendPlaceholder) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: ModernCard(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          child: EmptyState(
            icon: Icons.favorite_border,
            title: item.title,
            subtitle: item.subtitle,
          ),
        ),
      );
    }

    if (item.kind == FoodFeedKind.discover) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: ModernCard(
          onTap: onTap,
          padding: const EdgeInsets.all(20),
          borderColor: AppColors.gold.withValues(alpha: 0.35),
          child: Row(
            children: [
              const Icon(Icons.explore_outlined, color: AppColors.gold, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                    if (item.subtitle != null)
                      Text(item.subtitle!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppColors.cardRadius),
              border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppColors.cardRadius),
                  ),
                  child: Stack(
                    children: [
                      DishImageBanner(
                        imageUrl: item.imageUrl,
                        height: imageHeight,
                      ),
                      Positioned(
                        top: 14,
                        left: 14,
                        child: _KindChip(label: item.kindLabel, color: _accent(item.kind)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if (item.restaurantName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.restaurantName!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                      if (item.subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          item.subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                      if (item.price != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          PriceFormatter.format(item.price!),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
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
        border: Border.all(color: color.withValues(alpha: 0.65)),
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

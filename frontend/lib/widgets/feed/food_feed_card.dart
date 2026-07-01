import 'package:flutter/material.dart';

import '../../models/food_feed_item.dart';
import '../../theme/app_colors.dart';
import '../../utils/price_formatter.dart';
import '../ui/app_ui_widgets.dart';
import 'feed_constants.dart';
import 'feed_shimmer.dart';

/// Instagram-style food feed card — uniform media, minimal copy.
class FoodFeedCard extends StatelessWidget {
  const FoodFeedCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final FoodFeedItem item;
  final VoidCallback? onTap;

  Color _accent(FoodFeedKind kind) {
    switch (kind) {
      case FoodFeedKind.recommended:
      case FoodFeedKind.trending:
      case FoodFeedKind.groupDecision:
      case FoodFeedKind.discover:
        return AppColors.accent;
      case FoodFeedKind.friendPlaceholder:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (item.kind == FoodFeedKind.friendPlaceholder) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ModernCard(
          onTap: onTap,
          padding: const EdgeInsets.all(20),
          borderColor: AppColors.accent.withValues(alpha: 0.35),
          child: Row(
            children: [
              const Icon(Icons.explore_outlined, color: AppColors.accent, size: 32),
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

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: FeedConstants.mediaAspectRatio,
                    child: item.imageUrl != null
                        ? Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            gaplessPlayback: true,
                            filterQuality: FilterQuality.medium,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const FeedShimmer(child: SizedBox.expand());
                            },
                            errorBuilder: (_, __, ___) => _imageFallback(),
                          )
                        : _imageFallback(),
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: _KindChip(label: item.kindLabel, color: _accent(item.kind)),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    if (item.price != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        PriceFormatter.format(item.price!),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.border.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return ColoredBox(
      color: AppColors.surfaceLight,
      child: Icon(
        Icons.restaurant_outlined,
        size: 48,
        color: AppColors.accent.withValues(alpha: 0.7),
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

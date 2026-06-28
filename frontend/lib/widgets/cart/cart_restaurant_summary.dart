import 'package:flutter/material.dart';

import '../../models/restaurant.dart';
import '../../theme/app_colors.dart';
import '../../utils/profile_image_url.dart';
import '../feed/feed_shimmer.dart';
import '../ui/app_ui_widgets.dart';
import 'cart_constants.dart';

class CartRestaurantSummary extends StatelessWidget {
  const CartRestaurantSummary({
    super.key,
    this.restaurant,
    this.loading = false,
  });

  final Restaurant? restaurant;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: FeedShimmer(
          borderRadius: CartConstants.cardRadius,
          child: const SizedBox(height: 88, width: double.infinity),
        ),
      );
    }

    if (restaurant == null) return const SizedBox.shrink();

    final imageUrl = resolveProfileImageUrl(restaurant!.image);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppColors.headerGradient,
          borderRadius: BorderRadius.circular(CartConstants.cardRadius),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
          boxShadow: AppColors.cardShadow(),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : ColoredBox(
                      color: AppColors.accentSubtle,
                      child: Icon(Icons.storefront, color: AppColors.accent.withValues(alpha: 0.7)),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant!.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (restaurant!.averageRating > 0)
                        RatingBadge(
                          rating: restaurant!.averageRating,
                          reviews: restaurant!.totalReviews,
                        ),
                      _Chip(label: 'Delivery', icon: Icons.delivery_dining_outlined),
                      _Chip(
                        label: restaurant!.isOpen ? 'Open' : 'Closed',
                        icon: Icons.circle,
                        color: restaurant!.isOpen ? AppColors.accent : AppColors.error,
                      ),
                    ],
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

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    this.color = AppColors.textPrimary,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

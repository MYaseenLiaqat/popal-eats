import 'package:flutter/material.dart';

import '../../models/restaurant.dart';
import '../../theme/app_colors.dart';
import '../../utils/restaurant_display.dart';
import '../../utils/preference_display.dart';
import '../../utils/profile_image_url.dart';
import '../feed/feed_shimmer.dart';
import 'restaurant_constants.dart';

class RestaurantHeroHeader extends StatelessWidget {
  const RestaurantHeroHeader({
    super.key,
    required this.restaurant,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  final Restaurant restaurant;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  String? get _imageUrl => resolveProfileImageUrl(restaurant.image);

  String? get _cuisine =>
      restaurant.tags.isNotEmpty ? PreferenceDisplay.cuisineLabel(restaurant.tags.first) : null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: RestaurantConstants.heroHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: RestaurantConstants.coverHeroTag(restaurant.id),
            child: Material(
              type: MaterialType.transparency,
              child: _imageUrl != null
                  ? Image.network(
                      _imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const FeedShimmer(child: SizedBox.expand());
                      },
                      errorBuilder: (_, __, ___) => _fallbackCover(),
                    )
                  : _fallbackCover(),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.35),
                  AppColors.background.withValues(alpha: 0.95),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 12,
            child: _CircleIconButton(
              icon: isFavorite ? Icons.favorite : Icons.favorite_border,
              iconColor: isFavorite ? Colors.redAccent : Colors.white,
              onTap: onFavoriteToggle,
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 3),
                    boxShadow: AppColors.cardShadow(elevated: true),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imageUrl != null
                      ? Image.network(_imageUrl!, fit: BoxFit.cover)
                      : _logoFallback(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        restaurant.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (_cuisine != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _cuisine!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (restaurant.averageRating > 0)
                            _MetaChip(
                              icon: Icons.star_rounded,
                              label: restaurant.averageRating.toStringAsFixed(1),
                              color: AppColors.accent,
                            ),
                          if (restaurant.totalReviews > 0)
                            _MetaChip(
                              icon: Icons.rate_review_outlined,
                              label: '${restaurant.totalReviews} reviews',
                            ),
                          _MetaChip(
                            icon: Icons.circle,
                            iconSize: 8,
                            label: restaurant.isOpen ? 'Open now' : 'Closed',
                            color: restaurant.isOpen ? AppColors.accent : AppColors.error,
                          ),
                          _MetaChip(
                            icon: Icons.schedule_outlined,
                            label: RestaurantDisplay.deliveryEta(restaurant) ?? '25–35 min',
                          ),
                          _MetaChip(
                            icon: Icons.near_me_outlined,
                            label: RestaurantDisplay.distanceLabel(restaurant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackCover() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accentSubtle, AppColors.surface],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.storefront_outlined,
        size: 80,
        color: AppColors.accent.withValues(alpha: 0.45),
      ),
    );
  }

  Widget _logoFallback() {
    return Container(
      color: AppColors.accentSubtle,
      alignment: Alignment.center,
      child: const Icon(Icons.restaurant, color: AppColors.accent, size: 32),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.color = AppColors.textPrimary,
    this.iconSize = 14,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: iconColor, size: 22),
        ),
      ),
    );
  }
}

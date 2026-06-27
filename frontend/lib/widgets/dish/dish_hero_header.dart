import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../utils/profile_image_url.dart';
import '../feed/feed_shimmer.dart';
import 'dish_constants.dart';

class DishHeroHeader extends StatelessWidget {
  const DishHeroHeader({
    super.key,
    required this.imageUrl,
    required this.dishId,
    required this.restaurantName,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.onRestaurantTap,
    this.onShare,
  });

  final String? imageUrl;
  final int dishId;
  final String? restaurantName;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onRestaurantTap;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveProfileImageUrl(imageUrl);
    final topPad = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: DishConstants.heroHeight + topPad,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(DishConstants.cardRadius),
            ),
            child: Hero(
              tag: DishConstants.dishHeroTag(dishId),
              child: Material(
                type: MaterialType.transparency,
                child: resolved != null
                    ? Image.network(
                        resolved,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const FeedShimmer(child: SizedBox.expand());
                        },
                        errorBuilder: (_, __, ___) => _fallback(),
                      )
                    : _fallback(),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(DishConstants.cardRadius),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.35),
                  AppColors.background.withValues(alpha: 0.92),
                ],
                stops: const [0.35, 0.7, 1.0],
              ),
            ),
          ),
          Positioned(
            top: topPad + 8,
            left: 8,
            child: _CircleBtn(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: topPad + 8,
            right: 8,
            child: Row(
              children: [
                _CircleBtn(icon: Icons.ios_share_outlined, onTap: onShare),
                const SizedBox(width: 8),
                _CircleBtn(
                  icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                  iconColor: isFavorite ? Colors.redAccent : Colors.white,
                  onTap: onFavoriteToggle,
                ),
              ],
            ),
          ),
          if (restaurantName != null)
            Positioned(
              left: 16,
              bottom: 18,
              child: GestureDetector(
                onTap: onRestaurantTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.storefront_outlined, size: 16, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Text(
                        restaurantName!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 16, color: Colors.white.withValues(alpha: 0.8)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: AppColors.accentSubtle,
      alignment: Alignment.center,
      child: Icon(
        Icons.restaurant_menu,
        size: 72,
        color: AppColors.accent.withValues(alpha: 0.45),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({
    required this.icon,
    this.iconColor = Colors.white,
    this.onTap,
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

void shareDishLink(int dishId) {
  Clipboard.setData(ClipboardData(text: 'dish:$dishId'));
}

import 'package:flutter/material.dart';

import '../../models/restaurant.dart';
import '../../theme/app_colors.dart';
import '../../utils/profile_image_url.dart';
import 'home_constants.dart';
import 'home_network_image.dart';

class HomeFeaturedRestaurantCard extends StatefulWidget {
  const HomeFeaturedRestaurantCard({
    super.key,
    required this.restaurant,
    required this.width,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteToggle,
    this.heroTag,
  });

  final Restaurant restaurant;
  final double width;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final Object? heroTag;

  @override
  State<HomeFeaturedRestaurantCard> createState() => _HomeFeaturedRestaurantCardState();
}

class _HomeFeaturedRestaurantCardState extends State<HomeFeaturedRestaurantCard> {
  bool _hovered = false;

  String? get _imageUrl => resolveProfileImageUrl(widget.restaurant.image);

  String? get _cuisine =>
      widget.restaurant.tags.isNotEmpty ? widget.restaurant.tags.first : null;

  bool get _hasOffer =>
      widget.restaurant.tags.any((t) => t.toLowerCase().contains('off'));

  @override
  Widget build(BuildContext context) {
    final lift = _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Transform.translate(
          offset: Offset(0, lift ? -4 : 0),
          child: Transform.scale(
            scale: lift ? 1.02 : 1.0,
            child: AnimatedContainer(
              duration: HomeConstants.animDuration,
              curve: HomeConstants.animCurve,
              width: widget.width,
              decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(HomeConstants.cardRadius),
            border: Border.all(
              color: lift
                  ? AppColors.accent.withValues(alpha: 0.45)
                  : AppColors.borderStrong.withValues(alpha: 0.55),
            ),
            boxShadow: lift
                ? [...AppColors.cardShadow(elevated: true), ...AppColors.accentGlow(alpha: 0.12)]
                : AppColors.cardShadow(),
          ),
          clipBehavior: Clip.antiAlias,
          child: RepaintBoundary(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    HomeNetworkImage(
                      url: _imageUrl,
                      height: 160,
                      width: widget.width,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(HomeConstants.cardRadius),
                      ),
                      heroTag: widget.heroTag ??
                          HomeConstants.restaurantHeroTag(widget.restaurant.id),
                      fallbackIcon: Icons.storefront_outlined,
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _StatusBadge(
                        label: widget.restaurant.isOpen ? 'Open' : 'Closed',
                        color: widget.restaurant.isOpen ? AppColors.accent : AppColors.error,
                      ),
                    ),
                    if (_hasOffer)
                      const Positioned(
                        top: 12,
                        right: 52,
                        child: _StatusBadge(
                          label: 'Offer',
                          color: AppColors.accent,
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _FavoriteButton(
                        active: widget.isFavorite,
                        onTap: widget.onFavoriteToggle,
                      ),
                    ),
                    Positioned(
                      left: 14,
                      bottom: -22,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface, width: 3),
                          boxShadow: AppColors.cardShadow(),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: HomeNetworkImage(
                          url: _imageUrl,
                          width: 52,
                          height: 52,
                          borderRadius: BorderRadius.circular(26),
                          fallbackIcon: Icons.restaurant,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 30, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.restaurant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (widget.restaurant.averageRating > 0) ...[
                            const Icon(Icons.star_rounded, size: 16, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(
                              widget.restaurant.averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                              ),
                            ),
                            if (widget.restaurant.totalReviews > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${widget.restaurant.totalReviews})',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            const SizedBox(width: 10),
                          ],
                          if (_cuisine != null)
                            Expanded(
                              child: Text(
                                _cuisine!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ),
                      if (widget.restaurant.city != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.textSecondary.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.restaurant.city!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
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
        ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.65)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.active, this.onTap});

  final bool active;
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
          padding: const EdgeInsets.all(8),
          child: AnimatedSwitcher(
            duration: HomeConstants.animDuration,
            child: Icon(
              active ? Icons.favorite : Icons.favorite_border,
              key: ValueKey(active),
              color: active ? Colors.redAccent : Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

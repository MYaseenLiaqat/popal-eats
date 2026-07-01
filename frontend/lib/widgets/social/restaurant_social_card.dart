import 'package:flutter/material.dart';

import '../../models/restaurant.dart';
import '../../theme/app_colors.dart';
import '../../utils/profile_image_url.dart';
import '../community_avatar.dart';
import '../ui/app_ui_widgets.dart';

/// Compact restaurant row for discover / suggested lists (Instagram-style).
class RestaurantSocialCard extends StatelessWidget {
  const RestaurantSocialCard({
    super.key,
    required this.restaurant,
    required this.isFollowing,
    required this.onFollowToggle,
    this.onTap,
    this.compact = false,
    this.useCard = true,
  });

  final Restaurant restaurant;
  final bool isFollowing;
  final VoidCallback onFollowToggle;
  final VoidCallback? onTap;
  final bool compact;
  final bool useCard;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveProfileImageUrl(restaurant.image);
    final subtitle = [
      if (restaurant.city != null && restaurant.city!.isNotEmpty) restaurant.city,
      if (restaurant.tags.isNotEmpty) restaurant.tags.first,
    ].whereType<String>().join(' · ');

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CommunityAvatar(
          name: restaurant.name,
          imageUrl: imageUrl,
          size: compact ? 44 : 52,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                restaurant.name,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (!compact && restaurant.averageRating > 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      restaurant.averageRating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    if (restaurant.totalReviews > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(${restaurant.totalReviews})',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        _FollowChip(
          isFollowing: isFollowing,
          onPressed: onFollowToggle,
        ),
      ],
    );

    if (!useCard) return InkWell(onTap: onTap, child: content);
    return ModernCard(onTap: onTap, child: content);
  }
}

class _FollowChip extends StatelessWidget {
  const _FollowChip({required this.isFollowing, required this.onPressed});

  final bool isFollowing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (isFollowing) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: BorderSide(color: AppColors.borderStrong.withValues(alpha: 0.7)),
        ),
        child: Text(
          'Following',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      );
    }

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text('Follow'),
    );
  }
}

/// Circular avatar tile for horizontal suggested strip (Instagram-style).
class SuggestedAccountTile extends StatelessWidget {
  const SuggestedAccountTile({
    super.key,
    required this.name,
    this.imageUrl,
    required this.isFollowing,
    required this.onFollowToggle,
    this.onTap,
    this.subtitle,
  });

  final String name;
  final String? imageUrl;
  final bool isFollowing;
  final VoidCallback onFollowToggle;
  final VoidCallback? onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: CommunityAvatar(name: name, imageUrl: imageUrl, size: 64),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 28,
            child: isFollowing
                ? OutlinedButton(
                    onPressed: onFollowToggle,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide(
                        color: AppColors.borderStrong.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Text(
                      'Following',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                    ),
                  )
                : FilledButton(
                    onPressed: onFollowToggle,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.onAccent,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Follow',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

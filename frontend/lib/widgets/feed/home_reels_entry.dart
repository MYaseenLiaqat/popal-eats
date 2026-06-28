import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'feed_constants.dart';
import 'feed_shimmer.dart';

/// Entry point banner for vertical food reels on the Home feed.
class HomeReelsEntry extends StatelessWidget {
  const HomeReelsEntry({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FeedConstants.cardRadius),
          child: Ink(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FeedConstants.cardRadius),
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.35),
                  AppColors.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(
                    Icons.play_circle_filled,
                    size: 100,
                    color: AppColors.accent.withValues(alpha: 0.15),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.slow_motion_video, color: AppColors.accent, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Food Reels',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Watch chefs, specials & new menu drops',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.accent),
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

class HomeReelsEntrySkeleton extends StatelessWidget {
  const HomeReelsEntrySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: FeedShimmer(
        borderRadius: FeedConstants.cardRadius,
        child: const SizedBox(height: 120),
      ),
    );
  }
}

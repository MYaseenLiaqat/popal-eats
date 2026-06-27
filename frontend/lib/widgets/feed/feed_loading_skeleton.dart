import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'feed_constants.dart';
import 'feed_shimmer.dart';

/// Instagram-style skeleton while the home feed loads.
class FeedLoadingSkeleton extends StatelessWidget {
  const FeedLoadingSkeleton({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FeedSkeletonBlock(height: 28, width: 180, borderRadius: 8),
              const SizedBox(height: 8),
              FeedSkeletonBlock(height: 16, width: 120, borderRadius: 6),
            ],
          ),
        ),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 6,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => Column(
              children: [
                FeedSkeletonBlock(height: 64, width: 64, borderRadius: 32),
                const SizedBox(height: 8),
                FeedSkeletonBlock(height: 10, width: 48, borderRadius: 4),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < itemCount; i++) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              children: [
                FeedSkeletonBlock(height: 36, width: 36, borderRadius: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FeedSkeletonBlock(height: 14, width: 120, borderRadius: 4),
                      const SizedBox(height: 6),
                      FeedSkeletonBlock(height: 10, width: 72, borderRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
          FeedSkeletonBlock(aspectRatio: FeedConstants.mediaAspectRatio),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: FeedSkeletonBlock(height: 14, width: 90, borderRadius: 4),
          ),
          Divider(height: 1, color: AppColors.border.withValues(alpha: 0.4)),
        ],
      ],
    );
  }
}

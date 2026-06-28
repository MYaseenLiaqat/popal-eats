import 'package:flutter/material.dart';

import '../feed/feed_shimmer.dart';
import 'dish_constants.dart';

class DishLoadingSkeleton extends StatelessWidget {
  const DishLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        FeedShimmer(
          child: SizedBox(
            height: DishConstants.heroHeight + MediaQuery.paddingOf(context).top,
            width: double.infinity,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FeedSkeletonBlock(height: 28, width: 240, borderRadius: 8),
              const SizedBox(height: 10),
              FeedSkeletonBlock(height: 18, width: 160, borderRadius: 6),
              const SizedBox(height: 16),
              FeedSkeletonBlock(height: 32, width: 120, borderRadius: 8),
              const SizedBox(height: 24),
              FeedSkeletonBlock(height: 100, borderRadius: DishConstants.cardRadius),
              const SizedBox(height: 16),
              FeedSkeletonBlock(height: 140, borderRadius: DishConstants.cardRadius),
            ],
          ),
        ),
      ],
    );
  }
}

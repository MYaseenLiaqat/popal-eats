import 'package:flutter/material.dart';

import '../feed/feed_shimmer.dart';
import 'restaurant_constants.dart';

class RestaurantLoadingSkeleton extends StatelessWidget {
  const RestaurantLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        FeedShimmer(
          child: SizedBox(
            height: RestaurantConstants.heroHeight + MediaQuery.paddingOf(context).top,
            width: double.infinity,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FeedSkeletonBlock(height: 140, borderRadius: RestaurantConstants.cardRadius),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FeedSkeletonBlock(height: 36, borderRadius: 20),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FeedSkeletonBlock(height: 48, borderRadius: RestaurantConstants.cardRadius),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < 4; i++)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: FeedSkeletonBlock(height: 118, borderRadius: RestaurantConstants.cardRadius),
          ),
      ],
    );
  }
}

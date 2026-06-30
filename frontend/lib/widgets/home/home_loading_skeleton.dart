import 'package:flutter/material.dart';

import '../feed/feed_shimmer.dart';
import 'home_constants.dart';

class HomeLoadingSkeleton extends StatelessWidget {
  const HomeLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        FeedShimmer(
          child: SizedBox(
            height: 180 + MediaQuery.paddingOf(context).top,
            width: double.infinity,
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: FeedSkeletonBlock(height: 56, borderRadius: HomeConstants.cardRadius),
        ),
        const SizedBox(height: 24),
        _sectionTitle(),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => const FeedSkeletonBlock(
              width: 88,
              height: 108,
              borderRadius: HomeConstants.cardRadius,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: FeedSkeletonBlock(height: 156, borderRadius: HomeConstants.cardRadius),
        ),
        const SizedBox(height: 24),
        _sectionTitle(),
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, __) => FeedSkeletonBlock(
              width: HomeConstants.carouselItemWidth(context),
              height: 260,
              borderRadius: HomeConstants.cardRadius,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle(),
        for (var i = 0; i < 3; i++)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: FeedSkeletonBlock(height: 108, borderRadius: HomeConstants.cardRadius),
          ),
      ],
    );
  }

  Widget _sectionTitle() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          FeedSkeletonBlock(width: 36, height: 36, borderRadius: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FeedSkeletonBlock(height: 18, width: 160, borderRadius: 6),
                SizedBox(height: 6),
                FeedSkeletonBlock(height: 12, width: 120, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

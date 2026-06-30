import 'package:flutter/material.dart';

import '../../models/recommendation.dart';
import '../../models/review.dart';
import '../../theme/app_colors.dart';
import '../../utils/price_formatter.dart';
import '../feed/feed_shimmer.dart';
import '../home/home_section_header.dart';
import '../reviews/review_widgets.dart';
import 'restaurant_constants.dart';

class RestaurantReviewsPreview extends StatelessWidget {
  const RestaurantReviewsPreview({
    super.key,
    required this.reviews,
    required this.averageRating,
    required this.totalReviews,
    required this.onWriteReview,
    this.loading = false,
  });

  final List<Review> reviews;
  final double averageRating;
  final int totalReviews;
  final VoidCallback onWriteReview;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionHeader(
          title: 'Reviews',
          subtitle: totalReviews > 0 ? '$totalReviews reviews' : 'No reviews yet',
          icon: Icons.rate_review_outlined,
          trailing: TextButton(onPressed: onWriteReview, child: const Text('Write')),
        ),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
          )
        else if (totalReviews == 0)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _InlineEmpty(
              icon: Icons.chat_bubble_outline,
              title: 'No reviews yet',
              subtitle: 'Be the first to share your experience',
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(RestaurantConstants.cardRadius),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
                boxShadow: AppColors.cardShadow(),
              ),
              child: Row(
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(5, (i) {
                            return Icon(
                              i < averageRating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 18,
                              color: AppColors.accent,
                            );
                          }),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalReviews reviews',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (reviews.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...reviews.take(3).map(
                  (r) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: ReviewListTile(review: r),
                  ),
                ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: onWriteReview,
              child: const Text('View all reviews'),
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class RestaurantRecommendedSection extends StatelessWidget {
  const RestaurantRecommendedSection({
    super.key,
    required this.items,
    required this.dishImages,
    this.onDishTap,
  });

  final List<Recommendation> items;
  final Map<int, String?> dishImages;
  final ValueChanged<int>? onDishTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Column(
        children: [
          HomeSectionHeader(
            title: 'Recommended for You',
            subtitle: 'Personalized picks from this restaurant',
            icon: Icons.auto_awesome_outlined,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _InlineEmpty(
              icon: Icons.restaurant_menu_outlined,
              title: 'No recommendations yet',
              subtitle: 'Check back for personalized dish picks',
            ),
          ),
          SizedBox(height: 16),
        ],
      );
    }

    final cardWidth = MediaQuery.sizeOf(context).width >= 900 ? 220.0 : 190.0;

    return Column(
      children: [
        HomeSectionHeader(
          title: 'Recommended for You',
          subtitle: '${items.length} picks for you',
          icon: Icons.auto_awesome_outlined,
        ),
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final rec = items[index];
              return _RecCard(
                recommendation: rec,
                imageUrl: dishImages[rec.dishId],
                width: cardWidth,
                onTap: () => onDishTap?.call(rec.dishId),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _RecCard extends StatefulWidget {
  const _RecCard({
    required this.recommendation,
    required this.width,
    this.imageUrl,
    this.onTap,
  });

  final Recommendation recommendation;
  final double width;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  State<_RecCard> createState() => _RecCardState();
}

class _RecCardState extends State<_RecCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Transform.scale(
          scale: _hovered ? 1.03 : 1.0,
          child: AnimatedContainer(
            duration: RestaurantConstants.animDuration,
            curve: RestaurantConstants.animCurve,
            width: widget.width,
            decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(RestaurantConstants.cardRadius),
            border: Border.all(
              color: _hovered
                  ? AppColors.accent.withValues(alpha: 0.4)
                  : AppColors.borderStrong.withValues(alpha: 0.5),
            ),
            boxShadow: _hovered ? AppColors.cardShadow(elevated: true) : AppColors.cardShadow(),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 110,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.imageUrl != null
                        ? Image.network(
                            widget.imageUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const FeedShimmer(child: SizedBox.expand());
                            },
                            errorBuilder: (_, __, ___) => _fallback(),
                          )
                        : _fallback(),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppColors.cardShadow(),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 12, color: AppColors.onAccent),
                            SizedBox(width: 4),
                            Text(
                              'AI Recommended',
                              style: TextStyle(
                                color: AppColors.onAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.recommendation.dishName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      PriceFormatter.format(widget.recommendation.price),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (widget.recommendation.calories != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentSubtle,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${widget.recommendation.calories} kcal',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
    );
  }

  Widget _fallback() {
    return Container(
      color: AppColors.accentSubtle,
      alignment: Alignment.center,
      child: Icon(Icons.restaurant, color: AppColors.accent.withValues(alpha: 0.5)),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(RestaurantConstants.cardRadius),
        border: Border.all(color: AppColors.borderStrong.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.accent, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

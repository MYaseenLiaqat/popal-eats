import 'package:flutter/material.dart';

import '../../models/recommendation.dart';
import '../../models/review.dart';
import '../../theme/app_colors.dart';
import '../../utils/price_formatter.dart';
import '../../utils/recommendation_copy.dart';
import '../feed/feed_shimmer.dart';
import '../home/home_section_header.dart';
import '../reviews/review_widgets.dart';
import 'dish_constants.dart';
import 'dish_nutrition_section.dart';

class DishReviewsSection extends StatelessWidget {
  const DishReviewsSection({
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

  Map<int, int> _breakdown() {
    final counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final review in reviews) {
      final star = review.rating.clamp(1, 5);
      counts[star] = (counts[star] ?? 0) + 1;
    }
    return counts;
  }

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
            child: DishInlineEmpty(
              icon: Icons.chat_bubble_outline,
              title: 'No reviews yet',
              subtitle: 'Be the first to review this restaurant',
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(DishConstants.cardRadius),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
                boxShadow: AppColors.cardShadow(),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < averageRating.round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 16,
                            color: AppColors.accent,
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [5, 4, 3, 2, 1].map((star) {
                        final counts = _breakdown();
                        final count = counts[star] ?? 0;
                        final total = reviews.isEmpty ? 1 : reviews.length;
                        final fraction = count / total;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Text('$star', style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(width: 6),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: fraction,
                                    minHeight: 6,
                                    backgroundColor: AppColors.surfaceLight,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
            child: TextButton(onPressed: onWriteReview, child: const Text('View all reviews')),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class DishRecommendedSection extends StatelessWidget {
  const DishRecommendedSection({
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
            title: 'Recommended with this',
            subtitle: 'Pairs well with your pick',
            icon: Icons.auto_awesome_outlined,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: DishInlineEmpty(
              icon: Icons.restaurant_menu_outlined,
              title: 'No recommendations yet',
              subtitle: 'Check back for personalized pairings',
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
          title: 'Recommended with this',
          subtitle: '${items.length} dishes you may like',
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
            duration: DishConstants.animDuration,
            curve: DishConstants.animCurve,
            width: widget.width,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(DishConstants.cardRadius),
              border: Border.all(
                color: _hovered
                    ? AppColors.accent.withValues(alpha: 0.4)
                    : AppColors.borderStrong.withValues(alpha: 0.5),
              ),
              boxShadow: _hovered ? AppColors.cardShadow(elevated: true) : AppColors.cardShadow(),
            ),
            clipBehavior: Clip.antiAlias,
            child: RepaintBoundary(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 110,
                    child: widget.imageUrl != null
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
                        const SizedBox(height: 4),
                        Text(
                          widget.recommendation.restaurantName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          PriceFormatter.format(widget.recommendation.price),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (widget.recommendation.confidencePercent != null ||
                            widget.recommendation.explanationBullets.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          if (widget.recommendation.confidencePercent != null)
                            Text(
                              RecommendationCopy.matchLabel(
                                widget.recommendation.confidencePercent!,
                              ),
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          if (widget.recommendation.explanationBullets.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.recommendation.explanationBullets.first,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
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

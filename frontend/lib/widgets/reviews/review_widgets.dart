import 'package:flutter/material.dart';

import '../../models/review.dart';
import '../../utils/review_display.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_display.dart';
import '../../utils/recommendation_copy.dart';
import '../ui/app_ui_widgets.dart';

class SentimentBadge extends StatelessWidget {
  const SentimentBadge({super.key, required this.sentiment});

  final String sentiment;

  @override
  Widget build(BuildContext context) {
    final normalized = sentiment.trim().toLowerCase();
    final color = switch (normalized) {
      'positive' => AppColors.accent,
      'negative' => Colors.redAccent,
      'neutral' => AppColors.textSecondary,
      _ => AppColors.accent,
    };
    final label = normalized.isEmpty
        ? 'Review'
        : '${normalized[0].toUpperCase()}${normalized.substring(1)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class ReviewStatsSummary extends StatelessWidget {
  const ReviewStatsSummary({
    super.key,
    required this.averageRating,
    required this.totalReviews,
    this.positiveCount = 0,
    this.neutralCount = 0,
    this.negativeCount = 0,
  });

  final double averageRating;
  final int totalReviews;
  final int positiveCount;
  final int neutralCount;
  final int negativeCount;

  @override
  Widget build(BuildContext context) {
    if (totalReviews == 0) {
      return ModernCard(
        child: Text(
          'No reviews yet — be the first to share your experience.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ModernCard(
      borderColor: AppColors.accent.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RatingBadge(rating: averageRating, reviews: totalReviews),
              const Spacer(),
              if (positiveCount > 0)
                SentimentBadge(sentiment: '$positiveCount positive'),
            ],
          ),
          if (positiveCount + neutralCount + negativeCount > 0) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (positiveCount > 0) _statChip('Positive', positiveCount, AppColors.accent),
                if (neutralCount > 0) _statChip('Neutral', neutralCount, AppColors.textSecondary),
                if (negativeCount > 0) _statChip('Negative', negativeCount, Colors.redAccent),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class ReviewListTile extends StatelessWidget {
  const ReviewListTile({super.key, required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.displayAuthor,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              RatingBadge(rating: review.rating.toDouble()),
              const SizedBox(width: 8),
              SentimentBadge(sentiment: effectiveSentiment(review)),
            ],
          ),
          if (review.createdAt != null) ...[
            const SizedBox(height: 4),
            Text(
              DateDisplay.formatRelativeUpdated(review.createdAt!),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class RestaurantReviewsSection extends StatelessWidget {
  const RestaurantReviewsSection({
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

  static ({int positive, int neutral, int negative}) sentimentCounts(
    List<Review> reviews,
  ) {
    var positive = 0;
    var neutral = 0;
    var negative = 0;
    for (final r in reviews) {
      switch (r.sentiment?.toLowerCase()) {
        case 'positive':
          positive++;
        case 'negative':
          negative++;
        case 'neutral':
          neutral++;
      }
    }
    return (positive: positive, neutral: neutral, negative: negative);
  }

  @override
  Widget build(BuildContext context) {
    final uniqueReviews = dedupeReviews(reviews);
    final counts = sentimentCountsFromRatings(uniqueReviews);
    final stats = uniqueReviews.isNotEmpty
        ? reviewStatsFromList(uniqueReviews)
        : (average: averageRating, total: totalReviews);
    final displayAverage = stats.average > 0 ? stats.average : averageRating;
    final displayTotal = stats.total > 0 ? stats.total : totalReviews;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Reviews',
          subtitle: displayTotal > 0 ? '$displayTotal total' : 'Share your experience',
          trailing: TextButton.icon(
            onPressed: onWriteReview,
            icon: const Icon(Icons.rate_review_outlined, size: 18),
            label: const Text('Write review'),
          ),
        ),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
          )
        else ...[
          ReviewStatsSummary(
            averageRating: displayAverage,
            totalReviews: displayTotal,
            positiveCount: counts.positive,
            neutralCount: counts.neutral,
            negativeCount: counts.negative,
          ),
          if (uniqueReviews.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...uniqueReviews.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ReviewListTile(review: r),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

Future<bool?> showWriteReviewSheet({
  required BuildContext context,
  required String restaurantName,
  required Future<void> Function(int rating, String? comment) onSubmit,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _WriteReviewSheet(
      restaurantName: restaurantName,
      onSubmit: onSubmit,
    ),
  );
}

class _WriteReviewSheet extends StatefulWidget {
  const _WriteReviewSheet({
    required this.restaurantName,
    required this.onSubmit,
  });

  final String restaurantName;
  final Future<void> Function(int rating, String? comment) onSubmit;

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final comment = _commentController.text.trim();
      await widget.onSubmit(
        _rating,
        comment.isEmpty ? null : comment,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = RecommendationCopy.friendlyError(e);
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Review ${widget.restaurantName}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.accent),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                onPressed: _submitting ? null : () => setState(() => _rating = star),
                icon: Icon(
                  star <= _rating ? Icons.star : Icons.star_border,
                  color: AppColors.accent,
                  size: 32,
                ),
              );
            }),
          ),
          TextField(
            controller: _commentController,
            maxLines: 4,
            maxLength: 2000,
            enabled: !_submitting,
            decoration: const InputDecoration(
              hintText: 'Share what you liked (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 8),
          GoldActionButton(
            label: 'Submit review',
            icon: Icons.send_outlined,
            loading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

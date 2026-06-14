import 'package:flutter/material.dart';

import '../../models/group_recommendation.dart';
import '../../models/group_vote.dart';
import '../../theme/app_colors.dart';
import '../ui/app_ui_widgets.dart';
import 'group_vote_widgets.dart';

class GroupScoreBadge extends StatelessWidget {
  const GroupScoreBadge({super.key, required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percent / 100,
            strokeWidth: 4,
            backgroundColor: AppColors.surfaceLight,
            color: AppColors.gold,
          ),
          Text(
            '$percent%',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class GroupRecommendationCard extends StatelessWidget {
  const GroupRecommendationCard({
    super.key,
    required this.recommendation,
    this.onTap,
    this.userVote,
    this.voteSummary,
    this.voting = false,
    this.pendingVote,
    this.loadingVoteSummary = false,
    this.onVote,
  });

  final GroupDishRecommendation recommendation;
  final VoidCallback? onTap;
  final String? userVote;
  final GroupVoteSummary? voteSummary;
  final bool voting;
  final String? pendingVote;
  final bool loadingVoteSummary;
  final ValueChanged<String>? onVote;

  bool get _canVote => recommendation.recommendationId != null && onVote != null;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: ModernCard(
          onTap: onTap,
          padding: EdgeInsets.zero,
          borderColor: AppColors.green.withValues(alpha: 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DishImageBanner(
                imageUrl: recommendation.dishImageUrl,
                height: 148,
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recommendation.dishName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              if (recommendation.restaurantName.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.storefront_outlined,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        recommendation.restaurantName,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        GroupScoreBadge(percent: recommendation.scorePercent),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '\$${recommendation.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            'Group score',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    if (recommendation.reasons.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Why this pick',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: recommendation.reasons.map(_reasonChip).toList(),
                      ),
                    ],
                    if (_canVote) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Your vote',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      VoteControls(
                        selectedVote: userVote,
                        pendingVote: pendingVote,
                        voting: voting,
                        onVote: onVote!,
                      ),
                    ],
                    VoteSummarySection(
                      summary: voteSummary,
                      loading: loadingVoteSummary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reasonChip(String reason) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 14, color: AppColors.green),
          const SizedBox(width: 4),
          Text(
            reason,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

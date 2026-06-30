import 'package:flutter/material.dart';

import '../../models/group_recommendation.dart';
import '../../models/group_vote.dart';
import '../../utils/price_formatter.dart';
import '../../theme/app_colors.dart';
import '../auth_screen_widgets.dart';
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
            color: AppColors.accent,
          ),
          Text(
            '$percent%',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.accent,
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
          borderColor: AppColors.accent.withValues(alpha: 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DishImageBanner(
                imageUrl: recommendation.dishImageUrl,
                height: 148,
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: CardInnerSurface(
                  padding: const EdgeInsets.all(12),
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
                                Text(
                                  recommendation.restaurantName,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        GroupScoreBadge(percent: recommendation.scorePercent),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          PriceFormatter.format(recommendation.price),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.brandGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '${recommendation.scorePercent}% match',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    if (recommendation.topReasons.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Why',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: recommendation.topReasons
                            .map((r) => _reasonChip(context, r))
                            .toList(),
                      ),
                    ],
                    if (_canVote) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Your vote',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 6),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reasonChip(BuildContext context, String reason) {
    final onBg = AppColors.contrastOn(AppColors.brandCardInner);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.brandCream.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: onBg.withValues(alpha: 0.15)),
      ),
      child: Text(
        reason,
        style: TextStyle(
          color: onBg,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

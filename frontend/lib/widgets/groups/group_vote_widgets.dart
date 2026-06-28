import 'package:flutter/material.dart';

import '../../models/group_decision.dart';
import '../../models/group_vote.dart';
import '../../theme/app_colors.dart';
import '../ui/app_ui_widgets.dart';

class ConsensusBanner extends StatelessWidget {
  const ConsensusBanner({
    super.key,
    required this.decision,
    this.loading = false,
    this.onViewDecision,
  });

  final GroupDecision? decision;
  final bool loading;
  final VoidCallback? onViewDecision;

  @override
  Widget build(BuildContext context) {
    if (loading && decision == null) {
      return const ModernCard(
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
            ),
            SizedBox(width: 12),
            Text('Loading group decision…'),
          ],
        ),
      );
    }

    if (decision == null) return const SizedBox.shrink();

    final status = decision!.status;
    final (icon, color, gradient) = _styleFor(status);

    return ModernCard(
      gradient: gradient,
      borderColor: color.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusLabel(status),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      decision!.bannerMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (decision!.dishName != null && !decision!.isPending) ...[
                      const SizedBox(height: 8),
                      Text(
                        decision!.dishName!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                      ),
                      if (decision!.restaurantName != null)
                        Text(
                          decision!.restaurantName!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (onViewDecision != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onViewDecision,
                icon: const Icon(Icons.how_to_vote_outlined, size: 18),
                label: const Text('View decision'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  (IconData, Color, Gradient?) _styleFor(String status) {
    switch (status) {
      case GroupDecisionStatus.considering:
        return (
          Icons.hourglass_top_outlined,
          AppColors.accent,
          LinearGradient(
            colors: [
              AppColors.accent.withValues(alpha: 0.12),
              AppColors.surfaceLight.withValues(alpha: 0.4),
            ],
          ),
        );
      case GroupDecisionStatus.agreed:
        return (
          Icons.check_circle_outline,
          AppColors.accent,
          LinearGradient(
            colors: [
              AppColors.accent.withValues(alpha: 0.12),
              AppColors.surfaceLight.withValues(alpha: 0.4),
            ],
          ),
        );
      case GroupDecisionStatus.ordered:
        return (
          Icons.shopping_bag_outlined,
          AppColors.accent,
          LinearGradient(
            colors: [
              AppColors.accent.withValues(alpha: 0.18),
              AppColors.surfaceLight.withValues(alpha: 0.4),
            ],
          ),
        );
      default:
        return (
          Icons.pending_outlined,
          AppColors.textSecondary,
          null,
        );
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case GroupDecisionStatus.considering:
        return 'Considering';
      case GroupDecisionStatus.agreed:
        return 'Agreed';
      case GroupDecisionStatus.ordered:
        return 'Ordered';
      default:
        return 'Pending';
    }
  }
}

class VoteControls extends StatelessWidget {
  const VoteControls({
    super.key,
    required this.selectedVote,
    required this.voting,
    required this.onVote,
    this.pendingVote,
    this.enabled = true,
  });

  final String? selectedVote;
  final String? pendingVote;
  final bool voting;
  final ValueChanged<String> onVote;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _VoteButton(
            label: 'Like',
            icon: Icons.thumb_up_outlined,
            voteType: GroupVoteType.like,
            selected: selectedVote == GroupVoteType.like,
            loading: voting && pendingVote == GroupVoteType.like,
            disabled: !enabled || voting,
            color: AppColors.accent,
            onTap: () => onVote(GroupVoteType.like),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _VoteButton(
            label: 'Love',
            icon: Icons.favorite_outline,
            voteType: GroupVoteType.love,
            selected: selectedVote == GroupVoteType.love,
            loading: voting && pendingVote == GroupVoteType.love,
            disabled: !enabled || voting,
            color: AppColors.accent,
            onTap: () => onVote(GroupVoteType.love),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _VoteButton(
            label: 'Dislike',
            icon: Icons.thumb_down_outlined,
            voteType: GroupVoteType.dislike,
            selected: selectedVote == GroupVoteType.dislike,
            loading: voting && pendingVote == GroupVoteType.dislike,
            disabled: !enabled || voting,
            color: Colors.redAccent,
            onTap: () => onVote(GroupVoteType.dislike),
          ),
        ),
      ],
    );
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.label,
    required this.icon,
    required this.voteType,
    required this.selected,
    required this.loading,
    required this.disabled,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String voteType;
  final bool selected;
  final bool loading;
  final bool disabled;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = selected ? color : AppColors.textSecondary;
    final bg = selected ? color.withValues(alpha: 0.18) : AppColors.surfaceLight.withValues(alpha: 0.5);
    final border = selected ? color.withValues(alpha: 0.6) : AppColors.surfaceLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              if (loading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: color),
                )
              else
                Icon(icon, size: 20, color: activeColor),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: activeColor,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VoteSummarySection extends StatelessWidget {
  const VoteSummarySection({
    super.key,
    required this.summary,
    this.loading = false,
  });

  final GroupVoteSummary? summary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading && summary == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
            ),
            SizedBox(width: 8),
            Text('Loading votes…', style: TextStyle(fontSize: 13)),
          ],
        ),
      );
    }

    if (summary == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vote breakdown',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _countChip(Icons.thumb_up_outlined, 'Likes', summary!.likes, AppColors.accent),
              const SizedBox(width: 8),
              _countChip(Icons.favorite_outline, 'Loves', summary!.loves, AppColors.accent),
              const SizedBox(width: 8),
              _countChip(Icons.thumb_down_outlined, 'Dislikes', summary!.dislikes, Colors.redAccent),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _scoreBar(
                  context,
                  label: 'Group agreement',
                  percent: summary!.consensusPercent,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _scoreBar(
                  context,
                  label: 'Overall match',
                  percent: summary!.finalPercent,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${summary!.totalVotes} total vote${summary!.totalVotes == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _countChip(IconData icon, String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreBar(
    BuildContext context, {
    required String label,
    required int percent,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            Text(
              '$percent%',
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 6,
            backgroundColor: AppColors.surfaceLight,
            color: color,
          ),
        ),
      ],
    );
  }
}

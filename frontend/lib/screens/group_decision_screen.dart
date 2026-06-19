import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/group_decision.dart';
import '../providers/group_provider.dart';
import '../theme/app_colors.dart';
import '../utils/price_formatter.dart';
import '../widgets/groups/group_vote_widgets.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'dish_detail_screen.dart';

/// Group consensus decision with vote breakdown and order flow.
class GroupDecisionScreen extends StatefulWidget {
  const GroupDecisionScreen({
    super.key,
    required this.sessionId,
    this.groupName,
  });

  final int sessionId;
  final String? groupName;

  @override
  State<GroupDecisionScreen> createState() => _GroupDecisionScreenState();
}

class _GroupDecisionScreenState extends State<GroupDecisionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool force = true}) async {
    final provider = context.read<GroupProvider>();
    await provider.loadDecision(widget.sessionId, force: force);
    if (!mounted) return;

    final decision = provider.groupDecision;
    if (decision?.recommendationId != null) {
      await provider.loadVoteSummary(decision!.recommendationId!);
    }
  }

  Future<void> _markOrdered() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as ordered?'),
        content: const Text(
          'Confirm that your group has placed the order for the agreed dish.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<GroupProvider>();
    final ok = await provider.markDecisionOrdered(widget.sessionId);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Decision marked as ordered')),
      );
      return;
    }

    final message = provider.decisionError ?? 'Could not mark as ordered';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GroupProvider>();
    final decision = provider.decisionSessionId == widget.sessionId ? provider.groupDecision : null;
    final voteSummary = decision?.recommendationId != null
        ? provider.voteSummaryFor(decision!.recommendationId!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName != null ? '${widget.groupName} decision' : 'Group decision'),
      ),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () => _load(force: true),
        child: _buildBody(provider, decision, voteSummary),
      ),
    );
  }

  Widget _buildBody(GroupProvider provider, GroupDecision? decision, voteSummary) {
    if (provider.loadingDecision && decision == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }

    if (provider.decisionError != null && decision == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppColors.screenPadding),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load decision',
                  subtitle: provider.decisionError,
                ),
                TextButton(onPressed: () => _load(force: true), child: const Text('Retry')),
              ],
            ),
          ),
        ],
      );
    }

    if (decision == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppColors.screenPadding),
        children: const [
          SizedBox(height: 40),
          EmptyState(
            icon: Icons.how_to_vote_outlined,
            title: 'No decision yet',
            subtitle: 'Vote on recommendations to help your group reach consensus',
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppColors.screenPadding),
      children: [
        ConsensusBanner(decision: decision),
        const SizedBox(height: 16),
        ModernCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _statusChip(decision.status),
              const SizedBox(height: 16),
              if (decision.dishName != null) ...[
                Text('Agreed pick', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  decision.dishName!,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.gold),
                ),
                if (decision.restaurantName != null) ...[
                  const SizedBox(height: 4),
                  Text(decision.restaurantName!, style: Theme.of(context).textTheme.bodyMedium),
                ],
                if (decision.price != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    PriceFormatter.format(decision.price!),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.green,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
                if (decision.dishId != null) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DishDetailScreen(dishId: decision.dishId!),
                      ),
                    ),
                    icon: const Icon(Icons.restaurant_menu, size: 18),
                    label: const Text('View dish details'),
                  ),
                ],
              ] else ...[
                Text(
                  'No dish selected yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        ModernCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Scores', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (decision.consensusPercent != null || decision.finalPercent != null)
                Row(
                  children: [
                    if (decision.consensusPercent != null)
                      Expanded(
                        child: _scoreTile(
                          context,
                          label: 'Consensus',
                          percent: decision.consensusPercent!,
                          color: AppColors.green,
                        ),
                      ),
                    if (decision.consensusPercent != null && decision.finalPercent != null)
                      const SizedBox(width: 12),
                    if (decision.finalPercent != null)
                      Expanded(
                        child: _scoreTile(
                          context,
                          label: 'Final score',
                          percent: decision.finalPercent!,
                          color: AppColors.gold,
                        ),
                      ),
                  ],
                )
              else
                Text(
                  'Votes will show up once your group starts voting',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
            ],
          ),
        ),
        if (voteSummary != null) ...[
          const SizedBox(height: 16),
          ModernCard(
            child: VoteSummarySection(summary: voteSummary),
          ),
        ],
        if (decision.isAgreed) ...[
          const SizedBox(height: 24),
          GoldActionButton(
            label: 'Mark as Ordered',
            icon: Icons.shopping_bag_outlined,
            loading: provider.orderingDecision,
            onPressed: provider.orderingDecision ? null : _markOrdered,
          ),
        ],
        if (decision.isOrdered) ...[
          const SizedBox(height: 16),
          ModernCard(
            borderColor: AppColors.green.withValues(alpha: 0.4),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your group has finalized this decision.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _statusChip(String status) {
    final (label, color) = switch (status) {
      GroupDecisionStatus.considering => ('Considering', AppColors.gold),
      GroupDecisionStatus.agreed => ('Agreed', AppColors.green),
      GroupDecisionStatus.ordered => ('Ordered', AppColors.green),
      _ => ('Pending', AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _scoreTile(
    BuildContext context, {
    required String label,
    required int percent,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Text(
            '$percent%',
            style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

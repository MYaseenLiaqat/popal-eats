import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/group_vote.dart';
import '../providers/group_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/groups/group_recommendation_card.dart';
import '../widgets/groups/group_vote_widgets.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'dish_detail_screen.dart';
import 'group_decision_screen.dart';

/// Group-ranked dish recommendations for a session.
class GroupRecommendationsScreen extends StatefulWidget {
  const GroupRecommendationsScreen({
    super.key,
    required this.sessionId,
    this.groupName,
  });

  final int sessionId;
  final String? groupName;

  @override
  State<GroupRecommendationsScreen> createState() =>
      _GroupRecommendationsScreenState();
}

class _GroupRecommendationsScreenState extends State<GroupRecommendationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh({bool regenerate = false}) async {
    final provider = context.read<GroupProvider>();
    await provider.loadRecommendations(
      widget.sessionId,
      force: true,
      refresh: regenerate,
    );
  }

  Future<void> _vote(int recommendationId, String voteType) async {
    final provider = context.read<GroupProvider>();
    final ok = await provider.voteOnRecommendation(
      recommendationId: recommendationId,
      voteType: voteType,
      sessionId: widget.sessionId,
    );
    if (!mounted) return;

    if (ok) {
      final label = switch (voteType) {
        GroupVoteType.love => 'Love',
        GroupVoteType.dislike => 'Dislike',
        _ => 'Like',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vote recorded: $label')),
      );
      return;
    }

    final message = provider.voteError ?? 'Could not record vote';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openDecision() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupDecisionScreen(
          sessionId: widget.sessionId,
          groupName: widget.groupName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GroupProvider>();
    final result = provider.recommendationsSessionId == widget.sessionId
        ? provider.groupRecommendations
        : null;
    final decision = provider.decisionSessionId == widget.sessionId
        ? provider.groupDecision
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName ?? 'Group picks'),
        actions: [
          IconButton(
            tooltip: 'Group decision',
            icon: const Icon(Icons.how_to_vote_outlined),
            onPressed: _openDecision,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () => _refresh(regenerate: true),
        child: _buildBody(provider, result, decision),
      ),
    );
  }

  Widget _buildBody(GroupProvider provider, result, decision) {
    if (provider.loadingRecommendations && result == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }

    if (provider.recommendationsError != null && result == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load recommendations',
                  subtitle: provider.recommendationsError,
                ),
                TextButton(
                  onPressed: () => _refresh(regenerate: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (result == null || result.recommendations.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppColors.screenPadding),
        children: [
          const SizedBox(height: 40),
          const EmptyState(
            icon: Icons.restaurant_outlined,
            title: 'No recommendations available yet',
            subtitle:
                'Make sure members have shared locations and preferences, then refresh',
          ),
          const SizedBox(height: 20),
          GoldActionButton(
            label: 'Refresh',
            icon: Icons.refresh,
            loading: provider.loadingRecommendations,
            onPressed: provider.loadingRecommendations
                ? null
                : () => _refresh(regenerate: true),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppColors.screenPadding),
      children: [
        ConsensusBanner(
          decision: decision,
          loading: provider.loadingDecision && decision == null,
          onViewDecision: _openDecision,
        ),
        const SizedBox(height: 16),
        ModernCard(
          gradient: AppColors.headerGradient,
          borderColor: AppColors.gold.withValues(alpha: 0.35),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.groups, color: AppColors.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Picks for your group',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.gold,
                          ),
                    ),
                    Text(
                      '${result.memberCount} members · ${result.recommendations.length} dishes ranked',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (result.groupLatitude != null && result.groupLongitude != null)
                      Text(
                        'Based on shared group location',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.green,
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...result.recommendations.map((item) {
          final recId = item.recommendationId;
          return GroupRecommendationCard(
            recommendation: item,
            userVote: recId != null ? provider.userVoteFor(recId) : null,
            pendingVote: recId != null ? provider.pendingVoteFor(recId) : null,
            voteSummary: recId != null ? provider.voteSummaryFor(recId) : null,
            voting: recId != null && provider.isVotingOn(recId),
            loadingVoteSummary: provider.loadingVoteSummaries && recId != null && !provider.voteSummaries.containsKey(recId),
            onVote: recId != null ? (voteType) => _vote(recId, voteType) : null,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DishDetailScreen(dishId: item.dishId),
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }
}

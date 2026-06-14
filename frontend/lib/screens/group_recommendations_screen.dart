import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/group_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/groups/group_recommendation_card.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'dish_detail_screen.dart';

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
      context.read<GroupProvider>().loadRecommendations(widget.sessionId, force: true);
    });
  }

  Future<void> _refresh() async {
    await context.read<GroupProvider>().loadRecommendations(widget.sessionId, force: true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GroupProvider>();
    final result = provider.recommendationsSessionId == widget.sessionId
        ? provider.groupRecommendations
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName ?? 'Group picks'),
      ),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: _refresh,
        child: _buildBody(provider, result),
      ),
    );
  }

  Widget _buildBody(GroupProvider provider, result) {
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
                  onPressed: _refresh,
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
            onPressed: provider.loadingRecommendations ? null : _refresh,
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppColors.screenPadding),
      children: [
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
        ...result.recommendations.asMap().entries.map((entry) {
          return GroupRecommendationCard(
            recommendation: entry.value,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DishDetailScreen(dishId: entry.value.dishId),
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }
}

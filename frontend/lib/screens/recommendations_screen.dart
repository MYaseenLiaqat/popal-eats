import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recommendation.dart';
import '../providers/recommendation_provider.dart';
import '../theme/app_colors.dart';
import '../utils/recommendation_copy.dart';
import '../widgets/social/notification_hub_button.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'dish_detail_screen.dart';

/// Personalized, trending, and popular dishes.
class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key, this.isTabActive = false});

  /// When true, triggers the first recommendation load (lazy — not at app startup).
  final bool isTabActive;

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  bool _activated = false;

  @override
  void initState() {
    super.initState();
    _activateIfNeeded();
  }

  @override
  void didUpdateWidget(covariant RecommendationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isTabActive && widget.isTabActive) {
      _activateIfNeeded();
    }
  }

  void _activateIfNeeded() {
    if (!widget.isTabActive || _activated) return;
    _activated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RecommendationProvider>().fetchAll();
    });
  }

  Future<void> _refresh() async {
    await context.read<RecommendationProvider>().fetchAll(force: true);
  }

  void _openDish(Recommendation rec) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DishDetailScreen(dishId: rec.dishId),
      ),
    );
  }

  int _matchPercent(Recommendation rec) {
    if (rec.confidencePercent != null) {
      return rec.confidencePercent!.clamp(0, 100);
    }
    if (rec.score <= 10) {
      return (rec.score * 10).round().clamp(0, 100);
    }
    return rec.score.round().clamp(0, 100);
  }

  List<String> _whyReasons(Recommendation rec) {
    if (rec.explanationBullets.isNotEmpty) {
      return rec.explanationBullets.take(5).toList();
    }
    return RecommendationCopy.humanReasons(rec);
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required List<Recommendation> items,
    required bool loading,
    String? error,
    VoidCallback? onRetry,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          subtitle: loading
              ? 'Loading…'
              : (items.isEmpty ? 'No results yet' : subtitle),
          trailing: items.isNotEmpty
              ? Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accent, size: 20),
                )
              : null,
        ),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          )
        else if (error != null && items.isEmpty)
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(error, style: Theme.of(context).textTheme.bodyMedium),
                if (onRetry != null) ...[
                  const SizedBox(height: 8),
                  TextButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ],
            ),
          )
        else if (items.isEmpty)
          ModernCard(
            child: Text(
              'Check back later for new picks',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
          ...items.map(
            (rec) => RecommendationCard(
              dishName: rec.dishName,
              restaurantName: rec.restaurantName,
              price: rec.price,
              score: rec.score,
              explanation: rec.explanation,
              calories: rec.calories,
              matchPercent: _matchPercent(rec),
              whyReasons: _whyReasons(rec),
              onTap: () => _openDish(rec),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rec = context.watch<RecommendationProvider>();

    if (!_activated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Discover'),
          actions: const [NotificationHubButton()],
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    final showInitialLoader = rec.isLoading && !rec.hasCache;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: const [NotificationHubButton()],
      ),
      body: showInitialLoader
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : rec.allFailed
              ? ListView(
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
                            subtitle: rec.personalizedError ??
                                rec.trendingError ??
                                rec.popularError,
                          ),
                          TextButton(onPressed: _refresh, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  color: AppColors.accent,
                  child: ListView(
                    padding: const EdgeInsets.all(AppColors.screenPadding),
                    children: [
                      ModernCard(
                        gradient: AppColors.headerGradient,
                        borderColor: AppColors.accent.withValues(alpha: 0.4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.restaurant_outlined,
                                    color: AppColors.accent,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        RecommendationCopy.sectionHeroTitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(color: AppColors.accent),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        RecommendationCopy.sectionHeroSubtitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildSection(
                        title: 'For You',
                        subtitle:
                            '${rec.personalized.length} dishes picked for you',
                        icon: Icons.favorite_outline,
                        accent: AppColors.accent,
                        items: rec.personalized,
                        loading: rec.loadingPersonalized,
                        error: rec.personalizedError,
                        onRetry: () => rec.refreshPersonalized(),
                      ),
                      _buildSection(
                        title: 'Trending',
                        subtitle: '${rec.trending.length} rising picks',
                        icon: Icons.trending_up,
                        accent: AppColors.accent,
                        items: rec.trending,
                        loading: rec.loadingTrending,
                        error: rec.trendingError,
                        onRetry: () => rec.refreshTrending(),
                      ),
                      _buildSection(
                        title: 'Popular',
                        subtitle: '${rec.popular.length} crowd favorites',
                        icon: Icons.local_fire_department_outlined,
                        accent: AppColors.accent,
                        items: rec.popular,
                        loading: rec.loadingPopular,
                        error: rec.popularError,
                        onRetry: () => rec.refreshPopular(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }
}

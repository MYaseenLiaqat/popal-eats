import 'package:flutter/material.dart';

import '../models/recommendation.dart';
import '../services/recommendation_service.dart';
import '../theme/app_colors.dart';
import '../utils/recommendation_copy.dart';
import '../widgets/social/notification_hub_button.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'dish_detail_screen.dart';
import 'reels_screen.dart';

/// Personalized, trending, and popular dishes.
class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final _recommendations = RecommendationService();

  List<Recommendation> personalized = [];
  List<Recommendation> trending = [];
  List<Recommendation> popular = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final results = await Future.wait([
        _recommendations.list(),
        _recommendations.trending(),
        _recommendations.popular(),
      ]);
      if (!mounted) return;
      setState(() {
        personalized = results[0];
        trending = results[1];
        popular = results[2];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
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
    if (rec.score <= 10) {
      return (rec.score * 10).round().clamp(0, 100);
    }
    return rec.score.round().clamp(0, 100);
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required List<Recommendation> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          subtitle: items.isEmpty ? 'No results yet' : subtitle,
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
        if (items.isEmpty)
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
              whyReasons: RecommendationCopy.humanReasons(rec),
              onTap: () => _openDish(rec),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: const [NotificationHubButton()],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : error != null
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
                            subtitle: error,
                          ),
                          TextButton(onPressed: _load, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.gold,
                  child: ListView(
                    padding: const EdgeInsets.all(AppColors.screenPadding),
                    children: [
                      ModernCard(
                        gradient: AppColors.headerGradient,
                        borderColor: AppColors.green.withValues(alpha: 0.4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.green
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.restaurant_outlined,
                                    color: AppColors.green,
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
                                            ?.copyWith(color: AppColors.gold),
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
                            '${personalized.length} dishes picked for you',
                        icon: Icons.favorite_outline,
                        accent: AppColors.gold,
                        items: personalized,
                      ),
                      _buildSection(
                        title: 'Trending',
                        subtitle: '${trending.length} rising picks',
                        icon: Icons.trending_up,
                        accent: AppColors.green,
                        items: trending,
                      ),
                      _buildSection(
                        title: 'Popular',
                        subtitle: '${popular.length} crowd favorites',
                        icon: Icons.local_fire_department_outlined,
                        accent: AppColors.gold,
                        items: popular,
                      ),
                      const SectionHeader(
                        title: 'Recipe & chef reels',
                        subtitle: 'Short food stories — video coming soon',
                      ),
                      ModernCard(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ReelsScreen()),
                        ),
                        borderColor: AppColors.gold.withValues(alpha: 0.35),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.play_circle_outline,
                                color: AppColors.gold,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Watch reels',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Swipe through recipe and chef previews',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }
}

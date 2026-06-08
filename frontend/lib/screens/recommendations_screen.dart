import 'package:flutter/material.dart';

import '../models/recommendation.dart';
import '../services/recommendation_service.dart';
import '../theme/app_colors.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'dish_detail_screen.dart';

/// Recommendation Engine V2 — personalized, trending, and popular dishes.
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
              'Check back later for AI-powered picks',
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
      appBar: AppBar(title: const Text('Recommendations')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppColors.screenPadding),
                    child: Text(error!, textAlign: TextAlign.center),
                  ),
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
                                    Icons.psychology,
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
                                        'AI Nutrition Engine',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(color: AppColors.gold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Personalized picks based on your taste & health goals',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const AiMatchBadge(),
                          ],
                        ),
                      ),
                      _buildSection(
                        title: 'For You',
                        subtitle:
                            '${personalized.length} personalized matches',
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
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }
}

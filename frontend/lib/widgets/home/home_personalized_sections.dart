import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../models/recommendation.dart';
import '../../providers/recommendation_provider.dart';
import '../../services/health_nutrition_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/price_formatter.dart';
import '../../widgets/home/home_constants.dart';
import '../../widgets/home/home_dish_horizontal_card.dart';
import '../../widgets/home/home_section_header.dart';
import '../../widgets/ui/app_ui_widgets.dart';
import '../../screens/health_dashboard_screen.dart';
import '../../screens/orders_screen.dart';

/// Personalized blocks for Home: health, recommendations, recent orders.
class HomePersonalizedSections extends StatefulWidget {
  const HomePersonalizedSections({
    super.key,
    required this.isActive,
    required this.onOpenDish,
    required this.onOpenRecommendations,
  });

  final bool isActive;
  final void Function(int dishId) onOpenDish;
  final VoidCallback onOpenRecommendations;

  @override
  State<HomePersonalizedSections> createState() =>
      _HomePersonalizedSectionsState();
}

class _HomePersonalizedSectionsState extends State<HomePersonalizedSections> {
  final _healthService = HealthNutritionService();
  final _orderService = OrderService();

  HealthNutritionSummary? _health;
  List<Order> _recentOrders = [];
  bool _loadingExtras = false;

  @override
  void initState() {
    super.initState();
    _loadIfActive();
  }

  @override
  void didUpdateWidget(covariant HomePersonalizedSections oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _loadIfActive();
    }
  }

  Future<void> _loadIfActive() async {
    if (!widget.isActive || _loadingExtras) return;
    setState(() => _loadingExtras = true);

    final recFuture = context.read<RecommendationProvider>().fetchAll();
    final healthFuture = _healthService.load(days: 7);
    final ordersFuture = _orderService.myOrders(limit: 8);

    try {
      final results = await Future.wait([healthFuture, ordersFuture]);
      if (!mounted) return;
      setState(() {
        _health = results[0] as HealthNutritionSummary;
        _recentOrders = results[1] as List<Order>;
        _loadingExtras = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingExtras = false);
    }

    await recFuture;
  }

  int _matchPercent(Recommendation rec) {
    if (rec.score <= 10) {
      return (rec.score * 10).round().clamp(0, 100);
    }
    return rec.score.round().clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final rec = context.watch<RecommendationProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _healthSummaryCard(context),
        if (rec.personalized.isNotEmpty) ...[
          HomeSectionHeader(
            title: 'Recommended for you',
            subtitle: '${rec.personalized.length} dishes picked for you',
            icon: Icons.auto_awesome_outlined,
            onSeeAll: widget.onOpenRecommendations,
          ),
          SizedBox(
            height: 250,
            child: rec.loadingPersonalized
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: rec.personalized.length.clamp(0, 10),
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final item = rec.personalized[index];
                      return HomeDishHorizontalCard(
                        recommendation: item,
                        width: HomeConstants.dishCardWidth(context),
                        matchPercent: _matchPercent(item),
                        onTap: () => widget.onOpenDish(item.dishId),
                      );
                    },
                  ),
          ),
          const SizedBox(height: HomeConstants.sectionSpacing),
        ],
        if (_recentOrders.isNotEmpty) ...[
          HomeSectionHeader(
            title: 'Recently ordered',
            subtitle: 'Pick up where you left off',
            icon: Icons.history,
            onSeeAll: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdersScreen()),
            ),
          ),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _recentOrders.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final order = _recentOrders[index];
                final itemCount =
                    order.items.fold<int>(0, (a, i) => a + i.quantity);
                return ModernCard(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrdersScreen()),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: SizedBox(
                    width: 180,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Order #${order.id}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$itemCount item${itemCount == 1 ? '' : 's'} · ${PriceFormatter.format(order.totalPrice)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: HomeConstants.sectionSpacing),
        ],
        const HomeSectionHeader(
          title: 'Activity feed',
          subtitle: 'Stories, reels, and posts from restaurants',
          icon: Icons.dynamic_feed_outlined,
        ),
      ],
    );
  }

  Widget _healthSummaryCard(BuildContext context) {
    final summary = _health;
    final avgScore = summary?.avgHealthScore ?? 0;
    final weekCals = summary?.totalCalories ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: ModernCard(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HealthDashboardScreen()),
        ),
        gradient: AppColors.headerGradient,
        borderColor: AppColors.accent.withValues(alpha: 0.35),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.monitor_heart_outlined,
                color: AppColors.accent,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Health summary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.accent,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary?.hasData == true
                        ? '$weekCals kcal this week · score $avgScore'
                        : 'Track nutrition from your orders',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

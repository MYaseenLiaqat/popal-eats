import 'package:flutter/material.dart';

import '../models/restaurant.dart';
import '../models/restaurant_dashboard.dart';
import '../services/restaurant_owner_service.dart';
import '../theme/app_colors.dart';
import '../utils/price_formatter.dart';
import '../utils/recommendation_copy.dart';
import '../widgets/admin/admin_charts.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Dashboard home tab for restaurant owners.
class RestaurantDashboardHome extends StatefulWidget {
  const RestaurantDashboardHome({
    super.key,
    required this.restaurant,
    required this.onNavigateOrders,
    required this.onNavigateMenu,
    required this.onNavigateContent,
  });

  final Restaurant restaurant;
  final VoidCallback onNavigateOrders;
  final VoidCallback onNavigateMenu;
  final VoidCallback onNavigateContent;

  @override
  State<RestaurantDashboardHome> createState() => _RestaurantDashboardHomeState();
}

class _RestaurantDashboardHomeState extends State<RestaurantDashboardHome> {
  final _service = RestaurantOwnerService();
  RestaurantDashboard? _dashboard;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RestaurantDashboardHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.restaurant.id != widget.restaurant.id) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dash = await _service.dashboard(widget.restaurant.id);
      if (!mounted) return;
      setState(() {
        _dashboard = dash;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = RecommendationCopy.friendlyError(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _dashboard == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _dashboard == null) {
      return Center(child: Text(_error!));
    }
    final dash = _dashboard;
    if (dash == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.accent,
      child: ListView(
        padding: const EdgeInsets.all(AppColors.screenPadding),
        children: [
          SectionHeader(
            title: "Today's overview",
            subtitle: dash.restaurantName,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: "Today's orders",
                  value: '${dash.ordersToday}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Pending',
                  value: '${dash.pendingOrders}',
                  accent: dash.pendingOrders > 0 ? AppColors.accent : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Completed today',
                  value: '${dash.completedOrdersToday}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: "Today's revenue",
                  value: PriceFormatter.format(dash.revenueToday),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionHeader(
            title: 'Revenue snapshot',
            subtitle: 'Today vs dish performance',
          ),
          const SizedBox(height: 8),
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  PriceFormatter.format(dash.revenueToday),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text("Today's revenue", style: Theme.of(context).textTheme.bodySmall),
                if (dash.popularDishes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  AdminBarChart(
                    title: 'Top dishes by orders',
                    entries: dash.popularDishes
                        .take(5)
                        .map((d) => (label: d.dishName, value: d.orderCount))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Menu items',
                  value: '${dash.totalDishes}',
                  sub: '${dash.availableDishes} available',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Total orders',
                  value: '${dash.totalOrders}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Avg rating',
                  value: dash.averageRating.toStringAsFixed(1),
                  sub: '${dash.totalReviews} reviews',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Popular dish',
                  value: dash.popularDish?.dishName ?? '—',
                  sub: dash.popularDish != null
                      ? '${dash.popularDish!.orderCount} orders'
                      : 'No orders yet',
                ),
              ),
            ],
          ),
          if (dash.recentReviews.isNotEmpty) ...[
            const SizedBox(height: 20),
            const SectionHeader(title: 'Recent reviews', subtitle: 'Latest customer feedback'),
            ...dash.recentReviews.map(
              (review) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < review.rating ? Icons.star : Icons.star_border,
                              size: 16,
                              color: AppColors.accent,
                            ),
                          ),
                          const Spacer(),
                          if (review.authorName != null)
                            Text(
                              review.authorName!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                      if (review.comment != null && review.comment!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(review.comment!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          const SectionHeader(title: 'Quick actions'),
          const SizedBox(height: 8),
          GoldActionButton(
            label: 'Manage orders',
            icon: Icons.receipt_long,
            onPressed: widget.onNavigateOrders,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: widget.onNavigateMenu,
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Edit menu'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: widget.onNavigateContent,
            icon: const Icon(Icons.campaign_outlined),
            label: const Text('Create content'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.sub,
    this.accent,
  });

  final String label;
  final String value;
  final String? sub;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: accent ?? AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (sub != null) Text(sub!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

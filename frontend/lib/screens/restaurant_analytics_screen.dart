import 'package:flutter/material.dart';

import '../models/restaurant_dashboard.dart';
import '../services/restaurant_owner_service.dart';
import '../theme/app_colors.dart';
import '../utils/price_formatter.dart';
import '../utils/recommendation_copy.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Restaurant analytics tab — real metrics from the database.
class RestaurantAnalyticsScreen extends StatefulWidget {
  const RestaurantAnalyticsScreen({super.key, required this.restaurantId});

  final int restaurantId;

  @override
  State<RestaurantAnalyticsScreen> createState() => _RestaurantAnalyticsScreenState();
}

class _RestaurantAnalyticsScreenState extends State<RestaurantAnalyticsScreen> {
  final _service = RestaurantOwnerService();
  RestaurantDashboard? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RestaurantAnalyticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.restaurantId != widget.restaurantId) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.analytics(widget.restaurantId);
      if (!mounted) return;
      setState(() {
        _data = data;
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
    if (_loading && _data == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    if (_error != null && _data == null) {
      return Center(child: Text(_error!));
    }
    final data = _data!;
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.accent,
      child: ListView(
        padding: const EdgeInsets.all(AppColors.screenPadding),
        children: [
          SectionHeader(title: 'Performance', subtitle: data.restaurantName),
          const SizedBox(height: 8),
          _MetricTile(label: 'Orders today', value: '${data.ordersToday}'),
          _MetricTile(label: 'Revenue today', value: PriceFormatter.format(data.revenueToday)),
          _MetricTile(label: 'Total orders', value: '${data.totalOrders}'),
          _MetricTile(
            label: 'Average rating',
            value: data.averageRating.toStringAsFixed(1),
          ),
          _MetricTile(label: 'Total reviews', value: '${data.totalReviews}'),
          _MetricTile(label: 'Menu items', value: '${data.totalDishes}'),
          _MetricTile(label: 'Post engagement', value: '${data.postEngagement}'),
          _MetricTile(label: 'Total posts', value: '${data.totalPosts}'),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Top selling dishes'),
          if (data.popularDishes.isEmpty)
            const ModernCard(
              child: Text('No order data yet — sales will appear after your first orders.'),
            )
          else
            ...data.popularDishes.map(
              (dish) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ModernCard(
                  child: Row(
                    children: [
                      Expanded(child: Text(dish.dishName)),
                      Text('${dish.orderCount} sold'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ModernCard(
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

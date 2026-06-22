import 'package:flutter/material.dart';

import '../models/restaurant.dart';
import '../models/restaurant_dashboard.dart';
import '../services/restaurant_owner_service.dart';
import '../theme/app_colors.dart';
import '../utils/recommendation_copy.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'owner_dish_form_screen.dart';
import 'owner_dishes_screen.dart';
import 'restaurant_post_screen.dart';
import 'restaurant_register_screen.dart';

/// Restaurant owner dashboard — metrics and quick actions.
class RestaurantDashboardScreen extends StatefulWidget {
  const RestaurantDashboardScreen({super.key, this.restaurant});

  final Restaurant? restaurant;

  @override
  State<RestaurantDashboardScreen> createState() => _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState extends State<RestaurantDashboardScreen> {
  final _service = RestaurantOwnerService();

  List<Restaurant> _restaurants = [];
  Restaurant? _selected;
  RestaurantDashboard? _dashboard;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _restaurants = await _service.listMine();
      _selected = widget.restaurant ??
          (_restaurants.isNotEmpty ? _restaurants.first : null);
      if (_selected != null) {
        _dashboard = await _service.dashboard(_selected!.id);
      }
    } catch (e) {
      _error = RecommendationCopy.friendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectRestaurant(Restaurant restaurant) async {
    setState(() {
      _selected = restaurant;
      _loading = true;
    });
    try {
      _dashboard = await _service.dashboard(restaurant.id);
    } catch (e) {
      _error = RecommendationCopy.friendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.green;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: _restaurants.isEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RestaurantRegisterScreen()),
                );
                _load();
              },
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('Register restaurant'),
            )
          : null,
      body: _loading && _dashboard == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _error != null && _restaurants.isEmpty
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.gold,
                  child: ListView(
                    padding: const EdgeInsets.all(AppColors.screenPadding),
                    children: [
                      if (_restaurants.length > 1) ...[
                        DropdownButtonFormField<int>(
                          value: _selected?.id,
                          decoration: const InputDecoration(labelText: 'Restaurant'),
                          items: _restaurants
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r.id,
                                  child: Text(r.name),
                                ),
                              )
                              .toList(),
                          onChanged: (id) {
                            final match = _restaurants.where((r) => r.id == id).firstOrNull;
                            if (match != null) _selectRestaurant(match);
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_selected == null)
                        const EmptyState(
                          icon: Icons.storefront_outlined,
                          title: 'No restaurant yet',
                          subtitle: 'Register your restaurant to start managing dishes.',
                        )
                      else if (_dashboard != null) ...[
                        ModernCard(
                          borderColor: _statusColor(_dashboard!.approvalStatus)
                              .withValues(alpha: 0.45),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _dashboard!.restaurantName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Status: ${_dashboard!.approvalStatus.toUpperCase()}',
                                style: TextStyle(
                                  color: _statusColor(_dashboard!.approvalStatus),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_dashboard!.isPending)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Your restaurant is pending admin approval. Dishes will not appear publicly until approved.',
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Dishes',
                                value: '${_dashboard!.totalDishes}',
                                sub: '${_dashboard!.availableDishes} available',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatCard(
                                label: 'Rating',
                                value: _dashboard!.averageRating.toStringAsFixed(1),
                                sub: '${_dashboard!.totalReviews} reviews',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _StatCard(
                          label: 'Orders',
                          value: '${_dashboard!.totalOrders}',
                          sub: 'All time',
                        ),
                        const SizedBox(height: 16),
                        SectionHeader(
                          title: 'Popular dishes',
                          subtitle: _dashboard!.popularDishes.isEmpty
                              ? 'No order data yet'
                              : 'Based on order volume',
                        ),
                        ..._dashboard!.popularDishes.map(
                          (d) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ModernCard(
                              child: Row(
                                children: [
                                  Expanded(child: Text(d.dishName)),
                                  Text('${d.orderCount} orders'),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GoldActionButton(
                          label: 'Manage dishes',
                          icon: Icons.restaurant_menu,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OwnerDishesScreen(
                                restaurantId: _selected!.id,
                                restaurantName: _selected!.name,
                              ),
                            ),
                          ).then((_) => _load()),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OwnerDishFormScreen(
                                restaurantId: _selected!.id,
                              ),
                            ),
                          ).then((_) => _load()),
                          icon: const Icon(Icons.add),
                          label: const Text('Add new dish'),
                        ),
                        if (_selected!.approvalStatus == 'approved') ...[
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RestaurantPostScreen(
                                  restaurantId: _selected!.id,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.campaign_outlined),
                            label: const Text('Post promotion or announcement'),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
  });

  final String label;
  final String value;
  final String sub;

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
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(sub, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

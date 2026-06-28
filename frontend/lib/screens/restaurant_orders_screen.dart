import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/restaurant_owner_service.dart';
import '../theme/app_colors.dart';
import '../utils/price_formatter.dart';
import '../utils/recommendation_copy.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Restaurant order management — accept, reject, and update delivery status.
class RestaurantOrdersScreen extends StatefulWidget {
  const RestaurantOrdersScreen({super.key, required this.restaurantId});

  final int restaurantId;

  @override
  State<RestaurantOrdersScreen> createState() => _RestaurantOrdersScreenState();
}

class _RestaurantOrdersScreenState extends State<RestaurantOrdersScreen> {
  final _service = RestaurantOwnerService();
  List<Order> _orders = [];
  String _filter = 'all';
  bool _loading = true;
  String? _error;

  static const _filters = {
    'all': 'All',
    'pending': 'New',
    'confirmed': 'Accepted',
    'preparing': 'Preparing',
    'picked_up': 'Ready',
    'on_the_way': 'Out for delivery',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RestaurantOrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.restaurantId != widget.restaurantId) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await _service.listOrders(
        restaurantId: widget.restaurantId,
        status: _filter == 'all' ? null : _filter,
      );
      if (!mounted) return;
      setState(() {
        _orders = orders;
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

  Future<void> _updateStatus(Order order, String status) async {
    try {
      await _service.updateOrderStatus(
        order.id,
        status,
        riderName: status == 'on_the_way' ? 'Delivery Rider' : null,
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(RecommendationCopy.friendlyError(e))),
      );
    }
  }

  List<({String label, String status})> _actionsFor(Order order) {
    switch (order.status) {
      case 'pending':
        return [
          (label: 'Accept', status: 'confirmed'),
          (label: 'Reject', status: 'cancelled'),
        ];
      case 'confirmed':
        return [
          (label: 'Start preparing', status: 'preparing'),
          (label: 'Cancel', status: 'cancelled'),
        ];
      case 'preparing':
        return [
          (label: 'Mark ready', status: 'picked_up'),
          (label: 'Cancel', status: 'cancelled'),
        ];
      case 'picked_up':
        return [
          (label: 'Out for delivery', status: 'on_the_way'),
          (label: 'Cancel', status: 'cancelled'),
        ];
      case 'on_the_way':
        return [(label: 'Mark delivered', status: 'delivered')];
      default:
        return [];
    }
  }

  String _statusLabel(String status) => _filters[status] ?? status;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: _filters.entries.map((entry) {
              final selected = _filter == entry.key;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(entry.value),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _filter = entry.key);
                    _load();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : _error != null
                  ? Center(child: Text(_error!))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.accent,
                      child: _orders.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 80),
                                EmptyState(
                                  icon: Icons.receipt_long_outlined,
                                  title: 'No orders',
                                  subtitle: 'New customer orders will appear here.',
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(AppColors.screenPadding),
                              itemCount: _orders.length,
                              itemBuilder: (context, index) {
                                final order = _orders[index];
                                final actions = _actionsFor(order);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: ModernCard(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Order #${order.id}',
                                              style: Theme.of(context).textTheme.titleMedium,
                                            ),
                                            const Spacer(),
                                            Chip(
                                              label: Text(_statusLabel(order.status)),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(PriceFormatter.format(order.totalPrice)),
                                        Text(
                                          '${order.items.length} item(s) · ${order.deliveryAddress}',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                        if (actions.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: actions.map((action) {
                                              final destructive = action.status == 'cancelled';
                                              return FilledButton.tonal(
                                                onPressed: () =>
                                                    _updateStatus(order, action.status),
                                                style: destructive
                                                    ? FilledButton.styleFrom(
                                                        backgroundColor:
                                                            AppColors.error.withValues(alpha: 0.15),
                                                      )
                                                    : null,
                                                child: Text(action.label),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
        ),
      ],
    );
  }
}

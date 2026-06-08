import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/dish_service.dart';
import '../services/order_service.dart';
import '../theme/app_colors.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Single order from `GET /orders/{id}`.
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _orders = OrderService();
  final _dishes = DishService();

  Order? order;
  Map<int, String> dishNames = {};
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
      final o = await _orders.getById(widget.orderId);
      final names = <int, String>{};
      for (final item in o.items) {
        try {
          final dish = await _dishes.getById(item.dishId);
          names[item.dishId] = dish.name;
        } catch (_) {
          names[item.dishId] = 'Menu item';
        }
      }
      if (!mounted) return;
      setState(() {
        order = o;
        dishNames = names;
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

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    final local = dt.toLocal();
    final y = local.year;
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  String _dishLabel(int dishId) {
    final name = dishNames[dishId];
    if (name != null && name.isNotEmpty) return name;
    return 'Menu item';
  }

  @override
  Widget build(BuildContext context) {
    final o = order;

    return Scaffold(
      appBar: AppBar(title: Text(o != null ? 'Order #${o.id}' : 'Order')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppColors.screenPadding),
                    child: Text(error!, textAlign: TextAlign.center),
                  ),
                )
              : o == null
                  ? const Center(child: Text('Order not found'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.gold,
                      child: ListView(
                        padding: const EdgeInsets.all(AppColors.screenPadding),
                        children: [
                          ModernCard(
                            gradient: AppColors.headerGradient,
                            borderColor:
                                AppColors.gold.withValues(alpha: 0.35),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Order status',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    StatusBadge(status: o.status),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SummaryLine(
                                  label: 'Order number',
                                  value: '#${o.id}',
                                ),
                                SummaryLine(
                                  label: 'Payment',
                                  value: o.paymentStatus,
                                ),
                                SummaryLine(
                                  label: 'Placed',
                                  value: _formatDate(o.createdAt),
                                ),
                              ],
                            ),
                          ),
                          if (o.deliveryAddress.isNotEmpty) ...[
                            const SectionHeader(
                              title: 'Delivery information',
                            ),
                            ModernCard(
                              borderColor:
                                  AppColors.green.withValues(alpha: 0.35),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: AppColors.green,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      o.deliveryAddress,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (o.items.isNotEmpty) ...[
                            SectionHeader(
                              title: 'Items',
                              subtitle: '${o.items.length} dishes',
                            ),
                            ...o.items.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ModernCard(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppColors.green
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.lunch_dining,
                                          color: AppColors.green,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _dishLabel(item.dishId),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                            Text(
                                              'Qty ${item.quantity}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(color: AppColors.gold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          TotalAmountCard(
                            label: 'Total amount',
                            amount: '\$${o.totalPrice.toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
    );
  }
}

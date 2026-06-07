import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/order_service.dart';

/// Single order from `GET /orders/{id}`.
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _orders = OrderService();

  Order? order;
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
      if (!mounted) return;
      setState(() {
        order = o;
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
                    padding: const EdgeInsets.all(16),
                    child: Text(error!),
                  ),
                )
              : o == null
                  ? const Center(child: Text('Order not found'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Order number'),
                            trailing: Text('#${o.id}'),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Status'),
                            trailing: Text(o.status),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Total'),
                            trailing: Text('\$${o.totalPrice.toStringAsFixed(2)}'),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Created'),
                            trailing: Text(_formatDate(o.createdAt)),
                          ),
                          if (o.deliveryAddress.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Delivery address'),
                              subtitle: Text(o.deliveryAddress),
                            ),
                          ],
                          if (o.items.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Items (${o.items.length})',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            ...o.items.map(
                              (item) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text('Dish #${item.dishId}'),
                                subtitle: Text('Qty ${item.quantity}'),
                                trailing: Text(
                                  '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }
}

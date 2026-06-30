import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/recommendation_copy.dart';
import '../../../widgets/admin/admin_charts.dart';
import '../../../widgets/admin/admin_ui.dart';
import '../../../widgets/ui/app_ui_widgets.dart';
import '../admin_utils.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final _admin = AdminService();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  Map<String, dynamic>? _overview;
  String? _statusFilter;
  bool _loading = true;
  String? _error;

  static const _statuses = [
    ('Pending', 'pending'),
    ('Preparing', 'preparing'),
    ('Picked Up', 'picked_up'),
    ('Delivered', 'delivered'),
    ('Cancelled', 'cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _overview = await _admin.analyticsOverview();
      final page = await _admin.listOrders(
        page: 1,
        limit: 50,
        status: _statusFilter,
        search: _search.text.trim().isEmpty ? null : _search.text.trim(),
      );
      _items = page.items;
    } catch (e) {
      _error = RecommendationCopy.friendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showDetails(Map<String, dynamic> order) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Order #${order['id']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${order['user_name'] ?? order['user_email'] ?? '—'}'),
            Text('Restaurant: ${order['restaurant_name'] ?? '—'}'),
            Text('Status: ${order['status']}'),
            Text('Payment: ${order['payment_status'] ?? '—'}'),
            Text('Total: \$${order['total_price']}'),
            Text('Address: ${order['delivery_address'] ?? '—'}'),
            Text('Created: ${adminFormatDate(order['created_at']?.toString())}'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  Map<String, int> get _statusCounts {
    final raw = _overview?['order_status_counts'];
    if (raw is! Map) return {};
    return raw.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _items.isEmpty && _error == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    final counts = _statusCounts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AdminPageHeader(title: 'Orders', subtitle: 'Track and search platform orders'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search by customer, email, or restaurant',
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _load),
            ),
            onSubmitted: (_) => _load(),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _chip('All', null, counts.values.fold(0, (a, b) => a + b)),
              for (final s in _statuses) _chip(s.$1, s.$2, counts[s.$2] ?? 0),
            ],
          ),
        ),
        if (_error != null)
          Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: AppColors.error))),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            color: AppColors.accent,
            child: _items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 80),
                      EmptyState(icon: Icons.inbox_outlined, title: 'No orders found', subtitle: 'Try a different filter or search'),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final o = _items[i];
                      final status = o['status']?.toString() ?? 'pending';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ModernAdminCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.receipt_long, color: AppColors.accent, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text('Order #${o['id']}', style: Theme.of(context).textTheme.titleSmall),
                                        const SizedBox(width: 8),
                                        AdminStatusBadge(status: status),
                                      ],
                                    ),
                                    Text(
                                      '${o['user_name'] ?? o['user_email']} · ${o['restaurant_name'] ?? 'Restaurant'}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    Text(
                                      '\$${o['total_price']} · ${adminFormatDate(o['created_at']?.toString())}',
                                      style: Theme.of(context).textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(onPressed: () => _showDetails(o), child: const Text('Details')),
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

  Widget _chip(String label, String? status, int count) {
    final selected = _statusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$label ($count)', style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) {
          setState(() => _statusFilter = status);
          _load();
        },
        selectedColor: AppColors.accent.withValues(alpha: 0.2),
        checkmarkColor: AppColors.accent,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

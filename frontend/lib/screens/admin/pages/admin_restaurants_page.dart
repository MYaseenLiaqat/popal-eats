import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/recommendation_copy.dart';
import '../../../widgets/admin/admin_charts.dart';
import '../../../widgets/admin/admin_ui.dart';
import '../../../widgets/ui/app_ui_widgets.dart';
import '../admin_utils.dart';

class AdminRestaurantsPage extends StatefulWidget {
  const AdminRestaurantsPage({super.key});

  @override
  State<AdminRestaurantsPage> createState() => _AdminRestaurantsPageState();
}

class _AdminRestaurantsPageState extends State<AdminRestaurantsPage> {
  final _admin = AdminService();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  String _statusFilter = 'approved';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final page = await _admin.listRestaurants(
        page: 1,
        limit: 100,
        approvalStatus: _statusFilter == 'all' ? null : _statusFilter,
      );
      _items = page.items;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((r) {
      final name = r['name']?.toString().toLowerCase() ?? '';
      final city = r['city']?.toString().toLowerCase() ?? '';
      return name.contains(q) || city.contains(q);
    }).toList();
  }

  Future<void> _suspendOwner(Map<String, dynamic> restaurant) async {
    final ownerId = restaurant['owner_id'] as int?;
    if (ownerId == null) return;
    final ok = await adminConfirm(context, title: 'Suspend', message: 'Suspend this restaurant owner?');
    if (ok != true) return;
    try {
      await _admin.suspendBusinessAccount(ownerId, reason: 'Suspended by admin');
      if (!mounted) return;
      await adminShowSnack(context, 'Owner suspended');
      await _load();
    } catch (e) {
      if (!mounted) return;
      await adminShowSnack(context, RecommendationCopy.friendlyError(e), error: true);
    }
  }

  Future<void> _reactivateOwner(Map<String, dynamic> restaurant) async {
    final ownerId = restaurant['owner_id'] as int?;
    if (ownerId == null) return;
    try {
      await _admin.reactivateBusinessAccount(ownerId);
      if (!mounted) return;
      await adminShowSnack(context, 'Owner reactivated');
      await _load();
    } catch (e) {
      if (!mounted) return;
      await adminShowSnack(context, RecommendationCopy.friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AdminPageHeader(
          title: 'Restaurants',
          subtitle: 'Approved restaurants only — pending applications are in Business Approvals',
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search restaurants',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _statusFilter,
                items: const [
                  DropdownMenuItem(value: 'approved', child: Text('Approved')),
                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                  DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _statusFilter = v);
                  _load();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.accent,
                  child: _filtered.isEmpty
                      ? ListView(children: const [SizedBox(height: 80), EmptyState(icon: Icons.storefront_outlined, title: 'No restaurants', subtitle: '')])
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) {
                            final r = _filtered[i];
                            final status = r['approval_status']?.toString() ?? '—';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ModernAdminCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(r['name']?.toString() ?? 'Restaurant', style: Theme.of(context).textTheme.titleSmall),
                                        ),
                                        Chip(label: Text(status), visualDensity: VisualDensity.compact),
                                      ],
                                    ),
                                    Text('${r['city'] ?? ''} · ${r['address'] ?? ''}', style: Theme.of(context).textTheme.bodySmall),
                                    Text('Rating ${r['average_rating'] ?? '—'} · ${r['total_reviews'] ?? 0} reviews', style: Theme.of(context).textTheme.bodySmall),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        if (status == 'approved')
                                          TextButton(onPressed: () => _suspendOwner(r), child: const Text('Suspend')),
                                        if (status == 'rejected')
                                          TextButton(onPressed: () => _reactivateOwner(r), child: const Text('Reactivate')),
                                      ],
                                    ),
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

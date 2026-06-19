import 'package:flutter/material.dart';

import '../services/admin_service.dart';
import '../theme/app_colors.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'admin_restaurant_approvals_screen.dart';

/// Admin analytics dashboard (admin role required).
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _admin = AdminService();
  Map<String, dynamic>? stats;
  int _pendingRestaurants = 0;
  String? error;
  bool loading = true;

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
      stats = await _admin.analyticsOverview();
      final pending = await _admin.pendingRestaurantCount();
      _pendingRestaurants = pending['pending_count'] as int? ?? 0;
    } catch (e) {
      error = e.toString();
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : error != null
              ? Center(child: Text(error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.gold,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_pendingRestaurants > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ModernCard(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminRestaurantApprovalsScreen(),
                              ),
                            ).then((_) => _load()),
                            borderColor: AppColors.gold.withValues(alpha: 0.5),
                            child: Row(
                              children: [
                                const Icon(Icons.pending_actions, color: AppColors.gold),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '$_pendingRestaurants restaurant(s) awaiting approval',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ),
                      _tile('Users', stats?['users']),
                      _tile('Restaurants', stats?['restaurants']),
                      _tile('Dishes', stats?['dishes']),
                      _tile('Reviews', stats?['reviews']),
                      _tile('Pending AI', stats?['reviews_pending_processing']),
                      _tile('Failed AI', stats?['reviews_failed_processing']),
                      _tile('Menu uploads', stats?['menu_uploads']),
                    ],
                  ),
                ),
    );
  }

  Widget _tile(String label, dynamic value) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text('$value', style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

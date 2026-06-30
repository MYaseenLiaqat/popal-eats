import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/recommendation_copy.dart';
import '../../../widgets/admin/admin_charts.dart';
import '../../../widgets/admin/admin_ui.dart';
import '../../../widgets/ui/app_ui_widgets.dart';
import '../admin_utils.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  final _admin = AdminService();
  Map<String, dynamic>? _platform;
  List<Map<String, dynamic>> _failedReviews = [];
  List<Map<String, dynamic>> _pendingAccounts = [];
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
      _platform = await _admin.analyticsOverview();
      final reviews = await _admin.listReviews(processingStatus: 'failed', page: 1, limit: 20);
      _failedReviews = reviews.items;
      _pendingAccounts = await _admin.listPendingBusinessAccounts();
    } catch (e) {
      _error = RecommendationCopy.friendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _dismissReview(int id) async {
    final ok = await adminConfirm(context, title: 'Dismiss report', message: 'Delete this failed review?');
    if (ok != true) return;
    try {
      await _admin.deleteReview(id);
      if (!mounted) return;
      await adminShowSnack(context, 'Report dismissed');
      await _load();
    } catch (e) {
      if (!mounted) return;
      await adminShowSnack(context, RecommendationCopy.friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    if (_error != null) {
      return Center(child: EmptyState(icon: Icons.error_outline, title: 'Reports unavailable', subtitle: _error));
    }

    final kpis = _platform?['kpis'] as Map<String, dynamic>? ?? {};

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.accent,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AdminPageHeader(title: 'Reports center', subtitle: 'Failed reviews and pending business registrations'),
          ModernAdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Platform snapshot', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _line('Total users', kpis['total_users']),
                _line('Restaurants', kpis['restaurants']),
                _line('Dishes', kpis['total_dishes']),
                _line('Reviews', kpis['total_reviews']),
                _line('Pending reviews (AI)', kpis['pending_reviews']),
                _line('Failed reviews (reports)', kpis['pending_reports']),
                _line('Pending business accounts', _pendingAccounts.length),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Review reports (failed AI processing)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_failedReviews.isEmpty)
            const EmptyState(icon: Icons.check_circle_outline, title: 'No open reports', subtitle: 'Failed review queue is empty')
          else
            ..._failedReviews.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ModernAdminCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${r['author_name'] ?? 'User'} · ${r['rating']}★', style: Theme.of(context).textTheme.titleSmall),
                      if (r['comment'] != null)
                        Text(r['comment'].toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(onPressed: () => _dismissReview(r['id'] as int), child: const Text('Dismiss')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text('Business registration reports', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_pendingAccounts.isEmpty)
            Text('No pending registrations', style: Theme.of(context).textTheme.bodySmall)
          else
            ..._pendingAccounts.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ModernAdminCard(
                  child: Text('${adminAccountTitle(a)} · ${a['role']} · ${a['email']}'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _line(String label, Object? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text('${value ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

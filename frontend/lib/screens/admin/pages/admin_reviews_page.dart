import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/recommendation_copy.dart';
import '../../../widgets/admin/admin_charts.dart';
import '../admin_utils.dart';

class AdminReviewsPage extends StatefulWidget {
  const AdminReviewsPage({super.key});

  @override
  State<AdminReviewsPage> createState() => _AdminReviewsPageState();
}

class _AdminReviewsPageState extends State<AdminReviewsPage> {
  final _admin = AdminService();
  List<Map<String, dynamic>> _items = [];
  String? _statusFilter;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final page = await _admin.listReviews(processingStatus: _statusFilter, page: 1, limit: 50);
      _items = page.items;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reprocess(int id) async {
    try {
      await _admin.reprocessReview(id);
      if (!mounted) return;
      await adminShowSnack(context, 'Review reprocessed');
      await _load();
    } catch (e) {
      if (!mounted) return;
      await adminShowSnack(context, RecommendationCopy.friendlyError(e), error: true);
    }
  }

  Future<void> _delete(int id) async {
    final ok = await adminConfirm(context, title: 'Delete review', message: 'Remove this review permanently?');
    if (ok != true) return;
    try {
      await _admin.deleteReview(id);
      if (!mounted) return;
      await adminShowSnack(context, 'Review deleted');
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
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Filter:'),
              const SizedBox(width: 8),
              DropdownButton<String?>(
                value: _statusFilter,
                hint: const Text('All'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending AI')),
                  DropdownMenuItem(value: 'failed', child: Text('Failed AI')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                ],
                onChanged: (v) {
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
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final r = _items[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ModernAdminCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text('${r['author_name'] ?? 'User'} · ${r['rating']}★')),
                                  Chip(label: Text(r['processing_status']?.toString() ?? '—'), visualDensity: VisualDensity.compact),
                                ],
                              ),
                              if (r['comment'] != null) Text(r['comment'].toString(), maxLines: 3, overflow: TextOverflow.ellipsis),
                              if (r['sentiment'] != null) Text('Sentiment: ${r['sentiment']}', style: Theme.of(context).textTheme.bodySmall),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (r['processing_status'] == 'failed')
                                      TextButton(onPressed: () => _reprocess(r['id'] as int), child: const Text('Reprocess')),
                                    TextButton(
                                      onPressed: () => _delete(r['id'] as int),
                                      child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                                    ),
                                  ],
                                ),
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

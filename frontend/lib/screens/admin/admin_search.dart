import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/recommendation_copy.dart';
import 'admin_utils.dart';

Future<void> showAdminGlobalSearch(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => const _AdminSearchDialog(),
  );
}

class _AdminSearchDialog extends StatefulWidget {
  const _AdminSearchDialog();

  @override
  State<_AdminSearchDialog> createState() => _AdminSearchDialogState();
}

class _AdminSearchDialogState extends State<_AdminSearchDialog> {
  final _admin = AdminService();
  final _query = TextEditingController();
  Map<String, dynamic>? _results;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _query.text.trim();
    if (q.length < 2) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _results = await _admin.globalSearch(q);
    } catch (e) {
      _error = RecommendationCopy.friendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Global search'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _query,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search users, restaurants, orders, posts, reviews…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) {
                if (_query.text.trim().length >= 2) _search();
              },
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(color: AppColors.accent),
            if (_error != null) Text(_error!, style: const TextStyle(color: AppColors.error)),
            if (_results != null) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: SingleChildScrollView(child: _buildResults(_results!)),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }

  Widget _buildResults(Map<String, dynamic> data) {
    final sections = <String, List<dynamic>>{
      'Users': data['users'] as List? ?? [],
      'Restaurants': data['restaurants'] as List? ?? [],
      'Orders': data['orders'] as List? ?? [],
      'Posts': data['posts'] as List? ?? [],
      'Reviews': data['reviews'] as List? ?? [],
    };
    final hasAny = sections.values.any((l) => l.isNotEmpty);
    if (!hasAny) return const Text('No results');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.entries.where((e) => e.value.isNotEmpty).map((section) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(section.key, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accent)),
            const SizedBox(height: 4),
            ...section.value.whereType<Map>().map((item) {
              final label = item['full_name'] ??
                  item['name'] ??
                  item['title'] ??
                  item['body'] ??
                  '#${item['id']}';
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(label.toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(item['email']?.toString() ?? item['status']?.toString() ?? item['post_type']?.toString() ?? ''),
              );
            }),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }
}

IconData _notificationIcon(String? type) {
  switch (type) {
    case 'business_registration':
      return Icons.storefront_outlined;
    case 'review_failed':
      return Icons.flag_outlined;
    case 'recommendation_idle':
      return Icons.warning_amber_outlined;
    default:
      return Icons.notifications_outlined;
  }
}

String _notificationCategory(String? type) {
  switch (type) {
    case 'business_registration':
      return 'New registration';
    case 'review_failed':
      return 'New report';
    case 'recommendation_idle':
      return 'System alert';
    default:
      return 'Alert';
  }
}

Future<void> showAdminNotifications(BuildContext context) async {
  final admin = AdminService();
  List<Map<String, dynamic>> items = [];
  try {
    items = await admin.listNotifications(limit: 20);
  } catch (_) {}

  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Notifications'),
      content: SizedBox(
        width: 440,
        child: items.isEmpty
            ? const Text('No notifications')
            : SingleChildScrollView(
                child: Column(
                  children: items
                      .map(
                        (n) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(_notificationIcon(n['type']?.toString()), color: AppColors.accent, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _notificationCategory(n['type']?.toString()),
                                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                    ),
                                    Text(n['title']?.toString() ?? 'Notification', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text(n['subtitle']?.toString() ?? '', style: Theme.of(ctx).textTheme.bodySmall),
                                  ],
                                ),
                              ),
                              Text(
                                adminFormatDate(n['created_at']?.toString()),
                                style: Theme.of(ctx).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
    ),
  );
}

import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/recommendation_copy.dart';
import '../../../widgets/admin/admin_charts.dart';
import '../../../widgets/admin/admin_ui.dart';
import '../../../widgets/ui/app_ui_widgets.dart';
import '../admin_utils.dart';

class AdminContentPage extends StatefulWidget {
  const AdminContentPage({super.key});

  @override
  State<AdminContentPage> createState() => _AdminContentPageState();
}

class _AdminContentPageState extends State<AdminContentPage> with SingleTickerProviderStateMixin {
  final _admin = AdminService();
  final _search = TextEditingController();
  late final TabController _tabs;
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];
  String? _error;

  static const _tabTypes = [
    ('Posts', 'food_posts'),
    ('Stories', 'stories'),
    ('Reels', 'reels'),
    ('Recipes', 'recipes'),
    ('Restaurant Posts', 'restaurant_posts'),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _tabTypes.length, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) _load();
    });
    _search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  String get _currentType => _tabTypes[_tabs.index].$2;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_currentType == 'stories') {
        final page = await _admin.listContentStories(page: 1, limit: 50);
        _items = page.items;
      } else {
        final page = await _admin.listContentPosts(contentType: _currentType, page: 1, limit: 50);
        _items = page.items;
      }
    } catch (e) {
      _error = RecommendationCopy.friendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((item) {
      final author = item['author_name']?.toString().toLowerCase() ?? '';
      final caption = item['caption']?.toString().toLowerCase() ?? '';
      final title = item['title']?.toString().toLowerCase() ?? '';
      return author.contains(q) || caption.contains(q) || title.contains(q);
    }).toList();
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final ok = await adminConfirm(context, title: 'Delete content', message: 'Remove this content permanently?');
    if (ok != true) return;
    final id = item['id'] as int;
    setState(() => _items.removeWhere((i) => i['id'] == id));
    try {
      await _admin.deleteContentPost(id);
      if (!mounted) return;
      await adminShowSnack(context, 'Content deleted');
    } catch (e) {
      if (!mounted) return;
      await _load();
      await adminShowSnack(context, RecommendationCopy.friendlyError(e), error: true);
    }
  }

  void _viewFull(Map<String, dynamic> item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item['title']?.toString() ?? 'Content #${item['id']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Author: ${item['author_name'] ?? item['author_username'] ?? '—'}'),
              Text('Type: ${item['post_type'] ?? 'story'}'),
              Text('Date: ${adminFormatDate(item['created_at']?.toString())}'),
              Text('Reports: ${item['reports_count'] ?? 0}'),
              const SizedBox(height: 8),
              Text(item['caption']?.toString() ?? item['title']?.toString() ?? '—'),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AdminPageHeader(title: 'Content moderation', subtitle: 'Review and remove platform content'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search by author or caption',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        TabBar(
          controller: _tabs,
          isScrollable: true,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent,
          tabs: _tabTypes.map((t) => Tab(text: t.$1)).toList(),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : _error != null
                  ? Center(child: EmptyState(icon: Icons.error_outline, title: 'Content unavailable', subtitle: _error))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.accent,
                      child: _filtered.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 80),
                                EmptyState(icon: Icons.inbox_outlined, title: 'No content', subtitle: 'Nothing to moderate in this category'),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filtered.length,
                              itemBuilder: (context, i) {
                                final item = _filtered[i];
                                final images = item['images'];
                                final imageUrl = item['image_url']?.toString() ??
                                    (images is List && images.isNotEmpty ? images.first.toString() : null);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: ModernAdminCard(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: imageUrl != null
                                              ? Image.network(
                                                  imageUrl,
                                                  width: 52,
                                                  height: 52,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => _previewPlaceholder(),
                                                )
                                              : _previewPlaceholder(),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['title']?.toString() ?? item['caption']?.toString() ?? 'Content #${item['id']}',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context).textTheme.titleSmall,
                                              ),
                                              Text(item['author_name']?.toString() ?? 'Unknown', style: Theme.of(context).textTheme.bodySmall),
                                              Text(adminFormatDate(item['created_at']?.toString()), style: Theme.of(context).textTheme.labelSmall),
                                              if ((item['reports_count'] as int? ?? 0) > 0)
                                                Text('${item['reports_count']} report(s)', style: const TextStyle(fontSize: 11, color: AppColors.error)),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            TextButton(onPressed: () => _viewFull(item), child: const Text('View')),
                                            TextButton(
                                              onPressed: () => _delete(item),
                                              child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                                            ),
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

  Widget _previewPlaceholder() {
    return Container(
      width: 52,
      height: 52,
      color: AppColors.surfaceLight,
      child: const Icon(Icons.image_outlined, color: AppColors.textSecondary),
    );
  }
}

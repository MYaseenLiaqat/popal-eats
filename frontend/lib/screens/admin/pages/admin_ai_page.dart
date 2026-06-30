import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/recommendation_copy.dart';
import '../../../widgets/admin/admin_charts.dart';
import '../../../widgets/admin/admin_ui.dart';
import '../../../widgets/ui/app_ui_widgets.dart';

class AdminAiPage extends StatefulWidget {
  const AdminAiPage({super.key});

  @override
  State<AdminAiPage> createState() => _AdminAiPageState();
}

class _AdminAiPageState extends State<AdminAiPage> {
  final _admin = AdminService();
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;

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
      _data = await _admin.recommendationMetrics();
    } catch (e) {
      _error = RecommendationCopy.friendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MapEntry<String, dynamic>> _flattenDebug(Map<String, dynamic> debug) {
    final entries = <MapEntry<String, dynamic>>[];
    void walk(String prefix, dynamic value) {
      if (value is Map) {
        value.forEach((k, v) => walk(prefix.isEmpty ? k.toString() : '$prefix.$k', v));
      } else if (value is List) {
        entries.add(MapEntry(prefix, '${value.length} items'));
      } else {
        entries.add(MapEntry(prefix, value));
      }
    }
    walk('', debug);
    return entries.take(12).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    if (_error != null) {
      return Center(child: EmptyState(icon: Icons.error_outline, title: 'AI metrics unavailable', subtitle: _error));
    }

    final rec = _data?['recommendations'] as Map<String, dynamic>? ?? {};
    final top = _data?['top_entities'] as Map<String, dynamic>? ?? {};
    final debug = _data?['debug'] as Map<String, dynamic>? ?? {};
    final logs = _flattenDebug(debug);

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.accent,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AdminPageHeader(
            title: 'AI recommendation dashboard',
            subtitle: 'Hybrid engine performance and catalog health',
          ),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth >= 900 ? 3 : c.maxWidth >= 600 ? 2 : 1;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: [
                  AdminKpiCard(
                    label: 'Recommendation Requests',
                    value: formatMetricOrEmpty(rec['total_requests']),
                    icon: Icons.psychology_outlined,
                    description: 'Total hybrid engine calls',
                    trend: rec['requests_7d'] != null ? '${rec['requests_7d']} this week' : null,
                  ),
                  AdminKpiCard(
                    label: 'Top Recommended Cuisine',
                    value: formatMetricOrEmpty(top['cuisine']),
                    icon: Icons.restaurant,
                    description: 'Most surfaced cuisine',
                  ),
                  AdminKpiCard(
                    label: 'Top Recommended Dish',
                    value: formatMetricOrEmpty(top['ai_recommended_dish'] ?? top['dish']),
                    icon: Icons.ramen_dining,
                    description: 'Highest click-through dish',
                  ),
                  AdminKpiCard(
                    label: 'Top Recommended Restaurant',
                    value: formatMetricOrEmpty(top['restaurant']),
                    icon: Icons.store,
                    description: 'Highest rated listing',
                  ),
                  AdminKpiCard(
                    label: 'Average Response Time',
                    value: 'No data available',
                    icon: Icons.timer_outlined,
                    description: 'Engine latency tracking',
                  ),
                  AdminKpiCard(
                    label: 'Recommendation Queue',
                    value: rec['requests_7d'] != null ? '${rec['requests_7d']}' : 'No data available',
                    icon: Icons.queue_outlined,
                    description: 'Requests in last 7 days',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          if (rec['impressions'] != null && (rec['impressions'] as num) > 0)
            AdminProgressMetric(
              label: 'Recommendation success rate',
              value: (rec['clicks'] as num?)?.toDouble() ?? 0,
              max: (rec['impressions'] as num?)?.toDouble() ?? 1,
              subtitle: rec['success_rate_percent'] != null ? '${rec['success_rate_percent']}% CTR' : 'Click-through rate',
            ),
          const SizedBox(height: 16),
          Text('Latest recommendation logs', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ModernAdminCard(
            child: logs.isEmpty
                ? Text('No data available', style: Theme.of(context).textTheme.bodySmall)
                : Column(
                    children: logs
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.bolt, size: 14, color: AppColors.accent),
                                const SizedBox(width: 8),
                                Expanded(child: Text(e.key, style: Theme.of(context).textTheme.bodySmall)),
                                Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

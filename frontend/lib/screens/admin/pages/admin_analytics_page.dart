import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/recommendation_copy.dart';
import '../../../widgets/admin/admin_charts.dart';
import '../../../widgets/admin/admin_ui.dart';
import '../../../widgets/ui/app_ui_widgets.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  final _admin = AdminService();
  AdminAnalyticsData? _data;
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
      _data = await _admin.loadAnalyticsData();
    } catch (e) {
      _error = RecommendationCopy.friendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _chartRow(List<Widget> charts, double maxWidth) {
    if (maxWidth < 700) {
      return Column(children: [for (final c in charts) ...[c, const SizedBox(height: 10)]]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < charts.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: charts[i]),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    if (_error != null) {
      return Center(child: EmptyState(icon: Icons.error_outline, title: 'Analytics unavailable', subtitle: _error));
    }

    final d = _data!;
    final ts = d.platform['timeseries'] as Map<String, dynamic>? ?? {};
    final rec = d.platform['recommendations'] as Map<String, dynamic>? ?? {};
    final cuisineEntries = d.cuisineCounts.entries.map((e) => (label: e.key, value: e.value)).toList();
    final sentiment = d.platform['sentiment_breakdown'] as List? ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.accent,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AdminPageHeader(title: 'Platform analytics', subtitle: 'Growth, orders, content, and recommendations'),
          AdminChartSection(
            title: 'Platform growth',
            child: LayoutBuilder(
              builder: (context, c) => _chartRow([
                AdminLineChart(title: 'New users (7d)', points: dailySeriesCounts(ts, 'new_users'), compact: true),
                AdminLineChart(title: 'Posts (7d)', points: dailySeriesCounts(ts, 'posts'), compact: true),
              ], c.maxWidth),
            ),
          ),
          const SizedBox(height: 12),
          AdminChartSection(
            title: 'Orders',
            child: LayoutBuilder(
              builder: (context, c) => _chartRow([
                AdminLineChart(title: 'Orders per day', points: dailySeriesCounts(ts, 'orders'), compact: true),
                AdminPieChart(
                  title: 'Order status',
                  segments: _orderSegments(d.platform['order_status_counts']),
                ),
              ], c.maxWidth),
            ),
          ),
          const SizedBox(height: 12),
          AdminChartSection(
            title: 'Content',
            child: LayoutBuilder(
              builder: (context, c) => _chartRow([
                AdminLineChart(title: 'Stories', points: dailySeriesCounts(ts, 'stories'), compact: true),
                AdminLineChart(title: 'Reels', points: dailySeriesCounts(ts, 'reels'), compact: true),
              ], c.maxWidth),
            ),
          ),
          const SizedBox(height: 12),
          AdminChartSection(
            title: 'Recommendations',
            child: Row(
              children: [
                Expanded(
                  child: AdminKpiCard(
                    label: 'Total requests',
                    value: formatMetricOrEmpty(rec['total_requests']),
                    icon: Icons.psychology_outlined,
                    description: 'All-time engine calls',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AdminKpiCard(
                    label: 'Success rate',
                    value: rec['success_rate_percent'] != null ? '${rec['success_rate_percent']}%' : 'No data available',
                    icon: Icons.trending_up,
                    description: 'Click-through on impressions',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AdminChartSection(
            title: 'Users & sentiment',
            child: LayoutBuilder(
              builder: (context, c) => _chartRow([
                AdminBarChart(title: 'Cuisine distribution', entries: cuisineEntries, maxBars: 5),
                AdminBarChart(
                  title: 'Review sentiment',
                  entries: sentiment
                      .whereType<Map>()
                      .map((s) => (label: s['sentiment']?.toString() ?? '?', value: s['count'] as int? ?? 0))
                      .toList(),
                  maxBars: 5,
                ),
              ], c.maxWidth),
            ),
          ),
          const SizedBox(height: 12),
          Text('Top restaurants', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (d.topRestaurants.isEmpty)
            Text('No data available', style: Theme.of(context).textTheme.bodySmall)
          else
            ...d.topRestaurants.take(5).map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: ModernAdminCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(child: Text(r['name']?.toString() ?? 'Restaurant')),
                      Text('${r['average_rating'] ?? '—'}★', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Text('${r['total_reviews'] ?? 0} reviews', style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<({String label, int value, Color color})> _orderSegments(Object? raw) {
    if (raw is! Map) return [];
    final colors = [AppColors.accent, Colors.orange, Colors.blue, Colors.green, Colors.red];
    var i = 0;
    return raw.entries
        .map((e) {
          final color = colors[i % colors.length];
          i++;
          return (label: e.key.toString(), value: (e.value as num?)?.toInt() ?? 0, color: color);
        })
        .where((s) => s.value > 0)
        .toList();
  }
}

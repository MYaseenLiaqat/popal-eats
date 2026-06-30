import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Simple horizontal bar chart for admin analytics.
class AdminBarChart extends StatelessWidget {
  const AdminBarChart({
    super.key,
    required this.title,
    required this.entries,
    this.maxBars = 6,
  });

  final String title;
  final List<({String label, int value})> entries;
  final int maxBars;

  @override
  Widget build(BuildContext context) {
    final sorted = [...entries]..sort((a, b) => b.value.compareTo(a.value));
    final shown = sorted.take(maxBars).toList();
    final maxVal = shown.isEmpty ? 1 : shown.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return ModernAdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 16),
          if (shown.isEmpty)
            Text('No data yet', style: Theme.of(context).textTheme.bodySmall)
          else
            ...shown.map((e) {
              final fraction = e.value / maxVal;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(e.label, style: Theme.of(context).textTheme.bodySmall)),
                        Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceLight,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// Sparkline-style line chart from daily counts.
class AdminLineChart extends StatelessWidget {
  const AdminLineChart({
    super.key,
    required this.title,
    required this.points,
    this.compact = false,
  });

  final String title;
  final List<int> points;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasData = points.isNotEmpty && points.any((p) => p > 0);
    return ModernAdminCard(
      padding: compact ? const EdgeInsets.all(12) : const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (!hasData)
            Text('No data available', style: Theme.of(context).textTheme.bodySmall)
          else
            SizedBox(
              height: compact ? 72 : 100,
              width: double.infinity,
              child: CustomPaint(
                painter: _LineChartPainter(points: points),
              ),
            ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({required this.points});

  final List<int> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final max = points.reduce((a, b) => a > b ? a : b).clamp(1, 999999);
    final stepX = size.width / (points.length - 1).clamp(1, 99);

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height - (points[i] / max) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height - (points[i] / max) * size.height;
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = AppColors.accent);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => oldDelegate.points != points;
}

class ModernAdminCard extends StatelessWidget {
  const ModernAdminCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class AdminMetricCard extends StatelessWidget {
  const AdminMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
    this.subtitle,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? accent;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.accent;
    final card = ModernAdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: value.length > 12 ? 16 : null,
                ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: Theme.of(context).textTheme.labelSmall),
          ],
        ],
      ),
    );
    if (onTap == null) return card;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppColors.cardRadius), child: card);
  }
}

List<int> monthlyRegistrationCounts(List<Map<String, dynamic>> items) {
  final now = DateTime.now();
  final counts = List<int>.filled(6, 0);
  for (final item in items) {
    final raw = item['created_at']?.toString();
    if (raw == null) continue;
    final dt = DateTime.tryParse(raw);
    if (dt == null) continue;
    final monthsAgo = (now.year - dt.year) * 12 + now.month - dt.month;
    if (monthsAgo >= 0 && monthsAgo < 6) {
      counts[5 - monthsAgo]++;
    }
  }
  return counts;
}

List<int> dailySeriesCounts(Map<String, dynamic> timeseries, String key) {
  final raw = timeseries[key];
  if (raw is! List) return [];
  return raw
      .map((e) => e is Map ? (e['count'] as num?)?.toInt() ?? 0 : 0)
      .toList();
}

String formatMetricOrEmpty(Object? value, {String suffix = ''}) {
  if (value == null) return 'No data available';
  if (value is num) return '$value$suffix';
  final text = value.toString();
  if (text.isEmpty) return 'No data available';
  return '$text$suffix';
}

/// Donut-style pie chart from labeled segments.
class AdminPieChart extends StatelessWidget {
  const AdminPieChart({
    super.key,
    required this.title,
    required this.segments,
  });

  final String title;
  final List<({String label, int value, Color color})> segments;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<int>(0, (sum, s) => sum + s.value);
    return ModernAdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 16),
          if (total == 0)
            Text('No data available', style: Theme.of(context).textTheme.bodySmall)
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(
                children: [
                  for (final s in segments)
                    if (s.value > 0)
                      Expanded(
                        flex: s.value,
                        child: Container(height: 12, color: s.color),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...segments.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s.label, style: Theme.of(context).textTheme.bodySmall)),
                    Text('${s.value}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AdminProgressMetric extends StatelessWidget {
  const AdminProgressMetric({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    this.subtitle,
  });

  final String label;
  final double value;
  final double max;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final fraction = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return ModernAdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 10,
              backgroundColor: AppColors.surfaceLight,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 6),
          Text('${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)} / ${max.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

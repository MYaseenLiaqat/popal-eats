import 'package:flutter/material.dart';

import '../../services/health_nutrition_service.dart';
import '../../theme/app_colors.dart';

enum NutritionMetric { calories, protein, healthScore }

/// Single-metric trend chart for the nutrition dashboard.
class NutritionTrendChart extends StatelessWidget {
  const NutritionTrendChart({
    super.key,
    required this.points,
    this.metric = NutritionMetric.calories,
  });

  final List<DailyNutritionPoint> points;
  final NutritionMetric metric;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'Track meals on at least two different days to see trends',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: CustomPaint(
        painter: _NutritionTrendPainter(points: points, metric: metric),
        child: Padding(
          padding: const EdgeInsets.only(top: 8, left: 4, right: 4, bottom: 20),
          child: Row(
            children: points
                .map(
                  (p) => Expanded(
                    child: Text(
                      _label(p.date, points.length),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  String _label(DateTime date, int count) {
    if (count <= 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    }
    return '${date.month}/${date.day}';
  }
}

class _NutritionTrendPainter extends CustomPainter {
  _NutritionTrendPainter({required this.points, required this.metric});

  final List<DailyNutritionPoint> points;
  final NutritionMetric metric;

  double _value(DailyNutritionPoint p) {
    switch (metric) {
      case NutritionMetric.calories:
        return p.calories.toDouble();
      case NutritionMetric.protein:
        return p.protein;
      case NutritionMetric.healthScore:
        return p.healthScore.toDouble();
    }
  }

  Color get _color {
    switch (metric) {
      case NutritionMetric.calories:
        return AppColors.accent;
      case NutritionMetric.protein:
        return Colors.lightBlueAccent;
      case NutritionMetric.healthScore:
        return Colors.greenAccent;
    }
  }

  double _maxValue() {
    final values = points.map(_value);
    final peak = values.fold<double>(0, (a, b) => a > b ? a : b);
    switch (metric) {
      case NutritionMetric.calories:
        return peak.clamp(1, HealthNutritionService.defaultCalorieGoal * 2).toDouble();
      case NutritionMetric.protein:
        return peak.clamp(1, HealthNutritionService.defaultProteinGoal * 2);
      case NutritionMetric.healthScore:
        return 100;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final chartHeight = size.height - 24;
    final chartWidth = size.width;
    final stepX = chartWidth / (points.length - 1);
    final maxValue = _maxValue();

    final paint = Paint()
      ..color = _color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = chartHeight - (_value(points[i]) / maxValue) * (chartHeight - 8);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _NutritionTrendPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.metric != metric;
}

/// Compact bar chart for profile embed — tap opens full health dashboard.
class CompactNutritionBarChart extends StatelessWidget {
  const CompactNutritionBarChart({
    super.key,
    required this.points,
    this.height = 96,
    this.onTap,
  });

  final List<DailyNutritionPoint> points;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final active = points.where((p) => p.calories > 0).toList();
    if (active.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Order meals to see your weekly chart',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final maxCal = active
        .map((p) => p.calories)
        .fold<int>(0, (a, b) => a > b ? a : b)
        .clamp(1, HealthNutritionService.defaultCalorieGoal * 2);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: points.map((p) {
            final fraction = p.calories / maxCal;
            const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
            final label = days[p.date.weekday - 1];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (p.calories > 0)
                      Text(
                        '${p.calories}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              color: AppColors.accent,
                            ),
                      ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: fraction.clamp(0.05, 1.0),
                          widthFactor: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: p.calories > 0
                                  ? AppColors.accent.withValues(alpha: 0.85)
                                  : AppColors.surfaceLight.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

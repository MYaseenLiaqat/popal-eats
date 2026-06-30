import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../services/health_nutrition_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/health/nutrition_trend_chart.dart';
import '../../widgets/ui/app_ui_widgets.dart';
import '../../screens/health_dashboard_screen.dart';

/// Embedded glass-style health analytics for the profile tab.
class ProfileHealthDashboardCard extends StatefulWidget {
  const ProfileHealthDashboardCard({super.key});

  @override
  State<ProfileHealthDashboardCard> createState() => _ProfileHealthDashboardCardState();
}

class _ProfileHealthDashboardCardState extends State<ProfileHealthDashboardCard>
    with SingleTickerProviderStateMixin {
  final _service = HealthNutritionService();
  late final AnimationController _anim;
  HealthNutritionSummary? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _load();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await _service.load(days: 7);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    void openDetails() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HealthDashboardScreen()),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: openDetails,
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.18),
                    AppColors.surface.withValues(alpha: 0.92),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
              ),
              padding: const EdgeInsets.all(16),
              child: _buildContent(context, openDetails),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, VoidCallback openDetails) {
    if (_loading) {
      return SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }
    if (_error != null) {
      return Column(
        children: [
          const EmptyState(
            icon: Icons.monitor_heart_outlined,
            title: 'Health data unavailable',
            subtitle: 'Pull to refresh your profile',
          ),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ],
      );
    }

    final summary = _summary!;
    if (!summary.hasData) {
      return const EmptyState(
        icon: Icons.restaurant_outlined,
        title: 'No nutrition data yet',
        subtitle: 'Order dishes with nutrition info to track your health.',
      );
    }

    final calorieGoal = HealthNutritionService.defaultCalorieGoal;
    final proteinGoal = HealthNutritionService.defaultProteinGoal;
    final carbsGoal = HealthNutritionService.defaultCarbsGoal;
    final calorieProgress = (summary.totalCalories / calorieGoal).clamp(0.0, 1.0);
    final proteinProgress = (summary.totalProtein / proteinGoal).clamp(0.0, 1.0);
    final carbsProgress = (summary.totalCarbs / carbsGoal).clamp(0.0, 1.0);
    final score = summary.avgHealthScore.clamp(0, 100);
    final activeDays = summary.points.where((p) => p.calories > 0).length;

    return FadeTransition(
      opacity: CurvedAnimation(parent: _anim, curve: Curves.easeOut),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Health Dashboard',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              TextButton(
                onPressed: openDetails,
                child: const Text('Details'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HealthScoreGauge(score: score, animation: _anim),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _MetricBar(
                      label: 'Calories',
                      value: '${summary.totalCalories}',
                      progress: calorieProgress,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 8),
                    _MetricBar(
                      label: 'Protein',
                      value: '${summary.totalProtein.toStringAsFixed(0)}g',
                      progress: proteinProgress,
                      color: AppColors.chartProtein,
                    ),
                    const SizedBox(height: 8),
                    _MetricBar(
                      label: 'Carbs',
                      value: '${summary.totalCarbs.toStringAsFixed(0)}g',
                      progress: carbsProgress,
                      color: AppColors.chartCarbs,
                    ),
                    const SizedBox(height: 8),
                    _MetricBar(
                      label: 'Water',
                      value: '—',
                      progress: 0,
                      color: AppColors.chartWater,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ModernCard(
            padding: const EdgeInsets.all(12),
            borderColor: AppColors.accent.withValues(alpha: 0.2),
            child: Row(
              children: [
                Expanded(
                  child: _WeeklyStat(
                    label: 'Weekly orders',
                    value: '${summary.orderCount}',
                  ),
                ),
                Expanded(
                  child: _WeeklyStat(
                    label: 'Active days',
                    value: '$activeDays/7',
                  ),
                ),
                Expanded(
                  child: _WeeklyStat(
                    label: 'Health score',
                    value: '$score',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '7-day calories',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          CompactNutritionBarChart(
            points: summary.points,
            onTap: openDetails,
          ),
          const SizedBox(height: 10),
          Text(
            'Tap chart for full nutrition breakdown',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _HealthScoreGauge extends StatelessWidget {
  const _HealthScoreGauge({required this.score, required this.animation});

  final int score;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        return SizedBox(
          width: 88,
          height: 88,
          child: CustomPaint(
            painter: _GaugePainter(progress: (score / 100) * t, score: score),
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.progress, required this.score});

  final double progress;
  final int score;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final bg = Paint()
      ..color = AppColors.surfaceLight.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    final fg = Paint()
      ..shader = SweepGradient(
        colors: [AppColors.accent, AppColors.brandButtonHover],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8;

    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fg,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: '$score',
        style: TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.w800,
          fontSize: 22,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.score != score;
}

class _WeeklyStat extends StatelessWidget {
  const _WeeklyStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  final String label;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: Theme.of(context).textTheme.labelMedium)),
            Text(value, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.surfaceLight.withValues(alpha: 0.4),
            color: color,
          ),
        ),
      ],
    );
  }
}

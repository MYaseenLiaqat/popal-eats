import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/preferences_provider.dart';
import '../services/health_nutrition_service.dart';
import '../theme/app_colors.dart';
import '../widgets/health/nutrition_trend_chart.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Nutrition dashboard built from order history and dish macro data.
class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> {
  final _service = HealthNutritionService();

  static const _filters = <int, String>{
    7: '7 days',
    30: '30 days',
    90: '3 months',
  };

  int _days = 7;
  NutritionMetric _metric = NutritionMetric.calories;
  bool _loading = true;
  String? _error;
  HealthNutritionSummary? _summary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PreferencesProvider>().fetch(force: true);
    });
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await _service.load(days: _days);
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

  void _setDays(int days) {
    if (_days == days) return;
    setState(() => _days = days);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();
    final goalLabel = prefs.preferences?.nutritionGoal ?? 'maintain';

    return Scaffold(
      appBar: AppBar(title: const Text('Health Dashboard')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.accent,
                  child: ListView(
                    padding: const EdgeInsets.all(AppColors.screenPadding),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Wrap(
                        spacing: 8,
                        children: _filters.entries
                            .map(
                              (e) => ChoiceChip(
                                label: Text(e.value),
                                selected: _days == e.key,
                                onSelected: (_) => _setDays(e.key),
                                selectedColor:
                                    AppColors.accent.withValues(alpha: 0.25),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      if (_summary?.hasData != true)
                        const ModernCard(
                          child: EmptyState(
                            icon: Icons.restaurant_outlined,
                            title: 'No nutrition data yet',
                            subtitle:
                                'Order dishes with nutrition info to see your trends here.',
                          ),
                        )
                      else if (_summary!.points.where((p) => p.calories > 0).length < 2)
                        const ModernCard(
                          child: EmptyState(
                            icon: Icons.show_chart_outlined,
                            title: 'Not enough history yet',
                            subtitle:
                                'Order on at least two different days to unlock trend charts.',
                          ),
                        )
                      else ...[
                        ModernCard(
                          gradient: AppColors.headerGradient,
                          borderColor: AppColors.accent.withValues(alpha: 0.4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nutrition trends',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(color: AppColors.accent),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Goal: $goalLabel',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                children: NutritionMetric.values
                                    .map(
                                      (m) => ChoiceChip(
                                        label: Text(_metricLabel(m)),
                                        selected: _metric == m,
                                        onSelected: (_) => setState(() => _metric = m),
                                        selectedColor:
                                            AppColors.accent.withValues(alpha: 0.25),
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 12),
                              NutritionTrendChart(
                                points: _summary!.points,
                                metric: _metric,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _legend(_metricColor(_metric), _metricLabel(_metric)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: StatChip(
                                label: 'Total kcal',
                                value: '${_summary!.totalCalories}',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: StatChip(
                                label: 'Protein',
                                value:
                                    '${_summary!.totalProtein.toStringAsFixed(0)}g',
                                accent: AppColors.accent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: StatChip(
                                label: 'Health score',
                                value: '${_summary!.avgHealthScore}',
                                accent: Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const SectionHeader(
                          title: 'Daily breakdown',
                          subtitle: 'Per-day totals from your orders',
                        ),
                        ..._summary!.points.reversed.map((point) {
                          if (point.calories <= 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ModernCard(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${point.date.year}-${point.date.month.toString().padLeft(2, '0')}-${point.date.day.toString().padLeft(2, '0')}',
                                      style:
                                          Theme.of(context).textTheme.titleSmall,
                                    ),
                                  ),
                                  Text(
                                    '${point.calories} kcal',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppColors.accent),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${point.protein.toStringAsFixed(0)}g P',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${point.healthScore}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Colors.greenAccent),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  String _metricLabel(NutritionMetric metric) {
    switch (metric) {
      case NutritionMetric.calories:
        return 'Calories';
      case NutritionMetric.protein:
        return 'Protein';
      case NutritionMetric.healthScore:
        return 'Health Score';
    }
  }

  Color _metricColor(NutritionMetric metric) {
    switch (metric) {
      case NutritionMetric.calories:
        return AppColors.accent;
      case NutritionMetric.protein:
        return Colors.lightBlueAccent;
      case NutritionMetric.healthScore:
        return Colors.greenAccent;
    }
  }

  Widget _legend(Color color, String label, {bool isSpacer = false}) {
    if (isSpacer) return const Spacer();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

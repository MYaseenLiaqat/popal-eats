import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Health dashboard with mock nutrition data (Sprint 5C).
class HealthDashboardScreen extends StatelessWidget {
  const HealthDashboardScreen({super.key});

  static const _weekLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _weekValues = [1800, 2100, 1950, 2200, 1850, 2300, 1900];

  static const _maxCalories = 2300;
  static const _avgDay = 2014;
  static const _goal = 2200;
  static const _progress = 0.92;

  static const _insights = [
    'Calorie intake is close to goal.',
    'Protein intake is healthy.',
    'Water intake should be increased.',
  ];

  @override
  Widget build(BuildContext context) {
    final progressPct = (_progress * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Health Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(AppColors.screenPadding),
        children: [
          ModernCard(
            borderColor: AppColors.gold.withValues(alpha: 0.35),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.gold, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Preview screen — numbers shown are sample data, not your real intake.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ModernCard(
            gradient: AppColors.headerGradient,
            borderColor: AppColors.green.withValues(alpha: 0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.monitor_heart_outlined,
                        color: AppColors.green,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weekly analytics',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: AppColors.gold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Calorie overview & nutrition trends',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(_weekValues.length, (i) {
                      final factor = _weekValues[i] / _maxCalories;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${_weekValues[i]}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 9,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Flexible(
                                child: FractionallySizedBox(
                                  heightFactor: factor,
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          AppColors.green
                                              .withValues(alpha: 0.5),
                                          AppColors.gold.withValues(alpha: 0.9),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _weekLabels[i],
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              StatChip(
                label: 'Avg/Day',
                value: '$_avgDay kcal',
              ),
              SizedBox(width: 8),
              StatChip(
                label: 'Goal',
                value: '$_goal kcal',
                accent: AppColors.green,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '$progressPct%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.green,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progress,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader(
            title: 'Nutrition summary',
            subtitle: 'This week',
          ),
          const NutritionGrid(
            protein: 120,
            carbs: 250,
            fats: 70,
          ),
          ModernCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Water', style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  '2.3L',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.green,
                      ),
                ),
              ],
            ),
          ),
          const SectionHeader(
            title: 'Health insights',
            subtitle: 'Helpful tips for your goals',
          ),
          ..._insights.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ModernCard(
                borderColor: AppColors.gold.withValues(alpha: 0.3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.gold,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tip,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

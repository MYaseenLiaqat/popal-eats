import 'package:flutter/material.dart';

import '../../data/allergy_assets.dart';
import '../../models/dish.dart';
import '../../theme/app_colors.dart';
import '../../utils/preference_display.dart';
import 'dish_constants.dart';

class DishNutritionSection extends StatelessWidget {
  const DishNutritionSection({super.key, required this.dish});

  final Dish dish;

  bool get _hasData =>
      dish.calories != null ||
      dish.protein != null ||
      dish.carbs != null ||
      dish.fats != null ||
      dish.fiber != null ||
      dish.sugar != null ||
      dish.sodium != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nutrition',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text('Per serving', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 14),
          if (!_hasData)
            const DishInlineEmpty(
              icon: Icons.monitor_heart_outlined,
              title: 'Nutrition info unavailable',
              subtitle: 'This dish has no nutrition data yet',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 8) / 2;
                final items = <({String label, String value, IconData icon})>[
                  if (dish.calories != null)
                    (label: 'Calories', value: '${dish.calories} kcal', icon: Icons.local_fire_department_outlined),
                  if (dish.protein != null)
                    (label: 'Protein', value: '${dish.protein!.toStringAsFixed(1)} g', icon: Icons.fitness_center_outlined),
                  if (dish.carbs != null)
                    (label: 'Carbs', value: '${dish.carbs!.toStringAsFixed(1)} g', icon: Icons.grain_outlined),
                  if (dish.fats != null)
                    (label: 'Fat', value: '${dish.fats!.toStringAsFixed(1)} g', icon: Icons.water_drop_outlined),
                  if (dish.fiber != null)
                    (label: 'Fiber', value: '${dish.fiber!.toStringAsFixed(1)} g', icon: Icons.eco_outlined),
                  if (dish.sugar != null)
                    (label: 'Sugar', value: '${dish.sugar!.toStringAsFixed(1)} g', icon: Icons.cake_outlined),
                  if (dish.sodium != null)
                    (label: 'Sodium', value: '${dish.sodium!.toStringAsFixed(0)} mg', icon: Icons.science_outlined),
                ];

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: items.map((item) {
                    return SizedBox(
                      width: itemWidth,
                      child: _NutritionCard(
                        label: item.label,
                        value: item.value,
                        icon: item.icon,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  const _NutritionCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(DishConstants.cardRadius),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
          boxShadow: AppColors.cardShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.accent),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class DishIngredientsSection extends StatelessWidget {
  const DishIngredientsSection({super.key, required this.ingredients});

  final List<String> ingredients;

  @override
  Widget build(BuildContext context) {
    if (ingredients.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ingredients',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ingredients.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderStrong.withValues(alpha: 0.55)),
                ),
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class DishAllergensSection extends StatelessWidget {
  const DishAllergensSection({super.key, required this.allergens});

  final List<String> allergens;

  @override
  Widget build(BuildContext context) {
    if (allergens.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Allergens',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: allergens.map((raw) {
              final key = raw.trim().toLowerCase().replaceAll(' ', '_');
              final label = PreferenceDisplay.allergyLabel(key);
              return Container(
                padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
                decoration: BoxDecoration(
                  color: AppColors.accentSubtle,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipOval(
                      child: Image.asset(
                        AllergyAssets.pathFor(key),
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                        alignment: AllergyAssets.alignmentFor(key),
                        errorBuilder: (_, __, ___) => Container(
                          width: 28,
                          height: 28,
                          color: AppColors.surfaceLight,
                          child: const Icon(Icons.warning_amber_outlined, size: 16, color: AppColors.accent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class DishInlineEmpty extends StatelessWidget {
  const DishInlineEmpty({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(DishConstants.cardRadius),
        border: Border.all(color: AppColors.borderStrong.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.accent, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

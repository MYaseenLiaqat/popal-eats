import 'package:flutter/material.dart';

import '../data/local_preferences_store.dart';
import '../theme/app_colors.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Local-only nutrition preferences (Sprint 5B).
class NutritionPreferencesScreen extends StatefulWidget {
  const NutritionPreferencesScreen({super.key});

  @override
  State<NutritionPreferencesScreen> createState() =>
      _NutritionPreferencesScreenState();
}

class _NutritionPreferencesScreenState
    extends State<NutritionPreferencesScreen> {
  final _store = LocalPreferencesStore();
  final _calorieGoalController = TextEditingController();

  static const _dietTypes = [
    'None',
    'Vegetarian',
    'Vegan',
    'Keto',
    'High Protein',
  ];

  static const _cuisineOptions = [
    'Pakistani',
    'Italian',
    'Chinese',
    'Mediterranean',
    'American',
  ];

  String _dietType = LocalPreferencesStore.defaultDietType;
  final Set<String> _selectedCuisines = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final saved = await _store.loadNutrition();
    if (!mounted) return;
    setState(() {
      _calorieGoalController.text = saved.calorieGoal;
      _dietType = saved.dietType;
      _selectedCuisines
        ..clear()
        ..addAll(saved.cuisines);
      _loading = false;
    });
  }

  @override
  void dispose() {
    _calorieGoalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await _store.saveNutrition(
      calorieGoal: _calorieGoalController.text.trim().isEmpty
          ? LocalPreferencesStore.defaultCalorieGoal
          : _calorieGoalController.text.trim(),
      dietType: _dietType,
      cuisines: _selectedCuisines,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferences saved')),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color accent = AppColors.gold,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.2) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.6)
                : AppColors.surfaceLight.withValues(alpha: 0.8),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? accent : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nutrition Preferences')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition Preferences')),
      body: ListView(
        padding: const EdgeInsets.all(AppColors.screenPadding),
        children: [
          ModernCard(
            gradient: AppColors.headerGradient,
            borderColor: AppColors.gold.withValues(alpha: 0.35),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nutrition goals',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.gold,
                            ),
                      ),
                      Text(
                        'Personalize AI recommendations',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader(
            title: 'Daily calorie goal',
            subtitle: 'Target intake per day',
          ),
          ModernCard(
            borderColor: AppColors.gold.withValues(alpha: 0.4),
            child: TextField(
              controller: _calorieGoalController,
              keyboardType: TextInputType.number,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.gold,
                  ),
              decoration: const InputDecoration(
                hintText: '2100',
                suffixText: 'kcal',
                suffixStyle: TextStyle(color: AppColors.textSecondary),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SectionHeader(
            title: 'Diet type',
            subtitle: 'Select your diet preference',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _dietTypes.map((diet) {
              return _chip(
                label: diet,
                selected: _dietType == diet,
                onTap: () => setState(() => _dietType = diet),
                accent: AppColors.green,
              );
            }).toList(),
          ),
          const SectionHeader(
            title: 'Preferred cuisines',
            subtitle: 'Tap to select multiple',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _cuisineOptions.map((cuisine) {
              return _chip(
                label: cuisine,
                selected: _selectedCuisines.contains(cuisine),
                onTap: () {
                  setState(() {
                    if (_selectedCuisines.contains(cuisine)) {
                      _selectedCuisines.remove(cuisine);
                    } else {
                      _selectedCuisines.add(cuisine);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          GoldActionButton(
            label: 'Save Preferences',
            icon: Icons.check,
            onPressed: _save,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

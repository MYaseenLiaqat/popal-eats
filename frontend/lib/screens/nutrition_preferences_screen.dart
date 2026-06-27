import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/preferences_provider.dart';
import '../theme/app_colors.dart';
import '../utils/preference_display.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Nutrition preferences synced with backend GET/PUT /preferences.
class NutritionPreferencesScreen extends StatefulWidget {
  const NutritionPreferencesScreen({super.key});

  @override
  State<NutritionPreferencesScreen> createState() =>
      _NutritionPreferencesScreenState();
}

class _NutritionPreferencesScreenState
    extends State<NutritionPreferencesScreen> {
  final _calorieGoalController = TextEditingController(text: '2100');

  String _dietType = 'None';
  String _nutritionGoal = 'Maintain';
  final Set<String> _selectedCuisines = {};
  bool _initialized = false;

  List<MapEntry<String, String>> get _cuisineOptions {
    final entries = PreferenceDisplay.nutritionCuisineOptions.entries.toList();
    for (final key in _selectedCuisines) {
      if (!PreferenceDisplay.nutritionCuisineOptions.containsKey(key)) {
        entries.add(MapEntry(key, PreferenceDisplay.cuisineLabel(key)));
      }
    }
    return entries;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromBackend());
  }

  Future<void> _loadFromBackend() async {
    final provider = context.read<PreferencesProvider>();
    await provider.fetch(force: true);
    if (!mounted) return;

    final prefs = provider.preferences;
    if (provider.error != null || prefs == null) {
      setState(() => _initialized = true);
      return;
    }

    setState(() {
      _dietType = PreferenceDisplay.dietLabelFromBackend(prefs.dietaryPreferences);
      _nutritionGoal = PreferenceDisplay.nutritionGoalLabel(prefs.nutritionGoal);
      _selectedCuisines
        ..clear()
        ..addAll(prefs.favoriteCuisines);
      _initialized = true;
    });
  }

  @override
  void dispose() {
    _calorieGoalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final provider = context.read<PreferencesProvider>();
    final ok = await provider.updateNutrition(
      favoriteCuisines: _selectedCuisines.toList(),
      dietaryPreferences: PreferenceDisplay.dietToBackend(_dietType),
      nutritionGoal: PreferenceDisplay.nutritionGoalToBackend(_nutritionGoal),
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Could not save preferences')),
      );
    }
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color accent = AppColors.accent,
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

  Widget _buildBody(PreferencesProvider provider) {
    if (!_initialized || (provider.loading && provider.preferences == null)) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    if (provider.error != null && provider.preferences == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load preferences',
            subtitle: provider.error,
          ),
          TextButton(
            onPressed: _loadFromBackend,
            child: const Text('Retry'),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppColors.screenPadding),
      children: [
        ModernCard(
          gradient: AppColors.headerGradient,
          borderColor: AppColors.accent.withValues(alpha: 0.35),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  color: AppColors.accent,
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
                            color: AppColors.accent,
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
          title: 'Nutrition goal',
          subtitle: 'Adjust how we rank dishes for you',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PreferenceDisplay.nutritionGoals.values.map((goal) {
            return _chip(
              label: goal,
              selected: _nutritionGoal == goal,
              onTap: () => setState(() => _nutritionGoal = goal),
            );
          }).toList(),
        ),
        const SectionHeader(
          title: 'Daily calorie goal',
          subtitle: 'Target intake per day (device display only)',
        ),
        ModernCard(
          borderColor: AppColors.accent.withValues(alpha: 0.4),
          child: TextField(
            controller: _calorieGoalController,
            keyboardType: TextInputType.number,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.accent,
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
          children: PreferenceDisplay.dietTypes.map((diet) {
            return _chip(
              label: diet,
              selected: _dietType == diet,
              onTap: () => setState(() => _dietType = diet),
              accent: AppColors.accent,
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
          children: _cuisineOptions.map((entry) {
            return _chip(
              label: entry.value,
              selected: _selectedCuisines.contains(entry.key),
              onTap: () {
                setState(() {
                  if (_selectedCuisines.contains(entry.key)) {
                    _selectedCuisines.remove(entry.key);
                  } else {
                    _selectedCuisines.add(entry.key);
                  }
                });
              },
            );
          }).toList(),
        ),
        if ((provider.preferences?.allergies ?? []).isNotEmpty) ...[
          const SectionHeader(
            title: 'Allergies',
            subtitle: 'Synced from onboarding',
          ),
          ModernCard(
            child: Text(
              provider.preferences!.allergies
                  .map(PreferenceDisplay.allergyLabel)
                  .join(', '),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
        const SizedBox(height: 24),
        GoldActionButton(
          label: 'Save Preferences',
          icon: Icons.check,
          loading: provider.saving,
          onPressed: provider.saving ? null : _save,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PreferencesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition Preferences')),
      body: _buildBody(provider),
    );
  }
}

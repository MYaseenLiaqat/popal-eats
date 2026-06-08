import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for nutrition and budget preferences (device-only).
class LocalPreferencesStore {
  static const _calorieGoalKey = 'nutrition_calorie_goal';
  static const _dietTypeKey = 'nutrition_diet_type';
  static const _cuisinesKey = 'nutrition_cuisines';
  static const _weeklyBudgetKey = 'budget_weekly';
  static const _monthlyBudgetKey = 'budget_monthly';
  static const _budgetModeKey = 'budget_mode';

  static const defaultCalorieGoal = '2100';
  static const defaultDietType = 'None';
  static const defaultCuisines = ['Pakistani', 'Italian'];
  static const defaultWeeklyBudget = '150';
  static const defaultMonthlyBudget = '600';
  static const defaultBudgetMode = 'Balanced';

  Future<void> saveNutrition({
    required String calorieGoal,
    required String dietType,
    required Set<String> cuisines,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_calorieGoalKey, calorieGoal);
    await prefs.setString(_dietTypeKey, dietType);
    await prefs.setStringList(_cuisinesKey, cuisines.toList());
  }

  Future<({String calorieGoal, String dietType, Set<String> cuisines})>
      loadNutrition() async {
    final prefs = await SharedPreferences.getInstance();
    final cuisines = prefs.getStringList(_cuisinesKey);
    return (
      calorieGoal: prefs.getString(_calorieGoalKey) ?? defaultCalorieGoal,
      dietType: prefs.getString(_dietTypeKey) ?? defaultDietType,
      cuisines: cuisines != null && cuisines.isNotEmpty
          ? cuisines.toSet()
          : defaultCuisines.toSet(),
    );
  }

  Future<void> saveBudget({
    required String weeklyBudget,
    required String monthlyBudget,
    required String budgetMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weeklyBudgetKey, weeklyBudget);
    await prefs.setString(_monthlyBudgetKey, monthlyBudget);
    await prefs.setString(_budgetModeKey, budgetMode);
  }

  Future<({String weeklyBudget, String monthlyBudget, String budgetMode})>
      loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      weeklyBudget: prefs.getString(_weeklyBudgetKey) ?? defaultWeeklyBudget,
      monthlyBudget: prefs.getString(_monthlyBudgetKey) ?? defaultMonthlyBudget,
      budgetMode: prefs.getString(_budgetModeKey) ?? defaultBudgetMode,
    );
  }
}

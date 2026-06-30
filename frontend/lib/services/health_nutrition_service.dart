import '../models/dish.dart';
import '../services/api_client.dart';
import '../services/dish_service.dart';
import '../services/order_service.dart';

/// Daily nutrition rollup from completed orders and dish macro data.
class DailyNutritionPoint {
  const DailyNutritionPoint({
    required this.date,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.healthScore,
  });

  final DateTime date;
  final int calories;
  final double protein;
  final double carbs;
  final int healthScore;
}

class HealthNutritionSummary {
  const HealthNutritionSummary({
    required this.points,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.avgHealthScore,
    required this.orderCount,
  });

  final List<DailyNutritionPoint> points;
  final int totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final int avgHealthScore;
  final int orderCount;

  bool get hasData => orderCount > 0;
}

class HealthNutritionService {
  HealthNutritionService({
    OrderService? orders,
    DishService? dishes,
  })  : _orders = orders ?? OrderService(),
        _dishes = dishes ?? DishService();

  final OrderService _orders;
  final DishService _dishes;

  static const defaultCalorieGoal = 2200;
  static const defaultProteinGoal = 75.0;
  static const defaultCarbsGoal = 275.0;
  static const defaultWaterGoalMl = 2000;

  Future<HealthNutritionSummary> load({required int days}) async {
    if (!ApiClient.instance.isAuthenticated) {
      return const HealthNutritionSummary(
        points: [],
        totalCalories: 0,
        totalProtein: 0,
        totalCarbs: 0,
        avgHealthScore: 0,
        orderCount: 0,
      );
    }

    final orders = await _orders.myOrders(limit: 100);
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final dishCache = <int, Dish?>{};

    final buckets = <DateTime, ({int calories, double protein, double carbs})>{};

    var orderCount = 0;
    for (final order in orders) {
      if (order.createdAt == null || order.createdAt!.isBefore(cutoff)) continue;
      if (order.status.toLowerCase() == 'cancelled') continue;

      final day = DateTime(
        order.createdAt!.year,
        order.createdAt!.month,
        order.createdAt!.day,
      );
      orderCount++;

      for (final item in order.items) {
        final dish = await _dishFor(item.dishId, dishCache);
        final qty = item.quantity;
        final cals = (dish?.calories ?? 0) * qty;
        final protein = (dish?.protein ?? 0) * qty;
        final carbs = (dish?.carbs ?? 0) * qty;
        final existing = buckets[day];
        buckets[day] = (
          calories: (existing?.calories ?? 0) + cals,
          protein: (existing?.protein ?? 0) + protein,
          carbs: (existing?.carbs ?? 0) + carbs,
        );
      }
    }

    final points = <DailyNutritionPoint>[];
    for (var i = days - 1; i >= 0; i--) {
      final day = DateTime.now().subtract(Duration(days: i));
      final key = DateTime(day.year, day.month, day.day);
      final bucket = buckets[key];
      final calories = bucket?.calories ?? 0;
      final protein = bucket?.protein ?? 0;
      final carbs = bucket?.carbs ?? 0;
      points.add(
        DailyNutritionPoint(
          date: key,
          calories: calories,
          protein: protein,
          carbs: carbs,
          healthScore: _healthScore(calories: calories, protein: protein),
        ),
      );
    }

    final totalCalories = points.fold<int>(0, (a, p) => a + p.calories);
    final totalProtein = points.fold<double>(0, (a, p) => a + p.protein);
    final totalCarbs = points.fold<double>(0, (a, p) => a + p.carbs);
    final scored = points.where((p) => p.calories > 0).toList();
    final avgHealth = scored.isEmpty
        ? 0
        : (scored.fold<int>(0, (a, p) => a + p.healthScore) / scored.length)
            .round();

    return HealthNutritionSummary(
      points: points,
      totalCalories: totalCalories,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      avgHealthScore: avgHealth,
      orderCount: orderCount,
    );
  }

  Future<Dish?> _dishFor(int dishId, Map<int, Dish?> cache) async {
    if (cache.containsKey(dishId)) return cache[dishId];
    try {
      final dish = await _dishes.getById(dishId);
      cache[dishId] = dish;
      return dish;
    } catch (_) {
      cache[dishId] = null;
      return null;
    }
  }

  int _healthScore({required int calories, required double protein}) {
    if (calories <= 0) return 0;
    final calorieRatio = calories / defaultCalorieGoal;
    final calorieScore = (100 - (calorieRatio - 1).abs() * 100).clamp(0, 100);
    final proteinScore =
        (protein / defaultProteinGoal * 100).clamp(0, 100).toDouble();
    return ((calorieScore + proteinScore) / 2).round();
  }
}

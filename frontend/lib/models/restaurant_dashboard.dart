import 'json_parse.dart';

/// Owner dashboard metrics from GET /restaurants/{id}/dashboard.
class RestaurantDashboard {
  const RestaurantDashboard({
    required this.restaurantId,
    required this.restaurantName,
    required this.approvalStatus,
    required this.totalDishes,
    required this.availableDishes,
    required this.averageRating,
    required this.totalReviews,
    required this.totalOrders,
    required this.popularDishes,
  });

  final int restaurantId;
  final String restaurantName;
  final String approvalStatus;
  final int totalDishes;
  final int availableDishes;
  final double averageRating;
  final int totalReviews;
  final int totalOrders;
  final List<PopularDishStat> popularDishes;

  bool get isPending => approvalStatus == 'pending';
  bool get isApproved => approvalStatus == 'approved';
  bool get isRejected => approvalStatus == 'rejected';

  factory RestaurantDashboard.fromJson(Map<String, dynamic> json) {
    final popular = json['popular_dishes'];
    return RestaurantDashboard(
      restaurantId: parseInt(json['restaurant_id'], field: 'restaurant_id'),
      restaurantName: parseString(json['restaurant_name']),
      approvalStatus: json['approval_status']?.toString() ?? 'pending',
      totalDishes: parseIntOrNull(json['total_dishes']) ?? 0,
      availableDishes: parseIntOrNull(json['available_dishes']) ?? 0,
      averageRating: parseDoubleOrNull(json['average_rating']) ?? 0,
      totalReviews: parseIntOrNull(json['total_reviews']) ?? 0,
      totalOrders: parseIntOrNull(json['total_orders']) ?? 0,
      popularDishes: popular is List
          ? popular
              .whereType<Map>()
              .map((e) => PopularDishStat.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

class PopularDishStat {
  const PopularDishStat({
    required this.dishId,
    required this.dishName,
    required this.orderCount,
  });

  final int dishId;
  final String dishName;
  final int orderCount;

  factory PopularDishStat.fromJson(Map<String, dynamic> json) => PopularDishStat(
        dishId: parseInt(json['dish_id'], field: 'dish_id'),
        dishName: parseString(json['dish_name']),
        orderCount: parseIntOrNull(json['order_count']) ?? 0,
      );
}

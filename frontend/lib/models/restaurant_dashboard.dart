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
    this.ordersToday = 0,
    this.pendingOrders = 0,
    this.completedOrdersToday = 0,
    this.revenueToday = 0,
    this.popularDish,
    this.recentReviews = const [],
    this.totalPosts = 0,
    this.postEngagement = 0,
    this.storyViews = 0,
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
  final int ordersToday;
  final int pendingOrders;
  final int completedOrdersToday;
  final double revenueToday;
  final PopularDishStat? popularDish;
  final List<ReviewBrief> recentReviews;
  final int totalPosts;
  final int postEngagement;
  final int storyViews;

  bool get isPending => approvalStatus == 'pending';
  bool get isApproved => approvalStatus == 'approved';
  bool get isRejected => approvalStatus == 'rejected';

  factory RestaurantDashboard.fromJson(Map<String, dynamic> json) {
    final popular = json['popular_dishes'];
    final reviews = json['recent_reviews'];
    final top = json['popular_dish'];
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
      ordersToday: parseIntOrNull(json['orders_today']) ?? 0,
      pendingOrders: parseIntOrNull(json['pending_orders']) ?? 0,
      completedOrdersToday: parseIntOrNull(json['completed_orders_today']) ?? 0,
      revenueToday: parseDoubleOrNull(json['revenue_today']) ?? 0,
      popularDish: top is Map ? PopularDishStat.fromJson(Map<String, dynamic>.from(top)) : null,
      recentReviews: reviews is List
          ? reviews
              .whereType<Map>()
              .map((e) => ReviewBrief.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      totalPosts: parseIntOrNull(json['total_posts']) ?? 0,
      postEngagement: parseIntOrNull(json['post_engagement']) ?? 0,
      storyViews: parseIntOrNull(json['story_views']) ?? 0,
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

class ReviewBrief {
  const ReviewBrief({
    required this.id,
    required this.rating,
    this.comment,
    this.authorName,
    this.createdAt,
  });

  final int id;
  final int rating;
  final String? comment;
  final String? authorName;
  final DateTime? createdAt;

  factory ReviewBrief.fromJson(Map<String, dynamic> json) => ReviewBrief(
        id: parseInt(json['id'], field: 'id'),
        rating: parseInt(json['rating'], field: 'rating'),
        comment: json['comment']?.toString(),
        authorName: json['author_name']?.toString(),
        createdAt: parseDateTimeOrNull(json['created_at']),
      );
}

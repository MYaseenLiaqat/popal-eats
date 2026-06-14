import 'json_parse.dart';

class GroupDishRecommendation {
  const GroupDishRecommendation({
    this.recommendationId,
    required this.dishId,
    required this.dishName,
    required this.restaurantName,
    required this.price,
    required this.score,
    this.consensusScore = 0,
    this.finalScore,
    this.reasons = const [],
    this.dishImageUrl,
  });

  final int? recommendationId;
  final int dishId;
  final String dishName;
  final String restaurantName;
  final double price;
  final double score;
  final double consensusScore;
  final double? finalScore;
  final List<String> reasons;
  final String? dishImageUrl;

  double get displayScore => (finalScore ?? score).clamp(0, 100);

  int get scorePercent => displayScore.round().clamp(0, 100);

  GroupDishRecommendation copyWith({String? dishImageUrl}) {
    return GroupDishRecommendation(
      recommendationId: recommendationId,
      dishId: dishId,
      dishName: dishName,
      restaurantName: restaurantName,
      price: price,
      score: score,
      consensusScore: consensusScore,
      finalScore: finalScore,
      reasons: reasons,
      dishImageUrl: dishImageUrl ?? this.dishImageUrl,
    );
  }

  factory GroupDishRecommendation.fromJson(Map<String, dynamic> json) {
    return GroupDishRecommendation(
      recommendationId: parseIntOrNull(json['recommendation_id']),
      dishId: parseInt(json['dish_id'], field: 'dish_id'),
      dishName: parseString(json['dish_name']),
      restaurantName: parseString(json['restaurant_name']),
      price: parseDouble(json['price'], field: 'price'),
      score: parseDoubleOrNull(json['score']) ?? 0,
      consensusScore: parseDoubleOrNull(json['consensus_score']) ?? 0,
      finalScore: parseDoubleOrNull(json['final_score']),
      reasons: json['reasons'] is List
          ? (json['reasons'] as List).map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [],
    );
  }
}

class GroupRecommendationsResult {
  const GroupRecommendationsResult({
    required this.groupId,
    required this.memberCount,
    this.groupLatitude,
    this.groupLongitude,
    required this.recommendations,
  });

  final int groupId;
  final int memberCount;
  final double? groupLatitude;
  final double? groupLongitude;
  final List<GroupDishRecommendation> recommendations;

  factory GroupRecommendationsResult.fromJson(Map<String, dynamic> json) {
    final raw = json['recommendations'];
    return GroupRecommendationsResult(
      groupId: parseInt(json['group_id'], field: 'group_id'),
      memberCount: parseIntOrNull(json['member_count']) ?? 0,
      groupLatitude: parseDoubleOrNull(json['group_latitude']),
      groupLongitude: parseDoubleOrNull(json['group_longitude']),
      recommendations: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => GroupDishRecommendation.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

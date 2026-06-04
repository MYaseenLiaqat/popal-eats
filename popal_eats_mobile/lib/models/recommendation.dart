/// Recommendation item from Engine V2 API (`GET /recommendations/v2`).
class Recommendation {
  final int dishId;
  final String dishName;
  final String restaurantName;
  final double score;
  final String explanation;

  const Recommendation({
    required this.dishId,
    required this.dishName,
    required this.restaurantName,
    required this.score,
    required this.explanation,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      dishId: _asInt(json['dish_id'], field: 'dish_id'),
      dishName: _asString(json['dish_name'], field: 'dish_name'),
      restaurantName: _asString(json['restaurant_name'], field: 'restaurant_name'),
      score: _asDouble(json['score'], field: 'score'),
      explanation: _asString(json['explanation'], field: 'explanation', fallback: ''),
    );
  }

  static int _asInt(dynamic value, {required String field}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw FormatException('Expected int for $field, got ${value.runtimeType}');
  }

  static double _asDouble(dynamic value, {required String field}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.parse(value);
    throw FormatException('Expected number for $field, got ${value.runtimeType}');
  }

  static String _asString(
    dynamic value, {
    required String field,
    String fallback = '',
  }) {
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }
}

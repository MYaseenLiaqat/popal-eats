import 'json_parse.dart';

/// Dish from `DishResponse` (including nested cart payloads).
class Dish {
  const Dish({
    required this.id,
    required this.name,
    required this.price,
    required this.restaurantId,
    required this.categoryId,
    this.description,
    this.calories,
    this.protein,
    this.carbs,
    this.fats,
    this.image,
    this.isAvailable = true,
    this.createdAt,
  });

  final int id;
  final String name;
  final double price;
  final int restaurantId;
  final int categoryId;
  final String? description;
  final int? calories;
  final double? protein;
  final double? carbs;
  final double? fats;
  final String? image;
  final bool isAvailable;
  final DateTime? createdAt;

  factory Dish.fromJson(Map<String, dynamic> json) => Dish(
        id: parseInt(json['id'], field: 'id'),
        name: parseString(json['name']),
        price: parseDouble(json['price'], field: 'price'),
        restaurantId: parseInt(json['restaurant_id'], field: 'restaurant_id'),
        categoryId: parseInt(json['category_id'], field: 'category_id'),
        description: json['description']?.toString(),
        calories: parseIntOrNull(json['calories']),
        protein: parseDoubleOrNull(json['protein']),
        carbs: parseDoubleOrNull(json['carbs']),
        fats: parseDoubleOrNull(json['fats']),
        image: json['image']?.toString(),
        isAvailable: parseBool(json['is_available']),
        createdAt: parseDateTimeOrNull(json['created_at']),
      );
}

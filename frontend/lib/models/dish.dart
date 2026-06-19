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
    this.cuisine,
    this.calories,
    this.protein,
    this.carbs,
    this.fats,
    this.fiber,
    this.sugar,
    this.sodium,
    this.ingredients = const [],
    this.allergens = const [],
    this.image,
    this.images = const [],
    this.isAvailable = true,
    this.createdAt,
  });

  final int id;
  final String name;
  final double price;
  final int restaurantId;
  final int categoryId;
  final String? description;
  final String? cuisine;
  final int? calories;
  final double? protein;
  final double? carbs;
  final double? fats;
  final double? fiber;
  final double? sugar;
  final double? sodium;
  final List<String> ingredients;
  final List<String> allergens;
  final String? image;
  final List<String> images;
  final bool isAvailable;
  final DateTime? createdAt;

  factory Dish.fromJson(Map<String, dynamic> json) => Dish(
        id: parseInt(json['id'], field: 'id'),
        name: parseString(json['name']),
        price: parseDouble(json['price'], field: 'price'),
        restaurantId: parseInt(json['restaurant_id'], field: 'restaurant_id'),
        categoryId: parseInt(json['category_id'], field: 'category_id'),
        description: json['description']?.toString(),
        cuisine: json['cuisine']?.toString(),
        calories: parseIntOrNull(json['calories']),
        protein: parseDoubleOrNull(json['protein']),
        carbs: parseDoubleOrNull(json['carbs']),
        fats: parseDoubleOrNull(json['fats']),
        fiber: parseDoubleOrNull(json['fiber']),
        sugar: parseDoubleOrNull(json['sugar']),
        sodium: parseDoubleOrNull(json['sodium']),
        ingredients: _stringList(json['ingredients']),
        allergens: _stringList(json['allergens']),
        image: json['image']?.toString(),
        images: _stringList(json['images']),
        isAvailable: parseBool(json['is_available']),
        createdAt: parseDateTimeOrNull(json['created_at']),
      );

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }

  Map<String, dynamic> toWriteJson({bool includeRestaurantId = true}) {
    return {
      if (includeRestaurantId) 'restaurant_id': restaurantId,
      'category_id': categoryId,
      'name': name,
      if (description != null) 'description': description,
      'price': price,
      if (cuisine != null && cuisine!.isNotEmpty) 'cuisine': cuisine,
      if (calories != null) 'calories': calories,
      if (protein != null) 'protein': protein,
      if (carbs != null) 'carbs': carbs,
      if (fats != null) 'fats': fats,
      if (fiber != null) 'fiber': fiber,
      if (sugar != null) 'sugar': sugar,
      if (sodium != null) 'sodium': sodium,
      if (ingredients.isNotEmpty) 'ingredients': ingredients,
      if (allergens.isNotEmpty) 'allergens': allergens,
      if (image != null && image!.isNotEmpty) 'image': image,
      if (images.isNotEmpty) 'images': images,
      'is_available': isAvailable,
    };
  }
}

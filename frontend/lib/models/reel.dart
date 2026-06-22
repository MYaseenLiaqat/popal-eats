/// Recipe, chef, or restaurant spotlight reel.
enum ReelKind {
  recipe,
  chef,
  restaurant,
}

class Reel {
  const Reel({
    required this.id,
    required this.kind,
    required this.title,
    required this.creatorName,
    required this.caption,
    this.thumbnailUrl,
    this.videoUrl,
    this.durationLabel,
    this.postId,
    this.recipeIngredients = const [],
    this.recipeDescription,
    this.calories,
    this.protein,
    this.carbs,
    this.fats,
  });

  final String id;
  final ReelKind kind;
  final String title;
  final String creatorName;
  final String caption;
  final String? thumbnailUrl;
  final String? videoUrl;
  final String? durationLabel;
  final int? postId;
  final List<String> recipeIngredients;
  final String? recipeDescription;
  final int? calories;
  final double? protein;
  final double? carbs;
  final double? fats;

  bool get hasRecipeDetails =>
      recipeIngredients.isNotEmpty ||
      (recipeDescription != null && recipeDescription!.isNotEmpty) ||
      calories != null;

  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;

  String get kindLabel {
    switch (kind) {
      case ReelKind.recipe:
        return 'Recipe reel';
      case ReelKind.chef:
        return 'Chef reel';
      case ReelKind.restaurant:
        return 'Restaurant';
    }
  }

  factory Reel.fromJson(Map<String, dynamic> json) {
    final kindRaw = json['kind']?.toString().toLowerCase() ??
        json['post_type']?.toString().toLowerCase() ??
        'recipe';
    ReelKind kind;
    switch (kindRaw) {
      case 'chef':
      case 'chef_post':
        kind = ReelKind.chef;
        break;
      case 'restaurant':
      case 'restaurant_post':
        kind = ReelKind.restaurant;
        break;
      default:
        kind = ReelKind.recipe;
    }
    return Reel(
      id: json['id']?.toString() ?? '',
      kind: kind,
      title: json['title']?.toString() ?? '',
      creatorName: json['creator_name']?.toString() ?? '',
      caption: json['caption']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_url']?.toString(),
      videoUrl: json['video_url']?.toString(),
      durationLabel: json['duration_label']?.toString(),
      postId: json['post_id'] as int?,
      recipeIngredients: _stringList(json['recipe_ingredients']),
      recipeDescription: json['recipe_description']?.toString(),
      calories: json['calories'] is int
          ? json['calories'] as int
          : int.tryParse(json['calories']?.toString() ?? ''),
      protein: _doubleOrNull(json['protein']),
      carbs: _doubleOrNull(json['carbs']),
      fats: _doubleOrNull(json['fats']),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return [];
    return value.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }

  static double? _doubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

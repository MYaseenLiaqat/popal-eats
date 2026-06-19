import 'social_user.dart';

enum PostType {
  foodPost,
  recipe,
  chefPost,
  restaurantPost,
}

enum RestaurantContentSubtype {
  promotion,
  newDish,
  announcement,
}

class Post {
  const Post({
    required this.id,
    required this.authorId,
    required this.postType,
    this.caption,
    this.title,
    this.images = const [],
    this.videoUrl,
    this.restaurantId,
    this.dishId,
    this.restaurantContentSubtype,
    this.recipeDescription,
    this.recipeIngredients = const [],
    this.recipeSteps = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.saveCount = 0,
    this.createdAt,
    this.author,
    this.restaurantName,
    this.dishName,
    this.likedByMe = false,
    this.savedByMe = false,
  });

  final int id;
  final int authorId;
  final PostType postType;
  final String? caption;
  final String? title;
  final List<String> images;
  final String? videoUrl;
  final int? restaurantId;
  final int? dishId;
  final RestaurantContentSubtype? restaurantContentSubtype;
  final String? recipeDescription;
  final List<String> recipeIngredients;
  final List<String> recipeSteps;
  final int likeCount;
  final int commentCount;
  final int saveCount;
  final DateTime? createdAt;
  final UserPublicProfile? author;
  final String? restaurantName;
  final String? dishName;
  final bool likedByMe;
  final bool savedByMe;

  String get typeLabel {
    switch (postType) {
      case PostType.foodPost:
        return 'Food';
      case PostType.recipe:
        return 'Recipe';
      case PostType.chefPost:
        return 'Chef';
      case PostType.restaurantPost:
        return _restaurantSubtypeLabel;
    }
  }

  String get _restaurantSubtypeLabel {
    switch (restaurantContentSubtype) {
      case RestaurantContentSubtype.promotion:
        return 'Promotion';
      case RestaurantContentSubtype.newDish:
        return 'New dish';
      case RestaurantContentSubtype.announcement:
        return 'Announcement';
      default:
        return 'Restaurant';
    }
  }

  String get displayTitle => title ?? caption ?? 'Untitled';

  String get authorName =>
      postType == PostType.restaurantPost && restaurantName != null
          ? restaurantName!
          : author?.fullName ?? 'User';

  static PostType _parseType(String raw) {
    switch (raw.toLowerCase()) {
      case 'recipe':
        return PostType.recipe;
      case 'chef_post':
        return PostType.chefPost;
      case 'restaurant_post':
        return PostType.restaurantPost;
      default:
        return PostType.foodPost;
    }
  }

  static RestaurantContentSubtype? _parseSubtype(String? raw) {
    if (raw == null) return null;
    switch (raw.toLowerCase()) {
      case 'promotion':
        return RestaurantContentSubtype.promotion;
      case 'new_dish':
        return RestaurantContentSubtype.newDish;
      case 'announcement':
        return RestaurantContentSubtype.announcement;
      default:
        return null;
    }
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    final imagesRaw = json['images'];
    final ingredientsRaw = json['recipe_ingredients'];
    final stepsRaw = json['recipe_steps'];

    return Post(
      id: json['id'] as int,
      authorId: json['author_id'] as int,
      postType: _parseType(json['post_type']?.toString() ?? 'food_post'),
      caption: json['caption']?.toString(),
      title: json['title']?.toString(),
      images: imagesRaw is List
          ? imagesRaw.map((e) => e.toString()).toList()
          : const [],
      videoUrl: json['video_url']?.toString(),
      restaurantId: json['restaurant_id'] as int?,
      dishId: json['dish_id'] as int?,
      restaurantContentSubtype: _parseSubtype(json['restaurant_content_subtype']?.toString()),
      recipeDescription: json['recipe_description']?.toString(),
      recipeIngredients: ingredientsRaw is List
          ? ingredientsRaw.map((e) => e.toString()).toList()
          : const [],
      recipeSteps: stepsRaw is List
          ? stepsRaw.map((e) => e.toString()).toList()
          : const [],
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      saveCount: (json['save_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      author: json['author'] is Map
          ? UserPublicProfile.fromJson(Map<String, dynamic>.from(json['author'] as Map))
          : null,
      restaurantName: json['restaurant_name']?.toString(),
      dishName: json['dish_name']?.toString(),
      likedByMe: json['liked_by_me'] == true,
      savedByMe: json['saved_by_me'] == true,
    );
  }

  Map<String, dynamic> toWriteJson() {
    final map = <String, dynamic>{
      'post_type': _typeApiValue(postType),
      if (caption != null) 'caption': caption,
      if (title != null) 'title': title,
      if (images.isNotEmpty) 'images': images,
      if (videoUrl != null) 'video_url': videoUrl,
      if (restaurantId != null) 'restaurant_id': restaurantId,
      if (dishId != null) 'dish_id': dishId,
      if (restaurantContentSubtype != null)
        'restaurant_content_subtype': _subtypeApiValue(restaurantContentSubtype!),
      if (recipeDescription != null) 'recipe_description': recipeDescription,
      if (recipeIngredients.isNotEmpty) 'recipe_ingredients': recipeIngredients,
      if (recipeSteps.isNotEmpty) 'recipe_steps': recipeSteps,
    };
    return map;
  }

  static String _typeApiValue(PostType type) {
    switch (type) {
      case PostType.foodPost:
        return 'food_post';
      case PostType.recipe:
        return 'recipe';
      case PostType.chefPost:
        return 'chef_post';
      case PostType.restaurantPost:
        return 'restaurant_post';
    }
  }

  static String _subtypeApiValue(RestaurantContentSubtype subtype) {
    switch (subtype) {
      case RestaurantContentSubtype.promotion:
        return 'promotion';
      case RestaurantContentSubtype.newDish:
        return 'new_dish';
      case RestaurantContentSubtype.announcement:
        return 'announcement';
    }
  }

  Post copyWith({
    bool? likedByMe,
    int? likeCount,
    bool? savedByMe,
    int? saveCount,
    int? commentCount,
  }) {
    return Post(
      id: id,
      authorId: authorId,
      postType: postType,
      caption: caption,
      title: title,
      images: images,
      videoUrl: videoUrl,
      restaurantId: restaurantId,
      dishId: dishId,
      restaurantContentSubtype: restaurantContentSubtype,
      recipeDescription: recipeDescription,
      recipeIngredients: recipeIngredients,
      recipeSteps: recipeSteps,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      saveCount: saveCount ?? this.saveCount,
      createdAt: createdAt,
      author: author,
      restaurantName: restaurantName,
      dishName: dishName,
      likedByMe: likedByMe ?? this.likedByMe,
      savedByMe: savedByMe ?? this.savedByMe,
    );
  }
}

class PostComment {
  const PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.body,
    this.createdAt,
    this.author,
  });

  final int id;
  final int postId;
  final int userId;
  final String body;
  final DateTime? createdAt;
  final UserPublicProfile? author;

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['id'] as int,
      postId: json['post_id'] as int,
      userId: json['user_id'] as int,
      body: json['body']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      author: json['author'] is Map
          ? UserPublicProfile.fromJson(Map<String, dynamic>.from(json['author'] as Map))
          : null,
    );
  }
}

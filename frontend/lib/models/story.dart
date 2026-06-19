import 'social_user.dart';

class StoryItem {
  const StoryItem({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.expiresAt,
    this.createdAt,
    this.user,
    this.viewedByMe = false,
  });

  final int id;
  final int userId;
  final String imageUrl;
  final DateTime expiresAt;
  final DateTime? createdAt;
  final UserPublicProfile? user;
  final bool viewedByMe;

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    return StoryItem(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      imageUrl: json['image_url']?.toString() ?? '',
      expiresAt: DateTime.parse(json['expires_at'].toString()),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      user: json['user'] is Map
          ? UserPublicProfile.fromJson(Map<String, dynamic>.from(json['user'] as Map))
          : null,
      viewedByMe: json['viewed_by_me'] == true,
    );
  }
}

class StoryGroup {
  const StoryGroup({
    required this.user,
    required this.stories,
    this.hasUnviewed = false,
  });

  final UserPublicProfile user;
  final List<StoryItem> stories;
  final bool hasUnviewed;

  factory StoryGroup.fromJson(Map<String, dynamic> json) {
    final storiesRaw = json['stories'];
    return StoryGroup(
      user: UserPublicProfile.fromJson(
        Map<String, dynamic>.from(json['user'] as Map),
      ),
      stories: storiesRaw is List
          ? storiesRaw
              .whereType<Map>()
              .map((e) => StoryItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      hasUnviewed: json['has_unviewed'] == true,
    );
  }
}

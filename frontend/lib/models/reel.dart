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
    );
  }
}

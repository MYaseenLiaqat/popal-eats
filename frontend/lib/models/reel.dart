/// Recipe or chef spotlight reel (video playback not implemented yet).
enum ReelKind {
  recipe,
  chef,
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
  });

  final String id;
  final ReelKind kind;
  final String title;
  final String creatorName;
  final String caption;
  final String? thumbnailUrl;

  /// Reserved for future streaming integration — unused in Phase 5.
  final String? videoUrl;
  final String? durationLabel;

  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;

  String get kindLabel =>
      kind == ReelKind.recipe ? 'Recipe reel' : 'Chef reel';

  factory Reel.fromJson(Map<String, dynamic> json) {
    final kindRaw = json['kind']?.toString().toLowerCase() ?? 'recipe';
    return Reel(
      id: json['id']?.toString() ?? '',
      kind: kindRaw == 'chef' ? ReelKind.chef : ReelKind.recipe,
      title: json['title']?.toString() ?? '',
      creatorName: json['creator_name']?.toString() ?? '',
      caption: json['caption']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_url']?.toString(),
      videoUrl: json['video_url']?.toString(),
      durationLabel: json['duration_label']?.toString(),
    );
  }
}

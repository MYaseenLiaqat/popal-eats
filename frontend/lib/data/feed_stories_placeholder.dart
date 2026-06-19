/// Placeholder story rings for the home feed (no backend yet).
class FeedStory {
  const FeedStory({
    required this.id,
    required this.label,
    required this.isOwn,
    this.imageUrl,
  });

  final String id;
  final String label;
  final bool isOwn;
  final String? imageUrl;
}

class FeedStoriesPlaceholder {
  FeedStoriesPlaceholder._();

  static List<FeedStory> stories(String userName) {
    final first = userName.isNotEmpty ? userName.split(' ').first : 'You';
    return [
      FeedStory(id: 'create', label: 'Your story', isOwn: true),
      FeedStory(id: 'trending', label: 'Trending', isOwn: false),
      FeedStory(id: 'biryani', label: 'Biryani', isOwn: false),
      FeedStory(id: 'bbq', label: 'BBQ night', isOwn: false),
      FeedStory(id: 'dessert', label: 'Desserts', isOwn: false),
      FeedStory(id: 'friends', label: '$first\'s picks', isOwn: false),
    ];
  }
}

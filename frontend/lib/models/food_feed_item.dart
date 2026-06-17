/// A single card in the home food feed.
enum FoodFeedKind {
  recommended,
  trending,
  groupDecision,
  friendPlaceholder,
  discover,
}

class FoodFeedItem {
  const FoodFeedItem({
    required this.kind,
    required this.title,
    this.subtitle,
    this.restaurantName,
    this.price,
    this.imageUrl,
    this.dishId,
    this.groupSessionId,
    this.groupName,
    this.groupAgreed = false,
  });

  final FoodFeedKind kind;
  final String title;
  final String? subtitle;
  final String? restaurantName;
  final double? price;
  final String? imageUrl;
  final int? dishId;
  final int? groupSessionId;
  final String? groupName;
  final bool groupAgreed;

  String get kindLabel {
    switch (kind) {
      case FoodFeedKind.recommended:
        return 'Picked for you';
      case FoodFeedKind.trending:
        return 'Trending';
      case FoodFeedKind.groupDecision:
        return groupName != null ? '$groupName' : 'Group pick';
      case FoodFeedKind.friendPlaceholder:
        return 'Friends';
      case FoodFeedKind.discover:
        return 'Discover';
    }
  }

  bool get isInteractive =>
      kind != FoodFeedKind.friendPlaceholder || dishId != null;
}

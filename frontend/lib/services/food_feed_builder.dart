import '../models/food_feed_item.dart';
import '../models/group_decision.dart';
import '../models/group_session.dart';
import '../models/recommendation.dart';
import '../utils/recommendation_copy.dart';

/// Builds an interleaved home feed from recommendations and group activity.
class FoodFeedBuilder {
  FoodFeedBuilder._();

  static List<FoodFeedItem> build({
    required List<Recommendation> personalized,
    required List<Recommendation> trending,
    required List<({GroupSession session, GroupDecision decision})> groupDecisions,
    required Map<int, String?> dishImages,
    int maxDishCards = 10,
  }) {
    final items = <FoodFeedItem>[];

    for (final entry in groupDecisions.take(2)) {
      items.add(_groupItem(
        session: entry.session,
        decision: entry.decision,
        dishImages: dishImages,
      ));
    }

    final personalQueue = List<Recommendation>.from(personalized);
    final trendingQueue = List<Recommendation>.from(trending);
    var usePersonalized = true;
    var dishCards = 0;

    while (dishCards < maxDishCards &&
        (personalQueue.isNotEmpty || trendingQueue.isNotEmpty)) {
      Recommendation? rec;
      FoodFeedKind kind;

      if (usePersonalized && personalQueue.isNotEmpty) {
        rec = personalQueue.removeAt(0);
        kind = FoodFeedKind.recommended;
      } else if (trendingQueue.isNotEmpty) {
        rec = trendingQueue.removeAt(0);
        kind = FoodFeedKind.trending;
      } else if (personalQueue.isNotEmpty) {
        rec = personalQueue.removeAt(0);
        kind = FoodFeedKind.recommended;
      } else {
        break;
      }

      usePersonalized = !usePersonalized;
      dishCards++;
      items.add(_recommendationItem(rec, kind, dishImages));
    }

    items.add(
      const FoodFeedItem(
        kind: FoodFeedKind.discover,
        title: 'Explore more dishes',
        subtitle: 'Browse personalized picks and crowd favorites',
      ),
    );

    return items;
  }

  static FoodFeedItem _recommendationItem(
    Recommendation rec,
    FoodFeedKind kind,
    Map<int, String?> dishImages,
  ) {
    final reasons = kind == FoodFeedKind.recommended
        ? RecommendationCopy.humanReasons(rec)
        : const ['Trending this week'];

    return FoodFeedItem(
      kind: kind,
      title: rec.dishName,
      subtitle: reasons.isNotEmpty ? reasons.first : null,
      restaurantName: rec.restaurantName.isNotEmpty ? rec.restaurantName : null,
      price: rec.price,
      imageUrl: dishImages[rec.dishId],
      dishId: rec.dishId,
    );
  }

  static FoodFeedItem _groupItem({
    required GroupSession session,
    required GroupDecision decision,
    required Map<int, String?> dishImages,
  }) {
    final dishId = decision.dishId;
    String subtitle;

    if (decision.isAgreed && decision.dishName != null) {
      subtitle = 'Your group agreed on this pick';
    } else if (decision.isConsidering) {
      subtitle = 'Your group is narrowing it down';
    } else if (decision.isPending) {
      subtitle = 'Vote on what to eat together';
    } else if (decision.dishName != null) {
      subtitle = 'See what your group chose';
    } else {
      subtitle = 'Join your group\'s food decision';
    }

    return FoodFeedItem(
      kind: FoodFeedKind.groupDecision,
      title: decision.dishName ?? session.name,
      subtitle: subtitle,
      restaurantName: decision.restaurantName,
      price: decision.price,
      imageUrl: dishId != null ? dishImages[dishId] : null,
      dishId: dishId,
      groupSessionId: session.id,
      groupName: session.name,
      groupAgreed: decision.isAgreed,
    );
  }
}

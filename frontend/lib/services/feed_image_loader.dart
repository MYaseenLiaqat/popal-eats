import '../models/dish.dart';
import '../services/dish_service.dart';
import '../utils/profile_image_url.dart';

/// Loads dish image URLs for feed cards (parallel, capped).
class FeedImageLoader {
  FeedImageLoader({DishService? dishes}) : _dishes = dishes ?? DishService();

  final DishService _dishes;

  Future<Map<int, String?>> loadImages(Iterable<int> dishIds, {int max = 12}) async {
    final unique = dishIds.toSet().take(max);
    final map = <int, String?>{};

    await Future.wait(unique.map((id) async {
      try {
        final dish = await _dishes.getById(id);
        map[id] = _resolveDishImage(dish);
      } catch (_) {
        map[id] = null;
      }
    }));

    return map;
  }

  static String? _resolveDishImage(Dish dish) {
    return resolveProfileImageUrl(dish.image);
  }
}

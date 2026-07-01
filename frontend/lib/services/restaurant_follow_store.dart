import 'package:shared_preferences/shared_preferences.dart';

/// Persists followed restaurant IDs locally until a dedicated backend endpoint ships.
class RestaurantFollowStore {
  RestaurantFollowStore._();

  static const _key = 'followed_restaurant_ids';

  static Future<Set<int>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    return raw.map(int.tryParse).whereType<int>().toSet();
  }

  static Future<bool> isFollowing(int restaurantId) async {
    final ids = await load();
    return ids.contains(restaurantId);
  }

  static Future<bool> toggle(int restaurantId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await load();
    if (ids.contains(restaurantId)) {
      ids.remove(restaurantId);
    } else {
      ids.add(restaurantId);
    }
    await prefs.setStringList(_key, ids.map((id) => '$id').toList());
    return ids.contains(restaurantId);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<void> replace(Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids.map((id) => '$id').toList());
  }
}

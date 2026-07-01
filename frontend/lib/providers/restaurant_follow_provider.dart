import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../services/api_client.dart';
import '../services/restaurant_follow_service.dart';
import '../services/restaurant_follow_store.dart';

/// Restaurant follow state synced with the backend API.
class RestaurantFollowProvider extends ChangeNotifier {
  RestaurantFollowProvider({RestaurantFollowService? service})
      : _service = service ?? RestaurantFollowService();

  final RestaurantFollowService _service;

  Set<int> _followedIds = {};
  bool loaded = false;

  Set<int> get followedIds => Set.unmodifiable(_followedIds);
  int get followedCount => _followedIds.length;

  bool isFollowing(int restaurantId) => _followedIds.contains(restaurantId);

  void _notify() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      notifyListeners();
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });
  }

  void _applyIds(Iterable<int> ids) {
    _followedIds = ids.toSet();
    loaded = true;
    _notify();
  }

  Future<void> load() async {
    if (!ApiClient.instance.isAuthenticated) {
      _applyIds(await RestaurantFollowStore.load());
      return;
    }

    try {
      final result = await _service.getFollowing().timeout(const Duration(seconds: 20));
      _applyIds(result.restaurantIds);
      await RestaurantFollowStore.replace(_followedIds);
    } catch (_) {
      _applyIds(await RestaurantFollowStore.load());
    }
  }

  Future<void> reset() async {
    _followedIds = {};
    loaded = false;
    await RestaurantFollowStore.clear();
    _notify();
  }

  /// Returns true if now following after toggle.
  Future<bool> toggle(int restaurantId) async {
    final wasFollowing = isFollowing(restaurantId);

    if (ApiClient.instance.isAuthenticated) {
      try {
        final result = wasFollowing
            ? await _service.unfollow(restaurantId)
            : await _service.follow(restaurantId);
        _applyIds(result.restaurantIds);
        await RestaurantFollowStore.replace(_followedIds);
        return !wasFollowing;
      } catch (_) {
        // Fall through to local toggle if API fails.
      }
    }

    final nowFollowing = await RestaurantFollowStore.toggle(restaurantId);
    if (nowFollowing) {
      _followedIds.add(restaurantId);
    } else {
      _followedIds.remove(restaurantId);
    }
    _notify();
    return nowFollowing;
  }
}

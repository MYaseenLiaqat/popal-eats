import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../models/recommendation.dart';
import '../services/api_client.dart';
import '../services/recommendation_service.dart';
import '../utils/recommendation_copy.dart';

/// Shared cache for personalized, trending, and popular recommendations.
///
/// Deduplicates concurrent [fetchAll] calls so Home and Discover share one
/// in-flight request instead of firing duplicate HTTP calls.
class RecommendationProvider extends ChangeNotifier {
  RecommendationProvider({RecommendationService? service})
      : _service = service ?? RecommendationService();

  final RecommendationService _service;

  List<Recommendation> personalized = [];
  List<Recommendation> trending = [];
  List<Recommendation> popular = [];

  bool loadingPersonalized = false;
  bool loadingTrending = false;
  bool loadingPopular = false;

  String? personalizedError;
  String? trendingError;
  String? popularError;

  bool _hasFetched = false;
  Future<void>? _inFlight;

  bool get isLoading =>
      loadingPersonalized || loadingTrending || loadingPopular;

  bool get hasCache => _hasFetched;

  bool get allFailed =>
      personalized.isEmpty &&
      trending.isEmpty &&
      popular.isEmpty &&
      personalizedError != null &&
      trendingError != null &&
      popularError != null;

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

  /// Loads all three recommendation buckets once. Returns cached data when
  /// available unless [force] is true. Concurrent callers share the same Future.
  Future<void> fetchAll({bool force = false}) {
    if (!ApiClient.instance.isAuthenticated) {
      reset();
      return Future.value();
    }

    if (!force && _hasFetched && _inFlight == null) {
      return Future.value();
    }

    if (_inFlight != null && !force) {
      return _inFlight!;
    }

    final future = _fetchAllInternal(force: force);
    _inFlight = future;
    return future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    });
  }

  Future<void> _fetchAllInternal({required bool force}) async {
    if (!force && _hasFetched) return;

    loadingPersonalized = true;
    loadingTrending = true;
    loadingPopular = true;
    if (force) {
      personalizedError = null;
      trendingError = null;
      popularError = null;
    }
    _notify();

    await Future.wait([
      _loadPersonalized(force: force),
      _loadTrending(force: force),
      _loadPopular(force: force),
    ]);

    _hasFetched = true;
    _notify();
  }

  Future<void> _loadPersonalized({required bool force}) async {
    try {
      final list = await _service.list();
      personalized = list;
      personalizedError = null;
    } catch (e) {
      personalizedError = RecommendationCopy.friendlyError(e);
      if (force || personalized.isEmpty) {
        personalized = [];
      }
    } finally {
      loadingPersonalized = false;
      _notify();
    }
  }

  Future<void> _loadTrending({required bool force}) async {
    try {
      final list = await _service.trending(limit: 10);
      trending = list;
      trendingError = null;
    } catch (e) {
      trendingError = RecommendationCopy.friendlyError(e);
      if (force || trending.isEmpty) {
        trending = [];
      }
    } finally {
      loadingTrending = false;
      _notify();
    }
  }

  Future<void> _loadPopular({required bool force}) async {
    try {
      final list = await _service.popular(limit: 10);
      popular = list;
      popularError = null;
    } catch (e) {
      popularError = RecommendationCopy.friendlyError(e);
      if (force || popular.isEmpty) {
        popular = [];
      }
    } finally {
      loadingPopular = false;
      _notify();
    }
  }

  Future<void> refreshPersonalized() => _refreshSingle(
        loader: () => _service.list(),
        onSuccess: (list) {
          personalized = list;
          personalizedError = null;
        },
        onError: (msg) => personalizedError = msg,
        loadingFlag: (v) => loadingPersonalized = v,
      );

  Future<void> refreshTrending() => _refreshSingle(
        loader: () => _service.trending(limit: 10),
        onSuccess: (list) {
          trending = list;
          trendingError = null;
        },
        onError: (msg) => trendingError = msg,
        loadingFlag: (v) => loadingTrending = v,
      );

  Future<void> refreshPopular() => _refreshSingle(
        loader: () => _service.popular(limit: 10),
        onSuccess: (list) {
          popular = list;
          popularError = null;
        },
        onError: (msg) => popularError = msg,
        loadingFlag: (v) => loadingPopular = v,
      );

  Future<void> _refreshSingle({
    required Future<List<Recommendation>> Function() loader,
    required void Function(List<Recommendation> list) onSuccess,
    required void Function(String message) onError,
    required void Function(bool loading) loadingFlag,
  }) async {
    loadingFlag(true);
    _notify();
    try {
      onSuccess(await loader());
    } catch (e) {
      onError(RecommendationCopy.friendlyError(e));
    } finally {
      loadingFlag(false);
      _hasFetched = true;
      _notify();
    }
  }

  void reset() {
    personalized = [];
    trending = [];
    popular = [];
    loadingPersonalized = false;
    loadingTrending = false;
    loadingPopular = false;
    personalizedError = null;
    trendingError = null;
    popularError = null;
    _hasFetched = false;
    _inFlight = null;
    _notify();
  }
}

import 'package:flutter/foundation.dart';

import '../models/post.dart';
import '../models/story.dart';
import '../services/content_service.dart';
import '../utils/post_caption.dart';
import '../utils/recommendation_copy.dart';

/// Cached home feed + stories — refresh on pull-to-refresh or tab revisit only.
class HomeFeedProvider extends ChangeNotifier {
  HomeFeedProvider({ContentService? content}) : _content = content ?? ContentService();

  final ContentService _content;

  List<Post> posts = [];
  List<StoryGroup> storyGroups = [];
  bool loadingFeed = false;
  bool loadingStories = false;
  String? feedError;
  String? storiesError;
  bool _hasLoaded = false;
  Future<void>? _inFlight;

  Future<void> fetch({bool force = false}) {
    if (!force && _hasLoaded && _inFlight == null) {
      return Future.value();
    }
    if (_inFlight != null && !force) {
      return _inFlight!;
    }
    final future = _fetchInternal(force: force);
    _inFlight = future;
    return future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    });
  }

  Future<void> _fetchInternal({required bool force}) async {
    if (!force && _hasLoaded) return;

    loadingFeed = true;
    loadingStories = true;
    if (force) {
      feedError = null;
      storiesError = null;
    }
    notifyListeners();

    try {
      final results = await Future.wait([
        _content.fetchHomeFeed(limit: 30),
        _content.fetchStories(),
      ]);
      posts = _filterAndSort(results[0] as List<Post>);
      storyGroups = results[1] as List<StoryGroup>;
      feedError = null;
      storiesError = null;
      _hasLoaded = true;
    } catch (e) {
      final msg = RecommendationCopy.friendlyError(e);
      feedError = msg;
      storiesError = msg;
      if (force || posts.isEmpty) posts = [];
      if (force || storyGroups.isEmpty) storyGroups = [];
    } finally {
      loadingFeed = false;
      loadingStories = false;
      notifyListeners();
    }
  }

  List<Post> _filterAndSort(List<Post> raw) {
    final filtered = raw.where((p) {
      final captionBlob = '${p.caption ?? ''} ${p.title ?? ''}'.toLowerCase();
      if (captionBlob.contains('fyp_seed')) return false;
      final hasContent = hasVisibleCaption(p.caption) ||
          p.images.isNotEmpty ||
          p.videoUrl != null && p.videoUrl!.trim().isNotEmpty ||
          (p.title?.trim().isNotEmpty ?? false);
      if (!hasContent) return false;
      return p.postType == PostType.foodPost ||
          p.postType == PostType.recipe ||
          p.postType == PostType.chefPost ||
          p.postType == PostType.restaurantPost;
    }).toList();

    int priority(Post p) {
      switch (p.postType) {
        case PostType.foodPost:
          return 0;
        case PostType.restaurantPost:
          return 1;
        case PostType.recipe:
        case PostType.chefPost:
          return 2;
      }
    }

    filtered.sort((a, b) {
      final pa = priority(a);
      final pb = priority(b);
      if (pa != pb) return pa.compareTo(pb);
      final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });
    return filtered;
  }

  void reset() {
    posts = [];
    storyGroups = [];
    loadingFeed = false;
    loadingStories = false;
    feedError = null;
    storiesError = null;
    _hasLoaded = false;
    _inFlight = null;
    notifyListeners();
  }

  void updatePost(Post updated) {
    posts = posts.map((p) => p.id == updated.id ? updated : p).toList();
    notifyListeners();
  }
}

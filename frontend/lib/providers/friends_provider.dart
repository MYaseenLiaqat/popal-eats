import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../models/social_user.dart';
import '../services/api_client.dart';
import '../services/friends_service.dart';
import '../utils/recommendation_copy.dart';

class FriendsProvider extends ChangeNotifier {
  FriendsProvider({FriendsService? service}) : _service = service ?? FriendsService();

  final FriendsService _service;

  List<UserPublicProfile> friends = [];
  List<UserPublicProfile> suggestions = [];
  List<FriendRequest> incomingRequests = [];
  List<FriendRequest> outgoingRequests = [];

  bool loadingFriends = false;
  bool loadingSuggestions = false;
  bool loadingRequests = false;
  bool actionLoading = false;
  String? friendsError;
  String? suggestionsError;
  String? requestsError;
  String? actionError;

  Future<void>? _friendsInFlight;
  Future<void>? _suggestionsInFlight;
  Future<void>? _requestsInFlight;

  int get friendsCount => friends.length;
  int get incomingCount => incomingRequests.length;
  int get outgoingCount => outgoingRequests.length;
  int get pendingRequestsCount => incomingCount + outgoingCount;

  Set<int> get friendIds => friends.map((f) => f.id).toSet();
  Set<int> get outgoingReceiverIds =>
      outgoingRequests.map((r) => r.receiverId).toSet();

  bool isFriend(int userId) => friendIds.contains(userId);
  bool hasOutgoingRequestTo(int userId) => outgoingReceiverIds.contains(userId);

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

  Future<void> reset() async {
    friends = [];
    suggestions = [];
    incomingRequests = [];
    outgoingRequests = [];
    loadingFriends = false;
    loadingSuggestions = false;
    loadingRequests = false;
    actionLoading = false;
    friendsError = null;
    suggestionsError = null;
    requestsError = null;
    actionError = null;
    _friendsInFlight = null;
    _suggestionsInFlight = null;
    _requestsInFlight = null;
    _notify();
  }

  Future<void> fetchAll({bool force = false}) async {
    await Future.wait([
      fetchFriends(force: force),
      fetchRequests(force: force),
      fetchSuggestions(force: force),
    ]);
  }

  Future<void> fetchFriends({bool force = false}) {
    if (!ApiClient.instance.isAuthenticated) {
      return reset();
    }
    if (!force && friends.isNotEmpty && friendsError == null && _friendsInFlight == null) {
      return Future.value();
    }
    if (_friendsInFlight != null && !force) {
      return _friendsInFlight!;
    }

    final future = _fetchFriendsInternal(force: force);
    _friendsInFlight = future;
    return future.whenComplete(() {
      if (identical(_friendsInFlight, future)) {
        _friendsInFlight = null;
      }
    });
  }

  Future<void> _fetchFriendsInternal({required bool force}) async {
    if (!force && friends.isNotEmpty && friendsError == null) return;

    loadingFriends = true;
    friendsError = null;
    _notify();

    try {
      final result = await _service.getFriends().timeout(const Duration(seconds: 20));
      friends = result.friends;
      friendsError = null;
    } on ApiException catch (e) {
      friendsError = RecommendationCopy.friendlyError(e);
    } catch (e) {
      friendsError = RecommendationCopy.friendlyError(e);
    } finally {
      loadingFriends = false;
      _notify();
    }
  }

  Future<void> fetchSuggestions({bool force = false}) {
    if (!ApiClient.instance.isAuthenticated) return Future.value();
    if (!force &&
        suggestions.isNotEmpty &&
        suggestionsError == null &&
        _suggestionsInFlight == null) {
      return Future.value();
    }
    if (_suggestionsInFlight != null && !force) {
      return _suggestionsInFlight!;
    }

    final future = _fetchSuggestionsInternal(force: force);
    _suggestionsInFlight = future;
    return future.whenComplete(() {
      if (identical(_suggestionsInFlight, future)) {
        _suggestionsInFlight = null;
      }
    });
  }

  Future<void> _fetchSuggestionsInternal({required bool force}) async {
    if (!force && suggestions.isNotEmpty && suggestionsError == null) return;

    loadingSuggestions = true;
    suggestionsError = null;
    _notify();

    try {
      final result = await _service.getSuggestions().timeout(const Duration(seconds: 20));
      suggestions = result.results;
      suggestionsError = null;
    } on ApiException catch (e) {
      suggestionsError = RecommendationCopy.friendlyError(e);
    } catch (e) {
      suggestionsError = RecommendationCopy.friendlyError(e);
    } finally {
      loadingSuggestions = false;
      _notify();
    }
  }

  Future<void> fetchRequests({bool force = false}) {
    if (!ApiClient.instance.isAuthenticated) return Future.value();
    if (!force &&
        (incomingRequests.isNotEmpty || outgoingRequests.isNotEmpty) &&
        requestsError == null &&
        _requestsInFlight == null) {
      return Future.value();
    }
    if (_requestsInFlight != null && !force) {
      return _requestsInFlight!;
    }

    final future = _fetchRequestsInternal(force: force);
    _requestsInFlight = future;
    return future.whenComplete(() {
      if (identical(_requestsInFlight, future)) {
        _requestsInFlight = null;
      }
    });
  }

  Future<void> _fetchRequestsInternal({required bool force}) async {
    if (!force &&
        (incomingRequests.isNotEmpty || outgoingRequests.isNotEmpty) &&
        requestsError == null) {
      return;
    }

    loadingRequests = true;
    requestsError = null;
    _notify();

    try {
      final result = await _service.getFriendRequests().timeout(const Duration(seconds: 20));
      incomingRequests = result.incoming;
      outgoingRequests = result.outgoing;
      requestsError = null;
    } on ApiException catch (e) {
      requestsError = RecommendationCopy.friendlyError(e);
    } catch (e) {
      requestsError = RecommendationCopy.friendlyError(e);
    } finally {
      loadingRequests = false;
      _notify();
    }
  }

  Future<bool> sendRequest(int receiverId) async {
    actionLoading = true;
    actionError = null;
    _notify();

    try {
      final request = await _service.sendFriendRequest(receiverId);
      outgoingRequests = [...outgoingRequests, request];
      return true;
    } on ApiException catch (e) {
      actionError = RecommendationCopy.friendlyError(e);
      return false;
    } catch (e) {
      actionError = RecommendationCopy.friendlyError(e);
      return false;
    } finally {
      actionLoading = false;
      _notify();
    }
  }

  Future<bool> acceptRequest(int requestId) async {
    actionLoading = true;
    actionError = null;
    _notify();

    try {
      final accepted = await _service.acceptFriendRequest(requestId);
      incomingRequests = incomingRequests.where((r) => r.id != requestId).toList();
      final profile = accepted.sender ?? accepted.receiver;
      if (profile != null && !friendIds.contains(profile.id)) {
        friends = [...friends, profile];
      } else {
        await fetchFriends(force: true);
      }
      return true;
    } on ApiException catch (e) {
      actionError = RecommendationCopy.friendlyError(e);
      return false;
    } catch (e) {
      actionError = RecommendationCopy.friendlyError(e);
      return false;
    } finally {
      actionLoading = false;
      _notify();
    }
  }

  Future<bool> rejectRequest(int requestId) async {
    actionLoading = true;
    actionError = null;
    _notify();

    try {
      await _service.rejectFriendRequest(requestId);
      incomingRequests = incomingRequests.where((r) => r.id != requestId).toList();
      return true;
    } on ApiException catch (e) {
      actionError = RecommendationCopy.friendlyError(e);
      return false;
    } catch (e) {
      actionError = RecommendationCopy.friendlyError(e);
      return false;
    } finally {
      actionLoading = false;
      _notify();
    }
  }

  Future<bool> cancelRequest(int requestId) async {
    actionLoading = true;
    actionError = null;
    _notify();

    try {
      await _service.cancelFriendRequest(requestId);
      outgoingRequests = outgoingRequests.where((r) => r.id != requestId).toList();
      return true;
    } on ApiException catch (e) {
      actionError = RecommendationCopy.friendlyError(e);
      return false;
    } catch (e) {
      actionError = RecommendationCopy.friendlyError(e);
      return false;
    } finally {
      actionLoading = false;
      _notify();
    }
  }

  Future<bool> removeFriend(int friendId) async {
    actionLoading = true;
    actionError = null;
    _notify();

    try {
      await _service.removeFriend(friendId);
      friends = friends.where((f) => f.id != friendId).toList();
      return true;
    } on ApiException catch (e) {
      actionError = RecommendationCopy.friendlyError(e);
      return false;
    } finally {
      actionLoading = false;
      _notify();
    }
  }
}

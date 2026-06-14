import 'package:flutter/foundation.dart';

import '../models/social_user.dart';
import '../services/api_client.dart';
import '../services/friends_service.dart';

class FriendsProvider extends ChangeNotifier {
  FriendsProvider({FriendsService? service}) : _service = service ?? FriendsService();

  final FriendsService _service;

  List<UserPublicProfile> friends = [];
  List<FriendRequest> incomingRequests = [];
  List<FriendRequest> outgoingRequests = [];

  bool loadingFriends = false;
  bool loadingRequests = false;
  bool actionLoading = false;
  String? friendsError;
  String? requestsError;
  String? actionError;

  int get friendsCount => friends.length;
  int get incomingCount => incomingRequests.length;
  int get outgoingCount => outgoingRequests.length;
  int get pendingRequestsCount => incomingCount + outgoingCount;

  Set<int> get friendIds => friends.map((f) => f.id).toSet();
  Set<int> get outgoingReceiverIds =>
      outgoingRequests.map((r) => r.receiverId).toSet();

  bool isFriend(int userId) => friendIds.contains(userId);
  bool hasOutgoingRequestTo(int userId) => outgoingReceiverIds.contains(userId);

  Future<void> reset() async {
    friends = [];
    incomingRequests = [];
    outgoingRequests = [];
    loadingFriends = false;
    loadingRequests = false;
    actionLoading = false;
    friendsError = null;
    requestsError = null;
    actionError = null;
    notifyListeners();
  }

  Future<void> fetchAll({bool force = false}) async {
    await Future.wait([
      fetchFriends(force: force),
      fetchRequests(force: force),
    ]);
  }

  Future<void> fetchFriends({bool force = false}) async {
    if (!ApiClient.instance.isAuthenticated) {
      await reset();
      return;
    }
    if (loadingFriends) return;
    if (!force && friends.isNotEmpty && friendsError == null) return;

    loadingFriends = true;
    friendsError = null;
    notifyListeners();

    try {
      final result = await _service.getFriends();
      friends = result.friends;
    } on ApiException catch (e) {
      friendsError = e.message;
    } finally {
      loadingFriends = false;
      notifyListeners();
    }
  }

  Future<void> fetchRequests({bool force = false}) async {
    if (!ApiClient.instance.isAuthenticated) return;
    if (loadingRequests) return;
    if (!force &&
        (incomingRequests.isNotEmpty || outgoingRequests.isNotEmpty) &&
        requestsError == null) {
      return;
    }

    loadingRequests = true;
    requestsError = null;
    notifyListeners();

    try {
      final result = await _service.getFriendRequests();
      incomingRequests = result.incoming;
      outgoingRequests = result.outgoing;
    } on ApiException catch (e) {
      requestsError = e.message;
    } finally {
      loadingRequests = false;
      notifyListeners();
    }
  }

  Future<bool> sendRequest(int receiverId) async {
    actionLoading = true;
    actionError = null;
    notifyListeners();

    try {
      final request = await _service.sendFriendRequest(receiverId);
      outgoingRequests = [...outgoingRequests, request];
      return true;
    } on ApiException catch (e) {
      actionError = e.message;
      return false;
    } finally {
      actionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptRequest(int requestId) async {
    actionLoading = true;
    actionError = null;
    notifyListeners();

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
      actionError = e.message;
      return false;
    } finally {
      actionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> rejectRequest(int requestId) async {
    actionLoading = true;
    actionError = null;
    notifyListeners();

    try {
      await _service.rejectFriendRequest(requestId);
      incomingRequests = incomingRequests.where((r) => r.id != requestId).toList();
      return true;
    } on ApiException catch (e) {
      actionError = e.message;
      return false;
    } finally {
      actionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removeFriend(int friendId) async {
    actionLoading = true;
    actionError = null;
    notifyListeners();

    try {
      await _service.removeFriend(friendId);
      friends = friends.where((f) => f.id != friendId).toList();
      return true;
    } on ApiException catch (e) {
      actionError = e.message;
      return false;
    } finally {
      actionLoading = false;
      notifyListeners();
    }
  }
}

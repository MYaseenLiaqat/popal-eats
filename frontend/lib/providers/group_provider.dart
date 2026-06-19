import 'package:flutter/foundation.dart';

import '../models/group_decision.dart';
import '../models/group_member_location.dart';
import '../models/group_recommendation.dart';
import '../models/group_session.dart';
import '../models/group_vote.dart';
import '../services/api_client.dart';
import '../services/device_location_service.dart';
import '../services/dish_service.dart';
import '../services/group_service.dart';

class GroupProvider extends ChangeNotifier {
  GroupProvider({
    GroupService? service,
    DeviceLocationService? locationService,
  })  : _service = service ?? GroupService(),
        _locationService = locationService ?? DeviceLocationService();

  final GroupService _service;
  final DeviceLocationService _locationService;

  List<GroupSession> groups = [];
  GroupSession? selectedGroup;
  List<GroupInvitation> incomingInvitations = [];
  List<GroupInvitation> outgoingInvitations = [];
  List<GroupMemberLocation> memberLocations = [];
  int? locationsSessionId;
  GroupRecommendationsResult? groupRecommendations;
  int? recommendationsSessionId;
  GroupDecision? groupDecision;
  int? decisionSessionId;
  final Map<int, GroupVoteSummary> voteSummaries = {};
  final Map<int, String> userVotesByRecommendationId = {};
  final Map<int, String> pendingVotesByRecommendationId = {};
  final Set<int> votingRecommendationIds = {};

  bool loadingGroups = false;
  bool loadingDetail = false;
  bool loadingInvitations = false;
  bool loadingLocations = false;
  bool loadingRecommendations = false;
  bool loadingDecision = false;
  bool loadingVoteSummaries = false;
  bool sharingLocation = false;
  bool actionLoading = false;
  bool orderingDecision = false;

  String? groupsError;
  String? detailError;
  String? invitationsError;
  String? locationsError;
  String? recommendationsError;
  String? decisionError;
  String? voteError;
  String? actionError;
  String? locationActionError;

  int get groupCount => groups.length;
  int get incomingInvitationCount => incomingInvitations.length;
  int get outgoingInvitationCount => outgoingInvitations.length;

  Future<void> reset() async {
    groups = [];
    selectedGroup = null;
    incomingInvitations = [];
    outgoingInvitations = [];
    memberLocations = [];
    locationsSessionId = null;
    groupRecommendations = null;
    recommendationsSessionId = null;
    groupDecision = null;
    decisionSessionId = null;
    voteSummaries.clear();
    userVotesByRecommendationId.clear();
    pendingVotesByRecommendationId.clear();
    votingRecommendationIds.clear();
    loadingGroups = false;
    loadingDetail = false;
    loadingInvitations = false;
    loadingLocations = false;
    loadingRecommendations = false;
    loadingDecision = false;
    loadingVoteSummaries = false;
    sharingLocation = false;
    actionLoading = false;
    orderingDecision = false;
    groupsError = null;
    detailError = null;
    invitationsError = null;
    locationsError = null;
    recommendationsError = null;
    decisionError = null;
    voteError = null;
    actionError = null;
    locationActionError = null;
    notifyListeners();
  }

  Future<void> fetchAll({bool force = false}) async {
    await Future.wait([
      fetchGroups(force: force),
      fetchInvitations(force: force),
    ]);
  }

  Future<void> fetchGroups({bool force = false}) async {
    if (!ApiClient.instance.isAuthenticated) {
      await reset();
      return;
    }
    if (loadingGroups) return;
    if (!force && groups.isNotEmpty && groupsError == null) return;

    loadingGroups = true;
    groupsError = null;
    notifyListeners();

    try {
      final result = await _service.getGroups();
      groups = result.groups;
    } on ApiException catch (e) {
      groupsError = e.message;
    } finally {
      loadingGroups = false;
      notifyListeners();
    }
  }

  Future<void> fetchGroupDetail(int sessionId, {bool force = false}) async {
    if (loadingDetail) return;
    if (!force && selectedGroup?.id == sessionId && detailError == null) return;

    loadingDetail = true;
    detailError = null;
    notifyListeners();

    try {
      selectedGroup = await _service.getGroup(sessionId);
    } on ApiException catch (e) {
      detailError = e.message;
    } finally {
      loadingDetail = false;
      notifyListeners();
    }
  }

  Future<void> loadLocations(int sessionId, {bool force = false}) async {
    if (loadingLocations) return;
    if (!force &&
        locationsSessionId == sessionId &&
        memberLocations.isNotEmpty &&
        locationsError == null) {
      return;
    }

    loadingLocations = true;
    locationsError = null;
    notifyListeners();

    try {
      final result = await _service.getGroupLocations(sessionId);
      memberLocations = result.locations;
      locationsSessionId = sessionId;
    } on ApiException catch (e) {
      locationsError = e.message;
    } finally {
      loadingLocations = false;
      notifyListeners();
    }
  }

  Future<bool> shareLocation({
    required int sessionId,
    required double latitude,
    required double longitude,
  }) async {
    sharingLocation = true;
    locationActionError = null;
    notifyListeners();

    try {
      final saved = await _service.shareGroupLocation(
        sessionId: sessionId,
        latitude: latitude,
        longitude: longitude,
      );
      locationsSessionId = sessionId;
      memberLocations = [
        saved,
        ...memberLocations.where((loc) => loc.userId != saved.userId),
      ];
      return true;
    } on ApiException catch (e) {
      locationActionError = e.message;
      return false;
    } finally {
      sharingLocation = false;
      notifyListeners();
    }
  }

  Future<bool> shareMyLocation(int sessionId) async {
    sharingLocation = true;
    locationActionError = null;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentPosition();
      final saved = await _service.shareGroupLocation(
        sessionId: sessionId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      locationsSessionId = sessionId;
      memberLocations = [
        saved,
        ...memberLocations.where((loc) => loc.userId != saved.userId),
      ];
      return true;
    } on LocationAccessException catch (e) {
      locationActionError = e.message;
      return false;
    } on ApiException catch (e) {
      locationActionError = e.message;
      return false;
    } finally {
      sharingLocation = false;
      notifyListeners();
    }
  }

  DeviceLocationService get locationService => _locationService;

  Future<void> loadRecommendations(
    int sessionId, {
    bool force = false,
    bool refresh = false,
  }) async {
    if (loadingRecommendations) return;
    if (!force &&
        !refresh &&
        recommendationsSessionId == sessionId &&
        groupRecommendations != null &&
        recommendationsError == null) {
      return;
    }

    loadingRecommendations = true;
    recommendationsError = null;
    notifyListeners();

    try {
      final result = await _service.getGroupRecommendations(
        sessionId,
        refresh: refresh,
      );
      final enriched = await _enrichRecommendationsWithImages(result.recommendations);
      groupRecommendations = GroupRecommendationsResult(
        groupId: result.groupId,
        memberCount: result.memberCount,
        groupLatitude: result.groupLatitude,
        groupLongitude: result.groupLongitude,
        recommendations: enriched,
      );
      recommendationsSessionId = sessionId;
      await Future.wait([
        loadDecision(sessionId, force: true),
        loadVoteSummariesForRecommendations(enriched),
      ]);
    } on ApiException catch (e) {
      recommendationsError = e.message;
    } finally {
      loadingRecommendations = false;
      notifyListeners();
    }
  }

  Future<List<GroupDishRecommendation>> _enrichRecommendationsWithImages(
    List<GroupDishRecommendation> items,
  ) async {
    final dishService = DishService();
    return Future.wait(
      items.map((item) async {
        try {
          final dish = await dishService.getById(item.dishId);
          if (dish.image == null || dish.image!.isEmpty) return item;
          return item.copyWith(dishImageUrl: dish.image);
        } catch (_) {
          return item;
        }
      }),
    );
  }

  GroupVoteSummary? voteSummaryFor(int recommendationId) => voteSummaries[recommendationId];

  String? userVoteFor(int recommendationId) => userVotesByRecommendationId[recommendationId];

  bool isVotingOn(int recommendationId) => votingRecommendationIds.contains(recommendationId);

  Future<void> loadVoteSummary(int recommendationId) async {
    try {
      final summary = await _service.getVoteSummary(recommendationId);
      voteSummaries[recommendationId] = summary;
      voteError = null;
    } on ApiException catch (e) {
      voteError = e.message;
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadVoteSummariesForRecommendations(
    List<GroupDishRecommendation> items,
  ) async {
    final ids = items.map((item) => item.recommendationId).whereType<int>().toList();
    if (ids.isEmpty) return;

    loadingVoteSummaries = true;
    voteError = null;
    notifyListeners();

    try {
      final results = await Future.wait(
        ids.map((id) async {
          try {
            final summary = await _service.getVoteSummary(id);
            return MapEntry(id, summary);
          } catch (_) {
            return null;
          }
        }),
      );
      for (final entry in results) {
        if (entry != null) voteSummaries[entry.key] = entry.value;
      }
    } finally {
      loadingVoteSummaries = false;
      notifyListeners();
    }
  }

  String? pendingVoteFor(int recommendationId) => pendingVotesByRecommendationId[recommendationId];

  Future<bool> voteOnRecommendation({
    required int recommendationId,
    required String voteType,
    int? sessionId,
  }) async {
    votingRecommendationIds.add(recommendationId);
    pendingVotesByRecommendationId[recommendationId] = voteType;
    voteError = null;
    notifyListeners();

    try {
      final vote = await _service.voteOnRecommendation(
        recommendationId: recommendationId,
        voteType: voteType,
      );
      userVotesByRecommendationId[recommendationId] = vote.voteType;
      await loadVoteSummary(recommendationId);
      if (sessionId != null) {
        await loadDecision(sessionId, force: true);
      }
      _syncRecommendationScores(recommendationId);
      return true;
    } on ApiException catch (e) {
      voteError = e.message;
      return false;
    } finally {
      votingRecommendationIds.remove(recommendationId);
      pendingVotesByRecommendationId.remove(recommendationId);
      notifyListeners();
    }
  }

  void _syncRecommendationScores(int recommendationId) {
    final summary = voteSummaries[recommendationId];
    if (summary == null || groupRecommendations == null) return;

    final updated = groupRecommendations!.recommendations.map((item) {
      if (item.recommendationId != recommendationId) return item;
      return GroupDishRecommendation(
        recommendationId: item.recommendationId,
        dishId: item.dishId,
        dishName: item.dishName,
        restaurantName: item.restaurantName,
        price: item.price,
        score: item.score,
        consensusScore: summary.consensusScore,
        finalScore: summary.finalScore,
        reasons: item.reasons,
        dishImageUrl: item.dishImageUrl,
      );
    }).toList()
      ..sort((a, b) => b.displayScore.compareTo(a.displayScore));

    groupRecommendations = GroupRecommendationsResult(
      groupId: groupRecommendations!.groupId,
      memberCount: groupRecommendations!.memberCount,
      groupLatitude: groupRecommendations!.groupLatitude,
      groupLongitude: groupRecommendations!.groupLongitude,
      recommendations: updated,
    );
  }

  Future<void> loadDecision(int sessionId, {bool force = false}) async {
    if (loadingDecision) return;
    if (!force && decisionSessionId == sessionId && groupDecision != null && decisionError == null) {
      return;
    }

    loadingDecision = true;
    decisionError = null;
    notifyListeners();

    try {
      groupDecision = await _service.getDecision(sessionId);
      decisionSessionId = sessionId;
    } on ApiException catch (e) {
      decisionError = e.message;
    } finally {
      loadingDecision = false;
      notifyListeners();
    }
  }

  Future<bool> markDecisionOrdered(int sessionId) async {
    orderingDecision = true;
    decisionError = null;
    notifyListeners();

    try {
      groupDecision = await _service.markDecisionOrdered(sessionId);
      decisionSessionId = sessionId;
      return true;
    } on ApiException catch (e) {
      decisionError = e.message;
      return false;
    } finally {
      orderingDecision = false;
      notifyListeners();
    }
  }

  Future<void> fetchInvitations({bool force = false}) async {
    if (!ApiClient.instance.isAuthenticated) return;
    if (loadingInvitations) return;
    if (!force &&
        (incomingInvitations.isNotEmpty || outgoingInvitations.isNotEmpty) &&
        invitationsError == null) {
      return;
    }

    loadingInvitations = true;
    invitationsError = null;
    notifyListeners();

    try {
      final result = await _service.getInvitations();
      incomingInvitations = result.incoming;
      outgoingInvitations = result.outgoing;
    } on ApiException catch (e) {
      invitationsError = e.message;
    } finally {
      loadingInvitations = false;
      notifyListeners();
    }
  }

  Future<GroupSession?> createGroup(String name) async {
    actionLoading = true;
    actionError = null;
    notifyListeners();

    try {
      final session = await _service.createGroup(name: name);
      groups = [session, ...groups.where((g) => g.id != session.id)];
      selectedGroup = session;
      return session;
    } on ApiException catch (e) {
      actionError = e.message;
      return null;
    } finally {
      actionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> inviteFriend({
    required int sessionId,
    required int receiverId,
  }) async {
    actionLoading = true;
    actionError = null;
    notifyListeners();

    try {
      final invitation = await _service.inviteToGroup(
        sessionId: sessionId,
        receiverId: receiverId,
      );
      outgoingInvitations = [...outgoingInvitations, invitation];
      return true;
    } on ApiException catch (e) {
      actionError = e.message;
      return false;
    } finally {
      actionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptInvitation(int invitationId) async {
    actionLoading = true;
    actionError = null;
    notifyListeners();

    try {
      final accepted = await _service.acceptInvitation(invitationId);
      incomingInvitations =
          incomingInvitations.where((i) => i.id != invitationId).toList();
      await fetchGroups(force: true);
      if (accepted.sessionId > 0) {
        await fetchGroupDetail(accepted.sessionId, force: true);
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

  Future<bool> rejectInvitation(int invitationId) async {
    actionLoading = true;
    actionError = null;
    notifyListeners();

    try {
      await _service.rejectInvitation(invitationId);
      incomingInvitations =
          incomingInvitations.where((i) => i.id != invitationId).toList();
      return true;
    } on ApiException catch (e) {
      actionError = e.message;
      return false;
    } finally {
      actionLoading = false;
      notifyListeners();
    }
  }

  void clearSelectedGroup() {
    selectedGroup = null;
    detailError = null;
    memberLocations = [];
    locationsSessionId = null;
    groupRecommendations = null;
    recommendationsSessionId = null;
    groupDecision = null;
    decisionSessionId = null;
    voteSummaries.clear();
    userVotesByRecommendationId.clear();
    pendingVotesByRecommendationId.clear();
    votingRecommendationIds.clear();
    locationsError = null;
    recommendationsError = null;
    decisionError = null;
    voteError = null;
    locationActionError = null;
    notifyListeners();
  }
}

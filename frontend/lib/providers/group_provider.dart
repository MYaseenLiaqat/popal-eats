import 'package:flutter/foundation.dart';

import '../models/group_member_location.dart';
import '../models/group_recommendation.dart';
import '../models/group_session.dart';
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

  bool loadingGroups = false;
  bool loadingDetail = false;
  bool loadingInvitations = false;
  bool loadingLocations = false;
  bool loadingRecommendations = false;
  bool sharingLocation = false;
  bool actionLoading = false;

  String? groupsError;
  String? detailError;
  String? invitationsError;
  String? locationsError;
  String? recommendationsError;
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
    loadingGroups = false;
    loadingDetail = false;
    loadingInvitations = false;
    loadingLocations = false;
    loadingRecommendations = false;
    sharingLocation = false;
    actionLoading = false;
    groupsError = null;
    detailError = null;
    invitationsError = null;
    locationsError = null;
    recommendationsError = null;
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

  Future<void> loadRecommendations(int sessionId, {bool force = false}) async {
    if (loadingRecommendations) return;
    if (!force &&
        recommendationsSessionId == sessionId &&
        groupRecommendations != null &&
        recommendationsError == null) {
      return;
    }

    loadingRecommendations = true;
    recommendationsError = null;
    notifyListeners();

    try {
      final result = await _service.getGroupRecommendations(sessionId);
      final enriched = await _enrichRecommendationsWithImages(result.recommendations);
      groupRecommendations = GroupRecommendationsResult(
        groupId: result.groupId,
        memberCount: result.memberCount,
        groupLatitude: result.groupLatitude,
        groupLongitude: result.groupLongitude,
        recommendations: enriched,
      );
      recommendationsSessionId = sessionId;
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
    locationsError = null;
    recommendationsError = null;
    locationActionError = null;
    notifyListeners();
  }
}

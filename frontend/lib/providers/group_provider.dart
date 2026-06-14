import 'package:flutter/foundation.dart';

import '../models/group_session.dart';
import '../services/api_client.dart';
import '../services/group_service.dart';

class GroupProvider extends ChangeNotifier {
  GroupProvider({GroupService? service}) : _service = service ?? GroupService();

  final GroupService _service;

  List<GroupSession> groups = [];
  GroupSession? selectedGroup;
  List<GroupInvitation> incomingInvitations = [];
  List<GroupInvitation> outgoingInvitations = [];

  bool loadingGroups = false;
  bool loadingDetail = false;
  bool loadingInvitations = false;
  bool actionLoading = false;

  String? groupsError;
  String? detailError;
  String? invitationsError;
  String? actionError;

  int get groupCount => groups.length;
  int get incomingInvitationCount => incomingInvitations.length;
  int get outgoingInvitationCount => outgoingInvitations.length;

  Future<void> reset() async {
    groups = [];
    selectedGroup = null;
    incomingInvitations = [];
    outgoingInvitations = [];
    loadingGroups = false;
    loadingDetail = false;
    loadingInvitations = false;
    actionLoading = false;
    groupsError = null;
    detailError = null;
    invitationsError = null;
    actionError = null;
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
    notifyListeners();
  }
}

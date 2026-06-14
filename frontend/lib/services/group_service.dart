import 'api_client.dart';
import '../models/group_decision.dart';
import '../models/group_member_location.dart';
import '../models/group_recommendation.dart';
import '../models/group_session.dart';
import '../models/group_vote.dart';

class GroupService {
  GroupService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<GroupSessionList> getGroups() async {
    final response = await _client.get('/groups');
    _client.throwIfError(response);
    return GroupSessionList.fromJson(_client.decodeJson(response));
  }

  Future<GroupSession> getGroup(int sessionId) async {
    final response = await _client.get('/groups/$sessionId');
    _client.throwIfError(response);
    return GroupSession.fromJson(_client.decodeJson(response));
  }

  Future<GroupSession> createGroup({required String name}) async {
    final response = await _client.post('/groups', body: {'name': name.trim()});
    _client.throwIfError(response);
    return GroupSession.fromJson(_client.decodeJson(response));
  }

  Future<GroupInvitationsList> getInvitations() async {
    final response = await _client.get('/groups/invitations');
    _client.throwIfError(response);
    return GroupInvitationsList.fromJson(_client.decodeJson(response));
  }

  Future<GroupInvitation> inviteToGroup({
    required int sessionId,
    required int receiverId,
  }) async {
    final response = await _client.post(
      '/groups/$sessionId/invite',
      body: {'receiver_id': receiverId},
    );
    _client.throwIfError(response);
    return GroupInvitation.fromJson(_client.decodeJson(response));
  }

  Future<GroupInvitation> acceptInvitation(int invitationId) async {
    final response = await _client.post('/groups/invitations/$invitationId/accept');
    _client.throwIfError(response);
    return GroupInvitation.fromJson(_client.decodeJson(response));
  }

  Future<GroupInvitation> rejectInvitation(int invitationId) async {
    final response = await _client.post('/groups/invitations/$invitationId/reject');
    _client.throwIfError(response);
    return GroupInvitation.fromJson(_client.decodeJson(response));
  }

  Future<void> leaveGroup(int sessionId) async {
    final response = await _client.post('/groups/$sessionId/leave');
    _client.throwIfError(response);
  }

  Future<GroupMemberLocationList> getGroupLocations(int sessionId) async {
    final response = await _client.get('/groups/$sessionId/location');
    _client.throwIfError(response);
    return GroupMemberLocationList.fromJson(_client.decodeJson(response));
  }

  Future<GroupMemberLocation> shareGroupLocation({
    required int sessionId,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _client.post(
      '/groups/$sessionId/location',
      body: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    _client.throwIfError(response);
    return GroupMemberLocation.fromJson(_client.decodeJson(response));
  }

  Future<GroupRecommendationsResult> getGroupRecommendations(int sessionId) async {
    final response = await _client.get('/groups/$sessionId/recommendations');
    _client.throwIfError(response);
    return GroupRecommendationsResult.fromJson(_client.decodeJson(response));
  }

  Future<GroupVote> voteOnRecommendation({
    required int recommendationId,
    required String voteType,
  }) async {
    final response = await _client.post(
      '/groups/recommendations/$recommendationId/vote',
      body: {'vote_type': voteType},
    );
    _client.throwIfError(response);
    return GroupVote.fromJson(_client.decodeJson(response));
  }

  Future<GroupVoteSummary> getVoteSummary(int recommendationId) async {
    final response = await _client.get('/groups/recommendations/$recommendationId/votes');
    _client.throwIfError(response);
    return GroupVoteSummary.fromJson(_client.decodeJson(response));
  }

  Future<GroupDecision> getDecision(int sessionId) async {
    final response = await _client.get('/groups/$sessionId/decision');
    _client.throwIfError(response);
    return GroupDecision.fromJson(_client.decodeJson(response));
  }

  Future<GroupDecision> markDecisionOrdered(int sessionId) async {
    final response = await _client.post('/groups/$sessionId/decision/ordered');
    _client.throwIfError(response);
    return GroupDecision.fromJson(_client.decodeJson(response));
  }
}

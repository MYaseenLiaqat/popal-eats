import 'api_client.dart';
import '../models/group_session.dart';

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
}

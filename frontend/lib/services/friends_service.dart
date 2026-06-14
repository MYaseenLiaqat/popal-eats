import 'api_client.dart';
import '../models/social_user.dart';

class FriendsService {
  FriendsService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<FriendsList> getFriends() async {
    final response = await _client.get('/friends');
    _client.throwIfError(response);
    return FriendsList.fromJson(_client.decodeJson(response));
  }

  Future<FriendRequestsList> getFriendRequests() async {
    final response = await _client.get('/friends/requests');
    _client.throwIfError(response);
    return FriendRequestsList.fromJson(_client.decodeJson(response));
  }

  Future<FriendRequest> sendFriendRequest(int receiverId) async {
    final response = await _client.post(
      '/friends/request',
      body: {'receiver_id': receiverId},
    );
    _client.throwIfError(response);
    return FriendRequest.fromJson(_client.decodeJson(response));
  }

  Future<FriendRequest> acceptFriendRequest(int requestId) async {
    final response = await _client.post('/friends/request/$requestId/accept');
    _client.throwIfError(response);
    return FriendRequest.fromJson(_client.decodeJson(response));
  }

  Future<FriendRequest> rejectFriendRequest(int requestId) async {
    final response = await _client.post('/friends/request/$requestId/reject');
    _client.throwIfError(response);
    return FriendRequest.fromJson(_client.decodeJson(response));
  }

  Future<void> removeFriend(int friendId) async {
    final response = await _client.delete('/friends/$friendId');
    _client.throwIfError(response);
  }

  Future<UserSearchResults> searchUsers(String query) async {
    final response = await _client.get(
      '/users/search',
      query: {'q': query.trim()},
    );
    _client.throwIfError(response);
    return UserSearchResults.fromJson(_client.decodeJson(response));
  }
}

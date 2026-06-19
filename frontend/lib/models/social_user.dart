class UserPublicProfile {
  const UserPublicProfile({
    required this.id,
    required this.fullName,
    this.username,
    this.bio,
    this.profileImage,
  });

  final int id;
  final String fullName;
  final String? username;
  final String? bio;
  final String? profileImage;

  String get displayHandle {
    if (username != null && username!.trim().isNotEmpty) {
      final u = username!.trim().toLowerCase();
      return u.startsWith('@') ? u : '@$u';
    }
    return '@user$id';
  }

  factory UserPublicProfile.fromJson(Map<String, dynamic> json) {
    return UserPublicProfile(
      id: json['id'] as int? ?? int.tryParse('${json['id']}') ?? 0,
      fullName: json['full_name']?.toString() ?? '',
      username: json['username']?.toString(),
      bio: json['bio']?.toString(),
      profileImage: json['profile_image']?.toString(),
    );
  }
}

class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    this.sender,
    this.receiver,
  });

  final int id;
  final int senderId;
  final int receiverId;
  final String status;
  final UserPublicProfile? sender;
  final UserPublicProfile? receiver;

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as int? ?? int.tryParse('${json['id']}') ?? 0,
      senderId: json['sender_id'] as int? ?? 0,
      receiverId: json['receiver_id'] as int? ?? 0,
      status: json['status']?.toString() ?? 'pending',
      sender: json['sender'] is Map
          ? UserPublicProfile.fromJson(Map<String, dynamic>.from(json['sender'] as Map))
          : null,
      receiver: json['receiver'] is Map
          ? UserPublicProfile.fromJson(Map<String, dynamic>.from(json['receiver'] as Map))
          : null,
    );
  }
}

class FriendRequestsList {
  const FriendRequestsList({
    required this.incoming,
    required this.outgoing,
  });

  final List<FriendRequest> incoming;
  final List<FriendRequest> outgoing;

  factory FriendRequestsList.fromJson(Map<String, dynamic> json) {
    List<FriendRequest> parseList(dynamic value) {
      if (value is! List) return [];
      return value
          .whereType<Map>()
          .map((e) => FriendRequest.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return FriendRequestsList(
      incoming: parseList(json['incoming']),
      outgoing: parseList(json['outgoing']),
    );
  }
}

class FriendsList {
  const FriendsList({required this.friends});

  final List<UserPublicProfile> friends;

  factory FriendsList.fromJson(Map<String, dynamic> json) {
    final raw = json['friends'];
    if (raw is! List) return const FriendsList(friends: []);
    return FriendsList(
      friends: raw
          .whereType<Map>()
          .map((e) => UserPublicProfile.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class UserSearchResults {
  const UserSearchResults({required this.results});

  final List<UserPublicProfile> results;

  factory UserSearchResults.fromJson(Map<String, dynamic> json) {
    final raw = json['results'];
    if (raw is! List) return const UserSearchResults(results: []);
    return UserSearchResults(
      results: raw
          .whereType<Map>()
          .map((e) => UserPublicProfile.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

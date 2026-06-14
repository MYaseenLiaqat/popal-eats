import '../models/social_user.dart';

class GroupSessionMember {
  const GroupSessionMember({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.joinedAt,
    this.user,
  });

  final int id;
  final int sessionId;
  final int userId;
  final DateTime joinedAt;
  final UserPublicProfile? user;

  factory GroupSessionMember.fromJson(Map<String, dynamic> json) {
    return GroupSessionMember(
      id: json['id'] as int? ?? 0,
      sessionId: json['session_id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      joinedAt: DateTime.tryParse(json['joined_at']?.toString() ?? '') ?? DateTime.now(),
      user: json['user'] is Map
          ? UserPublicProfile.fromJson(Map<String, dynamic>.from(json['user'] as Map))
          : null,
    );
  }
}

class GroupSession {
  const GroupSession({
    required this.id,
    required this.name,
    required this.hostUserId,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.host,
    this.members = const [],
  });

  final int id;
  final String name;
  final int hostUserId;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final UserPublicProfile? host;
  final List<GroupSessionMember> members;

  int get memberCount => members.length;
  bool get isActive => status.toLowerCase() == 'active';

  factory GroupSession.fromJson(Map<String, dynamic> json) {
    final membersRaw = json['members'];
    return GroupSession(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      hostUserId: json['host_user_id'] as int? ?? 0,
      status: json['status']?.toString() ?? 'active',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? '') ?? DateTime.now(),
      host: json['host'] is Map
          ? UserPublicProfile.fromJson(Map<String, dynamic>.from(json['host'] as Map))
          : null,
      members: membersRaw is List
          ? membersRaw
              .whereType<Map>()
              .map((e) => GroupSessionMember.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [],
    );
  }
}

class GroupInvitation {
  const GroupInvitation({
    required this.id,
    required this.sessionId,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.sender,
    this.receiver,
    this.sessionName,
    this.sessionHost,
  });

  final int id;
  final int sessionId;
  final int senderId;
  final int receiverId;
  final String status;
  final DateTime createdAt;
  final UserPublicProfile? sender;
  final UserPublicProfile? receiver;
  final String? sessionName;
  final UserPublicProfile? sessionHost;

  factory GroupInvitation.fromJson(Map<String, dynamic> json) {
    return GroupInvitation(
      id: json['id'] as int? ?? 0,
      sessionId: json['session_id'] as int? ?? 0,
      senderId: json['sender_id'] as int? ?? 0,
      receiverId: json['receiver_id'] as int? ?? 0,
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      sender: json['sender'] is Map
          ? UserPublicProfile.fromJson(Map<String, dynamic>.from(json['sender'] as Map))
          : null,
      receiver: json['receiver'] is Map
          ? UserPublicProfile.fromJson(Map<String, dynamic>.from(json['receiver'] as Map))
          : null,
      sessionName: json['session_name']?.toString(),
      sessionHost: json['session_host'] is Map
          ? UserPublicProfile.fromJson(Map<String, dynamic>.from(json['session_host'] as Map))
          : null,
    );
  }
}

class GroupInvitationsList {
  const GroupInvitationsList({
    required this.incoming,
    required this.outgoing,
  });

  final List<GroupInvitation> incoming;
  final List<GroupInvitation> outgoing;

  factory GroupInvitationsList.fromJson(Map<String, dynamic> json) {
    List<GroupInvitation> parseList(dynamic value) {
      if (value is! List) return [];
      return value
          .whereType<Map>()
          .map((e) => GroupInvitation.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return GroupInvitationsList(
      incoming: parseList(json['incoming']),
      outgoing: parseList(json['outgoing']),
    );
  }
}

class GroupSessionList {
  const GroupSessionList({required this.groups});

  final List<GroupSession> groups;

  factory GroupSessionList.fromJson(Map<String, dynamic> json) {
    final raw = json['groups'];
    if (raw is! List) return const GroupSessionList(groups: []);
    return GroupSessionList(
      groups: raw
          .whereType<Map>()
          .map((e) => GroupSession.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

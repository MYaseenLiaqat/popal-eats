import '../models/social_user.dart';

class GroupMemberLocation {
  const GroupMemberLocation({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
    this.user,
  });

  final int id;
  final int sessionId;
  final int userId;
  final double latitude;
  final double longitude;
  final DateTime updatedAt;
  final UserPublicProfile? user;

  String get coordinatesLabel =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

  factory GroupMemberLocation.fromJson(Map<String, dynamic> json) {
    return GroupMemberLocation(
      id: json['id'] as int? ?? 0,
      sessionId: json['session_id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
      user: json['user'] is Map
          ? UserPublicProfile.fromJson(Map<String, dynamic>.from(json['user'] as Map))
          : null,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class GroupMemberLocationList {
  const GroupMemberLocationList({required this.locations});

  final List<GroupMemberLocation> locations;

  factory GroupMemberLocationList.fromJson(Map<String, dynamic> json) {
    final raw = json['locations'];
    if (raw is! List) return const GroupMemberLocationList(locations: []);
    return GroupMemberLocationList(
      locations: raw
          .whereType<Map>()
          .map((e) => GroupMemberLocation.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class DevicePosition {
  const DevicePosition({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

enum LocationAccessFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class LocationAccessException implements Exception {
  LocationAccessException(this.failure, [this.message]);

  final LocationAccessFailure failure;
  final String? message;

  @override
  String toString() => message ?? failure.name;
}

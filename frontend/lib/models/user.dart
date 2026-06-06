import 'json_parse.dart';

/// User profile from `GET /me` and `UserResponse`.
class User {
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.profileImage,
    this.createdAt,
  });

  final int id;
  final String fullName;
  final String email;
  final String role;
  final String? profileImage;
  final DateTime? createdAt;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: parseInt(json['id'], field: 'id'),
        fullName: parseString(json['full_name']),
        email: parseString(json['email']),
        role: parseString(json['role'], fallback: 'customer'),
        profileImage: json['profile_image']?.toString(),
        createdAt: parseDateTimeOrNull(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'role': role,
        'profile_image': profileImage,
        'created_at': createdAt?.toIso8601String(),
      };
}

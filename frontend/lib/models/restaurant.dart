import 'json_parse.dart';

/// Restaurant from `RestaurantResponse`.
class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    this.ownerId,
    this.description,
    this.address,
    this.city,
    this.phoneNumber,
    this.image,
    this.isOpen = true,
    this.averageRating = 0,
    this.totalReviews = 0,
    this.approvalStatus = 'approved',
    this.rejectionReason,
    this.tags = const [],
    this.openingTime,
    this.closingTime,
    this.createdAt,
  });

  final int id;
  final String name;
  final int? ownerId;
  final String? description;
  final String? address;
  final String? city;
  final String? phoneNumber;
  final String? image;
  final bool isOpen;
  final double averageRating;
  final int totalReviews;
  final String approvalStatus;
  final String? rejectionReason;
  final List<String> tags;
  final String? openingTime;
  final String? closingTime;
  final DateTime? createdAt;

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
        id: parseInt(json['id'], field: 'id'),
        name: parseString(json['name']),
        ownerId: parseIntOrNull(json['owner_id']),
        description: json['description']?.toString(),
        address: json['address']?.toString(),
        city: json['city']?.toString(),
        phoneNumber: json['phone_number']?.toString(),
        image: json['image']?.toString(),
        isOpen: parseBool(json['is_open']),
        averageRating: parseDoubleOrNull(json['average_rating']) ??
            parseDoubleOrNull(json['rating']) ??
            0,
        totalReviews: parseIntOrNull(json['total_reviews']) ?? 0,
        approvalStatus: json['approval_status']?.toString() ?? 'approved',
        rejectionReason: json['rejection_reason']?.toString(),
        tags: _parseTags(json['tags']),
        openingTime: json['opening_time']?.toString(),
        closingTime: json['closing_time']?.toString(),
        createdAt: parseDateTimeOrNull(json['created_at']),
      );

  static List<String> _parseTags(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).where((t) => t.isNotEmpty).toList();
    }
    return const [];
  }
}

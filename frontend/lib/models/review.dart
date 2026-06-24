import 'json_parse.dart';

/// Restaurant review from `ReviewResponse`.
class Review {
  const Review({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.rating,
    this.comment,
    this.sentiment,
    this.sentimentScore,
    this.authorName,
    this.authorUsername,
    this.createdAt,
  });

  final int id;
  final int userId;
  final int restaurantId;
  final int rating;
  final String? comment;
  final String? sentiment;
  final double? sentimentScore;
  final String? authorName;
  final String? authorUsername;
  final DateTime? createdAt;

  String get displayAuthor =>
      authorName?.trim().isNotEmpty == true
          ? authorName!
          : (authorUsername?.trim().isNotEmpty == true ? '@${authorUsername!}' : 'Guest');

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: parseInt(json['id'], field: 'id'),
        userId: parseInt(json['user_id'], field: 'user_id'),
        restaurantId: parseInt(json['restaurant_id'], field: 'restaurant_id'),
        rating: parseInt(json['rating'], field: 'rating'),
        comment: json['comment']?.toString(),
        sentiment: json['sentiment']?.toString(),
        sentimentScore: parseDoubleOrNull(json['sentiment_score']),
        authorName: json['author_name']?.toString(),
        authorUsername: json['author_username']?.toString(),
        createdAt: parseDateTimeOrNull(json['created_at']),
      );
}

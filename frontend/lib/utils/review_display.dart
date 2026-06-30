import '../models/review.dart';

/// Sentiment label aligned with star rating (ignores stale NLP tags).
String sentimentFromRating(int rating) {
  if (rating >= 4) return 'positive';
  if (rating <= 2) return 'negative';
  return 'neutral';
}

bool sentimentMatchesRating(String? sentiment, int rating) {
  if (sentiment == null || sentiment.trim().isEmpty) return false;
  return sentiment.trim().toLowerCase() == sentimentFromRating(rating);
}

String effectiveSentiment(Review review) =>
    sentimentFromRating(review.rating);

/// Remove duplicate review rows (same id or same author + comment).
List<Review> dedupeReviews(List<Review> reviews) {
  final seenIds = <int>{};
  final seenContent = <String>{};
  final result = <Review>[];
  for (final review in reviews) {
    if (!seenIds.add(review.id)) continue;
    final key =
        '${review.userId}|${review.comment?.trim().toLowerCase() ?? ''}';
    if (review.comment != null && review.comment!.trim().isNotEmpty) {
      if (!seenContent.add(key)) continue;
    }
    result.add(review);
  }
  return result;
}

({double average, int total}) reviewStatsFromList(List<Review> reviews) {
  if (reviews.isEmpty) return (average: 0, total: 0);
  final sum = reviews.fold<int>(0, (a, r) => a + r.rating);
  return (average: sum / reviews.length, total: reviews.length);
}

({int positive, int neutral, int negative}) sentimentCountsFromRatings(
  List<Review> reviews,
) {
  var positive = 0;
  var neutral = 0;
  var negative = 0;
  for (final r in reviews) {
    switch (sentimentFromRating(r.rating)) {
      case 'positive':
        positive++;
      case 'negative':
        negative++;
      default:
        neutral++;
    }
  }
  return (positive: positive, neutral: neutral, negative: negative);
}

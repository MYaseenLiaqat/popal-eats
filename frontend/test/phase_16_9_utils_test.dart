import 'package:flutter_test/flutter_test.dart';
import 'package:popal_eats/utils/post_caption.dart';
import 'package:popal_eats/utils/review_display.dart';
import 'package:popal_eats/models/review.dart';

void main() {
  test('displayPostCaption strips seed markers', () {
    expect(
      displayPostCaption('Great biryani!\n<!-- fyp_seed_v1 -->'),
      'Great biryani!',
    );
    expect(displayPostCaption('<!-- fyp_seed_v1 -->'), '');
    expect(hasVisibleCaption('<!-- fyp_seed_v1 -->'), isFalse);
  });

  test('review sentiment aligns with rating', () {
    expect(sentimentFromRating(5), 'positive');
    expect(sentimentFromRating(3), 'neutral');
    expect(sentimentFromRating(1), 'negative');
  });

  test('dedupeReviews removes duplicate ids', () {
    const r1 = Review(id: 1, userId: 1, restaurantId: 1, rating: 5, comment: 'Nice');
    const r2 = Review(id: 1, userId: 1, restaurantId: 1, rating: 5, comment: 'Nice');
    expect(dedupeReviews([r1, r2]).length, 1);
  });
}

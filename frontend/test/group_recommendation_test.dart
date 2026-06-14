import 'package:flutter_test/flutter_test.dart';

import 'package:popal_eats/models/group_recommendation.dart';

void main() {
  test('GroupDishRecommendation parses API payload', () {
    final item = GroupDishRecommendation.fromJson({
      'recommendation_id': 12,
      'dish_id': 44,
      'dish_name': 'Chicken Biryani',
      'restaurant_name': 'Student Biryani',
      'price': '850.00',
      'score': 88.5,
      'consensus_score': 0,
      'final_score': 92.0,
      'reasons': [
        'Matches 3 of 4 members',
        'Fits group budget',
        'Close to group location',
      ],
    });

    expect(item.dishName, 'Chicken Biryani');
    expect(item.scorePercent, 92);
    expect(item.reasons, hasLength(3));
  });

  test('GroupRecommendationsResult parses response', () {
    final result = GroupRecommendationsResult.fromJson({
      'group_id': 5,
      'member_count': 4,
      'group_latitude': 31.52,
      'group_longitude': 74.35,
      'recommendations': [],
    });

    expect(result.groupId, 5);
    expect(result.memberCount, 4);
    expect(result.recommendations, isEmpty);
  });
}

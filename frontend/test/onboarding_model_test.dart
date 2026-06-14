import 'package:flutter_test/flutter_test.dart';

import 'package:popal_eats/models/onboarding_option.dart';

void main() {
  test('OnboardingOptions parses API payload', () {
    final options = OnboardingOptions.fromJson({
      'food_interests': [
        {'key': 'pizza', 'display_name': 'Pizza'},
      ],
      'allergies': [
        {'key': 'peanuts', 'display_name': 'Peanuts'},
      ],
    });

    expect(options.foodInterests, hasLength(1));
    expect(options.foodInterests.first.key, 'pizza');
    expect(options.allergies.first.displayName, 'Peanuts');
  });

  test('OnboardingStatus parses completed flag', () {
    final status = OnboardingStatus.fromJson({'completed': true});
    expect(status.completed, isTrue);
  });
}

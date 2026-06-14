import 'package:flutter_test/flutter_test.dart';

import 'package:popal_eats/models/group_member_location.dart';

void main() {
  test('GroupMemberLocation parses API payload', () {
    final location = GroupMemberLocation.fromJson({
      'id': 1,
      'session_id': 9,
      'user_id': 3,
      'latitude': '31.520400',
      'longitude': '74.358700',
      'updated_at': '2026-06-05T14:30:00Z',
      'user': {
        'id': 3,
        'full_name': 'Sara Ali',
        'username': 'sara_a',
      },
    });

    expect(location.sessionId, 9);
    expect(location.latitude, closeTo(31.5204, 0.0001));
    expect(location.coordinatesLabel, contains('31.52040'));
    expect(location.user?.fullName, 'Sara Ali');
  });

  test('GroupMemberLocationList parses locations array', () {
    final list = GroupMemberLocationList.fromJson({
      'locations': [
        {
          'id': 1,
          'session_id': 9,
          'user_id': 3,
          'latitude': 31.5,
          'longitude': 74.3,
          'updated_at': '2026-06-05T14:30:00Z',
        },
      ],
    });

    expect(list.locations, hasLength(1));
  });
}

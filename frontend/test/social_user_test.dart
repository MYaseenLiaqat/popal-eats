import 'package:flutter_test/flutter_test.dart';

import 'package:popal_eats/models/social_user.dart';

void main() {
  test('UserPublicProfile parses API payload', () {
    final user = UserPublicProfile.fromJson({
      'id': 7,
      'full_name': 'Sara Ali',
      'username': 'sara_a',
      'bio': 'Food lover',
      'profile_image': '/uploads/sara.jpg',
    });

    expect(user.id, 7);
    expect(user.fullName, 'Sara Ali');
    expect(user.displayHandle, '@sara_a');
    expect(user.profileImage, '/uploads/sara.jpg');
  });

  test('FriendRequestsList parses incoming and outgoing', () {
    final list = FriendRequestsList.fromJson({
      'incoming': [
        {
          'id': 1,
          'sender_id': 2,
          'receiver_id': 3,
          'status': 'pending',
          'sender': {
            'id': 2,
            'full_name': 'Ahmed',
            'username': 'ahmed',
          },
        },
      ],
      'outgoing': [],
    });

    expect(list.incoming, hasLength(1));
    expect(list.incoming.first.sender?.fullName, 'Ahmed');
    expect(list.outgoing, isEmpty);
  });
}

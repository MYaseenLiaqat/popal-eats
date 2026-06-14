import 'package:flutter_test/flutter_test.dart';

import 'package:popal_eats/models/group_session.dart';

void main() {
  test('GroupSession parses API payload', () {
    final session = GroupSession.fromJson({
      'id': 3,
      'name': 'Lunch Squad',
      'host_user_id': 1,
      'status': 'active',
      'created_at': '2026-06-05T12:00:00Z',
      'expires_at': '2026-06-06T12:00:00Z',
      'host': {'id': 1, 'full_name': 'Ali', 'username': 'ali'},
      'members': [
        {
          'id': 10,
          'session_id': 3,
          'user_id': 1,
          'joined_at': '2026-06-05T12:00:00Z',
          'user': {'id': 1, 'full_name': 'Ali', 'username': 'ali'},
        },
      ],
    });

    expect(session.name, 'Lunch Squad');
    expect(session.memberCount, 1);
    expect(session.isActive, isTrue);
  });

  test('GroupInvitationsList parses incoming invitations', () {
    final list = GroupInvitationsList.fromJson({
      'incoming': [
        {
          'id': 5,
          'session_id': 3,
          'sender_id': 2,
          'receiver_id': 1,
          'status': 'pending',
          'created_at': '2026-06-05T12:00:00Z',
          'session_name': 'Lunch Squad',
        },
      ],
      'outgoing': [],
    });

    expect(list.incoming, hasLength(1));
    expect(list.incoming.first.sessionName, 'Lunch Squad');
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:popal_eats/models/social_user.dart';
import 'package:popal_eats/providers/friends_provider.dart';
import 'package:popal_eats/widgets/social/user_search_panel.dart';

class _FakeFriends extends FriendsProvider {
  _FakeFriends();

  @override
  Future<void> fetchFriends({bool force = false}) async {}

  @override
  Future<void> fetchSuggestions({bool force = false}) async {}

  @override
  Future<void> fetchRequests({bool force = false}) async {}
}

void main() {
  testWidgets('UserSearchPanel shows suggestions when search is empty', (tester) async {
    final provider = _FakeFriends()
      ..suggestions = const [
        UserPublicProfile(
          id: 2,
          fullName: 'Demo Friend',
          username: 'demofriend',
          role: 'customer',
        ),
      ];

    await tester.pumpWidget(
      ChangeNotifierProvider<FriendsProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(body: UserSearchPanel()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Suggested friends'), findsOneWidget);
    expect(find.text('Demo Friend'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('UserSearchPanel prompts for 2 characters before searching', (tester) async {
    final provider = _FakeFriends();

    await tester.pumpWidget(
      ChangeNotifierProvider<FriendsProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(body: UserSearchPanel()),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'd');
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Keep typing'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

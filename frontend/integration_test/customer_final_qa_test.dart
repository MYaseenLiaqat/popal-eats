import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:popal_eats/main.dart' as app;

/// Final customer-module QA — Chrome walkthrough with screenshots.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const settle = Duration(seconds: 30);
  const email = 'demo.host@example.com';
  const password = 'Demo1234!';

  Future<void> pumpApp(WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle(settle);
  }

  Future<void> dismissGates(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      if (find.text('Agree & Continue').evaluate().isNotEmpty) {
        await tester.tap(find.text('Agree & Continue'));
        await tester.pumpAndSettle(settle);
      }
      if (find.text('Not now').evaluate().isNotEmpty) {
        await tester.tap(find.text('Not now'));
        await tester.pumpAndSettle(settle);
      }
      if (find.text('Skip').evaluate().isNotEmpty) {
        await tester.tap(find.text('Skip').first);
        await tester.pumpAndSettle(settle);
      }
      if (find.text('Finish setup').evaluate().isNotEmpty) {
        await tester.tap(find.text('Finish setup'));
        await tester.pumpAndSettle(settle);
      }
    }
  }

  Future<void> login(WidgetTester tester) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), email);
    await tester.enterText(fields.at(1), password);
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle(settle);
    await dismissGates(tester);
  }

  Future<void> shot(WidgetTester tester, String name) async {
    try {
      await binding.convertFlutterSurfaceToImage();
      await binding.takeScreenshot(name);
    } catch (_) {}
  }

  testWidgets('customer final QA walkthrough', (tester) async {
    await pumpApp(tester);
    await login(tester);

    // Home — no catalogue widgets
    expect(find.text('Popular Restaurants'), findsNothing);
    expect(find.text('Featured'), findsNothing);
    expect(find.text('HomePromoCarousel'), findsNothing);
    await shot(tester, 'home');

    // Order + search
    await tester.tap(find.text('Order').first);
    await tester.pumpAndSettle(settle);
    await shot(tester, 'order');

    final search = find.byType(TextField).first;
    await tester.enterText(search, 'burger');
    await tester.pumpAndSettle(settle);
    await shot(tester, 'order_search_burger');

    // Friend search via profile community
    await tester.tap(find.text('Community').first);
    await tester.pumpAndSettle(settle);
    if (find.text('Find people').evaluate().isNotEmpty) {
      await tester.tap(find.text('Find people').first);
      await tester.pumpAndSettle(settle);
    }
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle(settle);
    await shot(tester, 'friend_search_idle');

    final searchFields = find.byType(TextField);
    if (searchFields.evaluate().length >= 1) {
      await tester.enterText(searchFields.last, 'demo');
      await tester.pumpAndSettle(settle);
      await shot(tester, 'friend_search_demo');
    }

    // Admin via profile if demo user is admin — skip if not visible
    await tester.tap(find.text('Profile').first);
    await tester.pumpAndSettle(settle);
    if (find.text('Admin Dashboard').evaluate().isNotEmpty) {
      await tester.tap(find.text('Admin Dashboard'));
      await tester.pumpAndSettle(settle);
      await shot(tester, 'admin_dashboard');
    }

    expect(tester.takeException(), isNull);
  });
}

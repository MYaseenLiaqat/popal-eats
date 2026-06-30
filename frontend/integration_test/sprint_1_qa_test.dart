import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:popal_eats/main.dart' as app;

/// Sprint 1 functional QA — customer flows with screenshots.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const settle = Duration(seconds: 60);
  const pwd = 'Demo1234!';
  final platform = const String.fromEnvironment('QA_PLATFORM', defaultValue: 'unknown');

  Future<void> shot(WidgetTester tester, String name) async {
    final tag = '${platform}_$name';
    try {
      await binding.convertFlutterSurfaceToImage();
      await binding.takeScreenshot(tag);
    } catch (_) {}
  }

  Future<void> pumpApp(WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle(settle);
  }

  Future<void> dismissGates(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
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
        continue;
      }
      if (find.text('Finish setup').evaluate().isNotEmpty) {
        await tester.tap(find.text('Finish setup'));
        await tester.pumpAndSettle(settle);
      }
      break;
    }
  }

  Future<void> login(WidgetTester tester, String email) async {
    expect(find.text('Welcome back'), findsOneWidget);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), email);
    await tester.enterText(fields.at(1), pwd);
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle(settle);
    await dismissGates(tester);
  }

  testWidgets('S1 auth — login logout session', (tester) async {
    await pumpApp(tester);
    await shot(tester, '01_login');

    await login(tester, 'demo.host@example.com');
    await shot(tester, '02_home');
    expect(find.text('Popal Eats'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Profile').first);
    await tester.pumpAndSettle(settle);
    await shot(tester, '03_profile');

    if (find.text('Logout').evaluate().isNotEmpty) {
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle(settle);
      expect(find.text('Welcome back'), findsOneWidget);
      await shot(tester, '04_logout');
    }
  });

  testWidgets('S1 home feed and empty state', (tester) async {
    await pumpApp(tester);
    await login(tester, 'demo.host@example.com');
    await shot(tester, '05_home_feed');
    expect(tester.takeException(), isNull);
  });

  testWidgets('S1 order page sections search cuisine', (tester) async {
    await pumpApp(tester);
    await login(tester, 'demo.host@example.com');

    await tester.tap(find.text('Order').first);
    await tester.pumpAndSettle(settle);
    await shot(tester, '06_order');

    expect(find.text('Recommended For You'), findsOneWidget);

    final search = find.byType(TextField);
    if (search.evaluate().isNotEmpty) {
      await tester.enterText(search.first, 'pizza');
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await shot(tester, '07_order_search');
    }

    if (find.text('Italian').evaluate().isNotEmpty) {
      await tester.tap(find.text('Italian').first);
      await tester.pumpAndSettle(settle);
      await shot(tester, '08_order_cuisine');
      await tester.tap(find.text('Italian').first);
      await tester.pumpAndSettle(settle);
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('S1 community friend search', (tester) async {
    await pumpApp(tester);
    await login(tester, 'demo.host@example.com');

    await tester.tap(find.text('Community').first);
    await tester.pumpAndSettle(settle);
    await shot(tester, '09_community');

    if (find.textContaining('Find friends').evaluate().isNotEmpty) {
      await tester.tap(find.textContaining('Find friends').first);
      await tester.pumpAndSettle(settle);
      await shot(tester, '10_friend_search');

      final fields = find.byType(TextField);
      if (fields.evaluate().isNotEmpty) {
        await tester.enterText(fields.first, 'demo');
        await tester.pumpAndSettle(const Duration(seconds: 2));
        await shot(tester, '11_search_results');
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('S1 health dashboard metrics', (tester) async {
    await pumpApp(tester);
    await login(tester, 'demo.host@example.com');

    await tester.tap(find.text('Profile').first);
    await tester.pumpAndSettle(settle);

    if (find.text('Health Dashboard').evaluate().isNotEmpty) {
      await tester.tap(find.text('Health Dashboard'));
      await tester.pumpAndSettle(settle);
      await shot(tester, '12_health');

      for (final label in ['Protein', 'Health Score', 'Calories']) {
        if (find.text(label).evaluate().isNotEmpty) {
          await tester.tap(find.text(label).first);
          await tester.pumpAndSettle(settle);
        }
      }
      await shot(tester, '13_health_metrics');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('S1 delivery tab', (tester) async {
    await pumpApp(tester);
    await login(tester, 'demo.host@example.com');

    if (find.text('Delivery').evaluate().isNotEmpty) {
      await tester.tap(find.text('Delivery').first);
      await tester.pumpAndSettle(settle);
      await shot(tester, '14_delivery');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('S1 restaurant detail from order', (tester) async {
    await pumpApp(tester);
    await login(tester, 'demo.host@example.com');

    await tester.tap(find.text('Order').first);
    await tester.pumpAndSettle(settle);

    final cards = find.byType(InkWell);
    if (cards.evaluate().length > 3) {
      await tester.tap(cards.at(3));
      await tester.pumpAndSettle(settle);
      await shot(tester, '15_restaurant_detail');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('S1 signup flow', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle(settle);
    await shot(tester, '16_signup');
    expect(find.text('Continue'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

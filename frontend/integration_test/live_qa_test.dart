import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:popal_eats/main.dart' as app;

/// Live E2E QA — drives the compiled Flutter app UI (not HTTP / not unit tests).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const settle = Duration(seconds: 45);
  const pwd = 'Demo1234!';
  const newPwd = 'Test1234!';
  final suffix = Random().nextInt(900000) + 100000;

  Future<void> pumpApp(WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle(settle);
  }

  Future<void> dismissGateScreens(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
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

  Future<void> loginUi(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    expect(find.text('Welcome back'), findsOneWidget);
    final fields = find.byType(TextField);
    expect(fields, findsAtLeast(2));
    await tester.enterText(fields.at(0), email);
    await tester.enterText(fields.at(1), password);
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle(settle);
  }

  Future<void> logoutIfPossible(WidgetTester tester) async {
    if (find.text('Logout').evaluate().isNotEmpty) {
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle(settle);
      return;
    }
    if (find.text('Sign out').evaluate().isNotEmpty) {
      await tester.tap(find.text('Sign out').first);
      await tester.pumpAndSettle(settle);
    }
  }

  Future<void> screenshot(WidgetTester tester, String name) async {
    try {
      await binding.convertFlutterSurfaceToImage();
      await binding.takeScreenshot(name);
    } catch (_) {
      // Web screenshot support varies by platform.
    }
  }

  testWidgets('live QA — customer login, home navigation, logout', (tester) async {
    await pumpApp(tester);
    await screenshot(tester, '01_login');

    await loginUi(tester, email: 'demo.host@example.com', password: pwd);
    await dismissGateScreens(tester);
    await screenshot(tester, '02_customer_home');

    expect(find.text('Home'), findsWidgets);
    await tester.tap(find.text('Order').first);
    await tester.pumpAndSettle(settle);
    await tester.tap(find.text('Community').first);
    await tester.pumpAndSettle(settle);
    await tester.tap(find.text('Profile').first);
    await tester.pumpAndSettle(settle);
    await screenshot(tester, '03_customer_profile');

    await logoutIfPossible(tester);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('live QA — customer signup', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle(settle);
    await screenshot(tester, '04_signup_role');

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle(settle);
    expect(find.text('Username'), findsNothing);

    final email = 'live.qa.$suffix@example.com';
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Live');
    await tester.enterText(fields.at(1), 'QA');
    await tester.enterText(fields.at(2), email);
    await tester.enterText(fields.at(3), '+92300$suffix');
    await tester.tap(find.textContaining('Select date of birth'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final pwdFields = fields.evaluate().length;
    await tester.enterText(fields.at(pwdFields - 2), newPwd);
    await tester.enterText(fields.at(pwdFields - 1), newPwd);
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle(settle);
    await screenshot(tester, '05_customer_after_signup');

    await dismissGateScreens(tester);
    expect(find.text('Home'), findsWidgets);
  });

  testWidgets('live QA — restaurant signup form renders', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle(settle);
    await tester.scrollUntilVisible(find.text('Restaurant'), 120);
    await tester.tap(find.text('Restaurant'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Continue'), 120);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle(settle);
    await screenshot(tester, '06_restaurant_form');

    expect(find.text('Restaurant name'), findsWidgets);
    expect(find.text('Upload'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('live QA — home chef signup form renders', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle(settle);
    await tester.scrollUntilVisible(find.text('Home Chef'), 120);
    await tester.tap(find.text('Home Chef'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Continue'), 120);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle(settle);
    await screenshot(tester, '07_home_chef_form');

    expect(find.text('Display name'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('live QA — restaurant login shows pending gate', (tester) async {
    await pumpApp(tester);
    await loginUi(tester, email: 'demo.owner@example.com', password: pwd);
    await dismissGateScreens(tester);
    await screenshot(tester, '08_restaurant_pending');
    expect(find.textContaining('pending', findRichText: true), findsWidgets);
    await logoutIfPossible(tester);
  });

  testWidgets('live QA — admin login and dashboard', (tester) async {
    await pumpApp(tester);
    await loginUi(
      tester,
      email: 'admin@popaleats.com',
      password: 'YourPassword123',
    );
    await dismissGateScreens(tester);
    await tester.pumpAndSettle(settle);
    await screenshot(tester, '09_admin_dashboard');

    expect(find.text('Admin Dashboard'), findsWidgets);
    expect(find.text('Platform summary'), findsOneWidget);
  });

  testWidgets('live QA — google sign-in button visibility on web', (tester) async {
    await pumpApp(tester);
    // Web without FIREBASE_* dart-defines should hide Google button.
    expect(find.text('Continue with Google'), findsNothing);
  });
}

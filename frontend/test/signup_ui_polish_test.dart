import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:popal_eats/data/cuisine_catalog.dart';
import 'package:popal_eats/providers/auth_provider.dart';
import 'package:popal_eats/screens/signup_screen.dart';
import 'package:popal_eats/utils/auth_validation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> openForm(WidgetTester tester, SignupRole role) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: SignupScreen()),
      ),
    );
    await tester.pumpAndSettle();

    if (role == SignupRole.restaurant) {
      await tester.scrollUntilVisible(
        find.text('Restaurant'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Restaurant'));
    } else if (role == SignupRole.homeChef) {
      await tester.scrollUntilVisible(
        find.text('Home Chef'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Home Chef'));
    }
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Continue'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  testWidgets('restaurant form field order at 1366x768', (tester) async {
    await openForm(tester, SignupRole.restaurant);

    final labels = [
      'Restaurant name',
      'Restaurant email',
      'Business phone',
      'Restaurant address',
      'Cuisine',
      'Description (optional)',
      'Registration number (optional)',
      'Logo (optional)',
      'Cover image (optional)',
      'Password',
      'Confirm password',
      'Create account',
    ];
    for (final label in labels) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('First name'), findsNothing);
    expect(find.text('Username'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home chef form field order at 1920x1080', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;

    await openForm(tester, SignupRole.homeChef);

    final labels = [
      'Display name',
      'Email',
      'Phone',
      'Kitchen address',
      'Cuisine specialty',
      'Biography (optional)',
      'Food license (optional)',
      'Profile image (optional)',
      'Password',
      'Confirm password',
    ];
    for (final label in labels) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.text('Upload'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cuisine dropdown visible with catalog items', (tester) async {
    await openForm(tester, SignupRole.restaurant);

    await tester.scrollUntilVisible(
      find.widgetWithText(DropdownButtonFormField<String>, 'Cuisine'),
      120,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text('Select cuisine'));
    await tester.pumpAndSettle();

    for (final cuisine in CuisineCatalog.cuisines) {
      expect(find.text(cuisine.name).evaluate().isNotEmpty, isTrue);
    }
  });
}

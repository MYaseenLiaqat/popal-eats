import 'package:flutter_test/flutter_test.dart';

import 'package:popal_eats/main.dart';

void main() {
  testWidgets('App loads login screen when logged out', (tester) async {
    await tester.pumpWidget(const PopalEatsApp());
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsWidgets);
  });
}

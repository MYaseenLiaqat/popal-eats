import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popal_eats_mobile/main.dart';

void main() {
  testWidgets('Shows recommendations screen with loading state', (WidgetTester tester) async {
    await tester.pumpWidget(const PopalEatsApp());

    expect(find.text('Recommendations'), findsOneWidget);
    expect(find.text('Loading recommendations…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

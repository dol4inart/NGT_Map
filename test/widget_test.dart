// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nsk_transport_map/main.dart';

void main() {
  testWidgets('App shows home screen title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Give async initState() a moment; network calls are stubbed in widget tests.
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Карта общественного транспорта'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}

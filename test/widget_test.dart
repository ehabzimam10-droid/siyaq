// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:siyaq/main.dart';

void main() {
  testWidgets('App smoke test - renders HomeScreen with title and bottom bar', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: SiyaqApp(),
      ),
    );

    // Verify that the title "سياق • اليومي" is displayed.
    expect(find.text('سياق • اليومي'), findsOneWidget);

    // Verify that the bottom navigation bar item label "الرئيسية" is displayed.
    expect(find.text('الرئيسية'), findsOneWidget);
  });
}

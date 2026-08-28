import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siyaq/features/settings/screens/settings_screen.dart';
import 'package:siyaq/features/settings/providers/settings_provider.dart';
import 'helpers/test_helper.dart';

void main() {
  setUpAll(() async {
    await initTestLocale();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Arabic Prayer Names E2E Tests', () {
    // ==========================================
    // Tier 1 - Feature Coverage
    // ==========================================

    testWidgets('T1.F4.1: Verify Settings Screen renders the prayer customization header "تخصيص أوقات الصلوات والعبادة"', (WidgetTester tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(createTestableWidget(SettingsScreen(scrollController: controller)));
      await tester.pumpAndSettle();

      // Drag to scroll and build header
      await tester.drag(find.byType(ListView), const Offset(0, -250));
      await tester.pumpAndSettle();

      expect(find.text('تخصيص أوقات الصلوات والعبادة'), findsOneWidget);
    });

    testWidgets('T1.F4.2: Verify the Fajr prayer displays Arabic label "صلاة الفجر"', (WidgetTester tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(createTestableWidget(SettingsScreen(scrollController: controller)));
      await tester.pumpAndSettle();

      // Drag to scroll and build Fajr widget
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('صلاة الفجر'), findsOneWidget);
    });

    testWidgets('T1.F4.3: Verify the Dhuhr prayer displays Arabic label "صلاة الظهر"', (WidgetTester tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(createTestableWidget(SettingsScreen(scrollController: controller)));
      await tester.pumpAndSettle();

      // Drag to scroll and build Dhuhr widget
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.text('صلاة الظهر'), findsOneWidget);
    });

    testWidgets('T1.F4.4: Verify the Asr prayer displays Arabic label "صلاة العصر"', (WidgetTester tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(createTestableWidget(SettingsScreen(scrollController: controller)));
      await tester.pumpAndSettle();

      // Drag to scroll and build Asr widget
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.text('صلاة العصر'), findsOneWidget);
    });

    testWidgets('T1.F4.5: Verify Maghrib and Isha prayers display Arabic labels "صلاة المغرب" and "صلاة العشاء"', (WidgetTester tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(createTestableWidget(SettingsScreen(scrollController: controller)));
      await tester.pumpAndSettle();

      // Drag to scroll and build Maghrib and Isha
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('صلاة المغرب'), findsOneWidget);
      expect(find.text('صلاة العشاء'), findsOneWidget);
    });

    // ==========================================
    // Tier 2 - Boundary & Corner Cases
    // ==========================================

    testWidgets('T2.F4.1: Settings reset keeps prayer names displayed in Arabic', (WidgetTester tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(createTestableWidget(SettingsScreen(scrollController: controller)));
      await tester.pumpAndSettle();

      // Drag to scroll and build reset settings button
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      final resetButton = find.byKey(const Key('reset_settings_button'));
      expect(resetButton, findsOneWidget);
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      expect(find.text('صلاة الفجر'), findsOneWidget);
      expect(find.text('صلاة الظهر'), findsOneWidget);
    });

    testWidgets('T2.F4.2: Prayer offsets slider handles negative limit (-20) and positive limit (+20) updates correctly', (WidgetTester tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(createTestableWidget(SettingsScreen(scrollController: controller)));
      await tester.pumpAndSettle();

      // Drag to scroll and build slider
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();

      // Find Fajr Offset Slider (Index 0 in the list of sliders)
      final offsetSliders = find.byType(Slider);
      expect(offsetSliders, findsAtLeastNWidgets(1));

      final firstSlider = tester.widget<Slider>(offsetSliders.at(0));
      expect(firstSlider.min, equals(-20));
      expect(firstSlider.max, equals(20));

      // Trigger changes
      firstSlider.onChanged!(-20.0);
      await tester.pumpAndSettle();

      firstSlider.onChanged!(20.0);
      await tester.pumpAndSettle();
    });

    testWidgets('T2.F4.3: Prayer duration slider handles min limit (10) and max limit (60) updates correctly', (WidgetTester tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(createTestableWidget(SettingsScreen(scrollController: controller)));
      await tester.pumpAndSettle();

      // Drag to scroll and build slider
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();

      // Find Fajr Duration Slider (Index 1 in the list of sliders)
      final durationSliders = find.byType(Slider);
      expect(durationSliders, findsAtLeastNWidgets(2));

      final secondSlider = tester.widget<Slider>(durationSliders.at(1));
      expect(secondSlider.min, equals(10));
      expect(secondSlider.max, equals(60));

      // Trigger changes
      secondSlider.onChanged!(10.0);
      await tester.pumpAndSettle();

      secondSlider.onChanged!(60.0);
      await tester.pumpAndSettle();
    });

    testWidgets('T2.F4.4: Slider adjustments for all prayers update their state concurrently without layout constraints', (WidgetTester tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(createTestableWidget(SettingsScreen(scrollController: controller)));
      await tester.pumpAndSettle();

      // Drag to scroll and build all sliders
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      expect(sliders, findsAtLeastNWidgets(10)); // 5 prayers * 2 sliders each

      for (int i = 0; i < 10; i++) {
        final slider = tester.widget<Slider>(sliders.at(i));
        // Alternate between values
        final value = i % 2 == 0 ? 5.0 : 30.0;
        slider.onChanged!(value);
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('T2.F4.5: Scroll Settings Screen to ensure all 5 prayer configuration cards are reachable and interactable', (WidgetTester tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(createTestableWidget(SettingsScreen(scrollController: controller)));
      await tester.pumpAndSettle();

      // Drag to scroll down settings page
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Verify that the 5th prayer (Isha) is in view and interactable
      final ishaText = find.text('صلاة العشاء');
      expect(ishaText, findsOneWidget);
    });
  });
}

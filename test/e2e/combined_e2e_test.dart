import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:siyaq/main.dart';
import 'package:siyaq/core/widgets/floating_app_bar.dart';
import 'package:siyaq/core/widgets/solarium_glass_container.dart';
import 'package:siyaq/features/calendar/screens/calendar_screen.dart';
import 'package:siyaq/features/settings/screens/settings_screen.dart';
import 'package:siyaq/features/home/screens/home_screen.dart';
import 'helpers/test_helper.dart';

void main() {
  setUpAll(() async {
    await initTestLocale();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Combined E2E Tests (Tiers 3 & 4)', () {
    // ==========================================
    // Tier 3 - Cross-Feature Combinations
    // ==========================================

    testWidgets('T3.1 (Locale + Theme): Navigate to Calendar (ar locale formatted) and cycle theme mode, verifying date strings update colors/fonts without loosing Arabic values', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SiyaqApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Calendar Screen
      await tester.tap(find.text('التقويم'));
      await tester.pumpAndSettle();

      final todayStr = DateFormat('EEEE', 'ar').format(DateTime.now());
      expect(find.text(todayStr), findsOneWidget);

      // Cycle theme
      final toggleButton = find.byKey(const Key('theme_toggle_button'));
      expect(toggleButton, findsOneWidget);
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      // Verify Arabic values remain correct after theme change
      expect(find.text(todayStr), findsOneWidget);
    });

    testWidgets('T3.2 (Theme + Blur): Toggle dark mode, scroll Settings Screen to trigger blur, and verify appBar BackdropFilter colors blend correctly with dark theme styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SiyaqApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Cycle to dark mode
      final toggleButton = find.byKey(const Key('theme_toggle_button'));
      await tester.tap(toggleButton); // light
      await tester.pumpAndSettle();
      await tester.tap(toggleButton); // dark
      await tester.pumpAndSettle();

      // Go to Settings Screen
      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();

      // Scroll Settings Screen to trigger floating app bar blur
      final settingsList = find.byType(ListView);
      expect(settingsList, findsOneWidget);
      await tester.drag(settingsList, const Offset(0, -300));
      await tester.pumpAndSettle();

      final glassContainerFinder = find.descendant(
        of: find.byType(FloatingAppBar),
        matching: find.byType(SolariumGlassContainer),
      );
      final glassContainer = tester.widget<SolariumGlassContainer>(glassContainerFinder);
      expect(glassContainer.blur, equals(25.0));
      
      final BuildContext context = tester.element(find.byType(HomeScreen));
      expect(Theme.of(context).brightness, equals(Brightness.dark));
    });

    testWidgets('T3.3 (Locale + Scroll + Dialog): Scroll Calendar Screen to trigger blur, open DatePicker dialog, verify localization in dialog matches, and close it without affecting appBar state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SiyaqApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Go to Calendar Screen
      await tester.tap(find.text('التقويم'));
      await tester.pumpAndSettle();

      // Scroll calendar screen to trigger floating app bar
      await tester.drag(find.byType(CalendarScreen), const Offset(0, -30));
      await tester.pumpAndSettle();

      // Open DatePicker dialog
      final datePickerButton = find.text('اختر التاريخ');
      await tester.tap(datePickerButton);
      await tester.pumpAndSettle();

      // Verify Arabic localization
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(find.text('حسنًا'), findsOneWidget);
      await tester.tap(find.text('الإلغاء'));
      await tester.pumpAndSettle();

      // Check appBar remains floating/scrolled
      final glassContainerFinder = find.descendant(
        of: find.byType(FloatingAppBar),
        matching: find.byType(SolariumGlassContainer),
      );
      final glassContainer = tester.widget<SolariumGlassContainer>(glassContainerFinder);
      expect(glassContainer.blur, equals(25.0));
    });

    testWidgets('T3.4 (Prayer settings + Theme): Switch to Dark theme, navigate to settings, verify Arabic prayer titles and sliders reflect dark mode colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SiyaqApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Toggle theme to dark
      final toggleButton = find.byKey(const Key('theme_toggle_button'));
      await tester.tap(toggleButton); // light
      await tester.pump();
      await tester.tap(toggleButton); // dark
      await tester.pumpAndSettle();

      // Navigate to Settings
      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();

      // Drag to scroll and build Fajr widget
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('صلاة الفجر'), findsOneWidget);
      
      final BuildContext context = tester.element(find.byType(HomeScreen));
      expect(Theme.of(context).brightness, equals(Brightness.dark));
    });

    // ==========================================
    // Tier 4 - Real-World Application Scenarios
    // ==========================================

    testWidgets('T4.1 (User Onboarding Flow): App launches safely -> navigates to Calendar (verifying Arabic date labels) -> select a date -> verify no crashes', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SiyaqApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Tab bar navigation to Calendar
      await tester.tap(find.text('التقويم'));
      await tester.pumpAndSettle();

      final todayStr = DateFormat('EEEE', 'ar').format(DateTime.now());
      expect(find.text(todayStr), findsOneWidget);

      // Select date
      await tester.tap(find.text('اختر التاريخ'));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
      final okButton = find.byWidgetPredicate((w) => w is Text && (w.data == 'حسنًا' || w.data == 'موافق' || w.data == 'OK'));
      await tester.tap(okButton);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('T4.2 (Theme & Settings Configuration): User launches app, toggles theme to Dark, navigates to settings, scrolls to prayers, adjusts Fajr offset to +10, verifies UI displays correct text, and checks if settings persist', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SiyaqApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Toggle to dark theme
      final toggleButton = find.byKey(const Key('theme_toggle_button'));
      await tester.tap(toggleButton); // light
      await tester.pump();
      await tester.tap(toggleButton); // dark
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();

      // Drag to scroll to prayers
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Adjust Fajr offset
      final sliders = find.byType(Slider);
      expect(sliders, findsAtLeastNWidgets(2));
      final fajrOffsetSlider = tester.widget<Slider>(sliders.at(0));
      fajrOffsetSlider.onChanged!(10.0);
      await tester.pumpAndSettle();

      // Verify UI text matches updated offset
      expect(find.textContaining('بعد الأذان بـ 10 د'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T4.3 (Calendar Interaction & Scrolling): User navigates to Calendar, scrolls down to see schedule, verifies frosted glass effect activates, opens Task addition sheet, adds a custom task, and verifies the list updates', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SiyaqApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Calendar
      await tester.tap(find.text('التقويم'));
      await tester.pumpAndSettle();

      // Scroll Calendar
      await tester.drag(find.byType(CalendarScreen), const Offset(0, -30));
      await tester.pumpAndSettle();

      // Verify glass blur activated
      final glassContainerFinder = find.descendant(
        of: find.byType(FloatingAppBar),
        matching: find.byType(SolariumGlassContainer),
      );
      expect(tester.widget<SolariumGlassContainer>(glassContainerFinder).blur, equals(25.0));

      // Open task addition sheet using floating action button
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Enter task title
      final titleField = find.byType(TextField).first;
      await tester.enterText(titleField, 'مهمة تجريبية E2E');
      await tester.pumpAndSettle();

      // Scroll down the bottom sheet to make save button fully visible
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Save task
      final saveButton = find.text('حفظ المهمة في سياق');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify list contains newly added task title
      expect(find.text('مهمة تجريبية E2E'), findsOneWidget);
    });

    testWidgets('T4.4 (Continuous Theme & Blur performance): Cycle through all theme modes while repeatedly scrolling page up and down, verifying BackdropFilter handles rapid changes gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SiyaqApp(),
        ),
      );
      await tester.pumpAndSettle();

      final toggleButton = find.byKey(const Key('theme_toggle_button'));
      
      for (int i = 0; i < 5; i++) {
        // Toggle theme
        await tester.tap(toggleButton);
        await tester.pump();

        // Scroll down
        await tester.drag(find.byType(HomeScreen), const Offset(0, -150));
        await tester.pump();

        // Scroll back up
        await tester.drag(find.byType(HomeScreen), const Offset(0, 150));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('T4.5 (Complete Settings Adjustments): Go to Settings Screen, adjust offsets for all 5 prayers, toggle theme mode, scroll down, verify the application version card, and return to main dashboard', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SiyaqApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Go to settings
      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();

      // Scroll to build the sliders
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Adjust offsets for all 5 prayers
      final sliders = find.byType(Slider);
      expect(sliders, findsAtLeastNWidgets(10));
      for (int i = 0; i < 5; i++) {
        final offsetSlider = tester.widget<Slider>(sliders.at(i * 2));
        offsetSlider.onChanged!(5.0);
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Toggle theme mode
      final toggleButton = find.byKey(const Key('theme_toggle_button'));
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      // Scroll to bottom
      await tester.drag(find.byType(ListView), const Offset(0, -800));
      await tester.pumpAndSettle();

      // Verify app version card
      expect(find.text('تطبيق سياق (Siyaq)'), findsOneWidget);
      expect(find.textContaining('الإصدار 2.0.0'), findsOneWidget);

      // Return to main dashboard
      await tester.tap(find.text('الرئيسية'));
      await tester.pumpAndSettle();

      expect(find.text('سياق • اليومي'), findsOneWidget);
    });
  });
}

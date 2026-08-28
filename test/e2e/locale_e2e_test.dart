import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/src/date_format_internal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:siyaq/features/calendar/screens/calendar_screen.dart';
import 'package:siyaq/features/dashboard/providers/schedule_provider.dart';
import 'helpers/test_helper.dart';

void main() {
  setUpAll(() async {
    await initTestLocale();
  });

  setUp(() async {
    dateTimeSymbols['ar'].ZERODIGIT = '0';
    SharedPreferences.setMockInitialValues({});
  });

  group('Locale & Date Formatting E2E Tests', () {
    // ==========================================
    // Tier 1 - Feature Coverage
    // ==========================================

    testWidgets('T1.F1.1: App starts and navigates to Calendar Screen without throwing LocaleDataException', (WidgetTester tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(createTestableWidget(CalendarScreen(scrollController: controller)));
      await tester.pumpAndSettle();
      
      expect(find.byType(CalendarScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T1.F1.2: EEEE date format displays Arabic day names (e.g. الجمعة)', (WidgetTester tester) async {
      final controller = ScrollController();
      final targetDate = DateTime(2026, 7, 10); // July 10, 2026 is Friday (الجمعة)
      
      await tester.pumpWidget(
        createTestableWidget(
          CalendarScreen(scrollController: controller),
          overrides: [
            selectedDateProvider.overrideWith(() => MockSelectedDateNotifier(targetDate)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الجمعة'), findsOneWidget);
    });

    testWidgets('T1.F1.3: dd MMMM yyyy format displays Arabic month names (e.g. يوليو)', (WidgetTester tester) async {
      final controller = ScrollController();
      final targetDate = DateTime(2026, 7, 10); // 10 يوليو 2026
      
      await tester.pumpWidget(
        createTestableWidget(
          CalendarScreen(scrollController: controller),
          overrides: [
            selectedDateProvider.overrideWith(() => MockSelectedDateNotifier(targetDate)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate((w) =>
            w is Text &&
            (w.data == '10 يوليو 2026' || w.data == '١٠ يوليو ٢٠٢٦')),
        findsOneWidget,
      );
    });

    testWidgets('T1.F1.4: Arabic locale is correctly propagated to DateFormat formatters without default fallback issues', (WidgetTester tester) async {
      final targetDate = DateTime(2026, 7, 10);
      final formattedDay = DateFormat('EEEE', 'ar').format(targetDate);
      final formattedFull = DateFormat('dd MMMM yyyy', 'ar').format(targetDate);

      expect(formattedDay, contains('الجمعة'));
      expect(formattedFull, contains('يوليو'));
      expect(formattedFull, anyOf(contains('2026'), contains('٢٠٢٦')));
    });

    testWidgets('T1.F1.5: Initial app load configures Global Material Localizations for Arabic', (WidgetTester tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(createTestableWidget(CalendarScreen(scrollController: controller)));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(CalendarScreen));
      final Locale currentLocale = Localizations.localeOf(context);

      expect(currentLocale.languageCode, equals('ar'));
    });

    // ==========================================
    // Tier 2 - Boundary & Corner Cases
    // ==========================================

    testWidgets('T2.F1.1: Verify date formatting handles Leap Years (e.g. Feb 29) without crashing or failing', (WidgetTester tester) async {
      final controller = ScrollController();
      final leapDate = DateTime(2024, 2, 29); // 29 فبراير 2024 (الخميس)
      
      await tester.pumpWidget(
        createTestableWidget(
          CalendarScreen(scrollController: controller),
          overrides: [
            selectedDateProvider.overrideWith(() => MockSelectedDateNotifier(leapDate)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الخميس'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) =>
            w is Text &&
            (w.data == '29 فبراير 2024' || w.data == '٢٩ فبراير ٢٠٢٤')),
        findsOneWidget,
      );
    });

    testWidgets('T2.F1.2: Verify date formatting handles dates far in the future (e.g., year 2036)', (WidgetTester tester) async {
      final controller = ScrollController();
      final futureDate = DateTime(2036, 7, 10); // 10 يوليو 2036 (الخميس)
      
      await tester.pumpWidget(
        createTestableWidget(
          CalendarScreen(scrollController: controller),
          overrides: [
            selectedDateProvider.overrideWith(() => MockSelectedDateNotifier(futureDate)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الخميس'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) =>
            w is Text &&
            (w.data == '10 يوليو 2036' || w.data == '١٠ يوليو ٢٠٣٦')),
        findsOneWidget,
      );
    });

    testWidgets('T2.F1.3: Verify date formatting handles past dates correctly', (WidgetTester tester) async {
      final controller = ScrollController();
      final pastDate = DateTime(2016, 7, 10); // 10 يوليو 2016 (الأحد)
      
      await tester.pumpWidget(
        createTestableWidget(
          CalendarScreen(scrollController: controller),
          overrides: [
            selectedDateProvider.overrideWith(() => MockSelectedDateNotifier(pastDate)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الأحد'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) =>
            w is Text &&
            (w.data == '10 يوليو 2016' || w.data == '١٠ يوليو ٢٠١٦')),
        findsOneWidget,
      );
    });

    testWidgets('T2.F1.4: Verify rapid switching between calendar days does not cause rendering lags or formatting failures', (WidgetTester tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(createTestableWidget(CalendarScreen(scrollController: controller)));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(CalendarScreen));
      final containerRef = ProviderScope.containerOf(context);

      for (int i = 0; i < 20; i++) {
        containerRef.read(selectedDateProvider.notifier).setDate(DateTime(2026, 7, 10 + i));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      
      expect(tester.takeException(), isNull);
    });

    testWidgets('T2.F1.5: Verify that date picker dialog uses localizations corresponding to Arabic locale', (WidgetTester tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(createTestableWidget(CalendarScreen(scrollController: controller)));
      await tester.pumpAndSettle();

      // Tap on DatePicker trigger button
      final datePickerButton = find.text('اختر التاريخ');
      expect(datePickerButton, findsOneWidget);
      await tester.tap(datePickerButton);
      await tester.pumpAndSettle();

      // Verify that DatePicker dialog is shown and displays Arabic confirm/cancel labels
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(find.text('حسنًا'), findsOneWidget);
      expect(find.text('الإلغاء'), findsOneWidget);
    });
  });
}

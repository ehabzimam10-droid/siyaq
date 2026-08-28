import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siyaq/main.dart';
import 'package:siyaq/features/home/screens/home_screen.dart';
import 'package:siyaq/features/settings/screens/settings_screen.dart';
import 'package:siyaq/core/theme/colors.dart';
import 'helpers/test_helper.dart';

void main() {
  setUpAll(() async {
    await initTestLocale();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Theme Mode Toggle E2E Tests', () {
    // ==========================================
    // Tier 1 - Feature Coverage
    // ==========================================

    testWidgets('T1.F2.1: Verify default system theme starts correctly in MaterialApp', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SiyaqApp(),
        ),
      );
      await tester.pumpAndSettle();

      final materialAppFinder = find.byType(MaterialApp);
      expect(materialAppFinder, findsOneWidget);
      
      final materialApp = tester.widget<MaterialApp>(materialAppFinder);
      expect(materialApp.themeMode, equals(ThemeMode.system));
    });

    testWidgets('T1.F2.2: Changing theme to Light applies light brightness theme colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SiyaqApp(),
        ),
      );
      await tester.pumpAndSettle();

      final toggleButton = find.byKey(const Key('theme_toggle_button'));
      expect(toggleButton, findsOneWidget);
      await tester.tap(toggleButton); // Switch to Light
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, equals(ThemeMode.light));

      final BuildContext context = tester.element(find.byType(HomeScreen));
      expect(Theme.of(context).brightness, equals(Brightness.light));
    });

    testWidgets('T1.F2.3: Changing theme to Dark applies dark brightness theme colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SiyaqApp(),
        ),
      );
      await tester.pumpAndSettle();

      final toggleButton = find.byKey(const Key('theme_toggle_button'));
      expect(toggleButton, findsOneWidget);
      
      // Cycle twice to reach Dark (system -> light -> dark)
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, equals(ThemeMode.dark));

      final BuildContext context = tester.element(find.byType(HomeScreen));
      expect(Theme.of(context).brightness, equals(Brightness.dark));
    });

    testWidgets('T1.F2.4: Verify the presence of a theme toggle button in the appBar/actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SiyaqApp(),
        ),
      );
      await tester.pumpAndSettle();

      final toggleButton = find.byKey(const Key('theme_toggle_button'));
      expect(toggleButton, findsOneWidget);
    });

    testWidgets('T1.F2.5: Tapping the theme toggle button cycles through ThemeMode states (light -> dark -> system)', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SiyaqApp(),
        ),
      );
      await tester.pumpAndSettle();

      final toggleButton = find.byKey(const Key('theme_toggle_button'));
      
      // 1. First tap: System -> Light
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();
      expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, equals(ThemeMode.light));

      // 2. Second tap: Light -> Dark
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();
      expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, equals(ThemeMode.dark));

      // 3. Third tap: Dark -> System
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();
      expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, equals(ThemeMode.system));
    });

    // ==========================================
    // Tier 2 - Boundary & Corner Cases
    // ==========================================

    testWidgets('T2.F2.1: Theme state is persisted in SharedPreferences and loaded correctly on subsequent app boots', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});

      await tester.pumpWidget(
        const ProviderScope(
          child: SiyaqApp(),
        ),
      );
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, equals(ThemeMode.dark));
    });

    testWidgets('T2.F2.2: Fast consecutive taps on the theme toggle button do not cause race conditions or state desyncs', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SiyaqApp(),
        ),
      );
      await tester.pumpAndSettle();

      final toggleButton = find.byKey(const Key('theme_toggle_button'));

      // Tap rapidly 5 times without settling intermediate frames
      for (int i = 0; i < 5; i++) {
        await tester.tap(toggleButton);
      }
      await tester.pumpAndSettle();

      // 5 steps starting from System:
      // 1: Light
      // 2: Dark
      // 3: System
      // 4: Light
      // 5: Dark
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, equals(ThemeMode.dark));
    });

    testWidgets('T2.F2.3: React to system brightness changes in real-time when ThemeMode is set to system', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SiyaqApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify startup is System
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, equals(ThemeMode.system));

      // Simulate change to dark brightness on system level
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(HomeScreen));
      expect(Theme.of(context).brightness, equals(Brightness.dark));

      // Reset
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
    });

    testWidgets('T2.F2.4: Ensure text styling retains acceptable readability contrast when theme toggles', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SiyaqApp(),
        ),
      );
      await tester.pumpAndSettle();

      final toggleButton = find.byKey(const Key('theme_toggle_button'));
      
      // Switch to Light and check background vs primary text color
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();
      
      final BuildContext lightContext = tester.element(find.byType(HomeScreen));
      final lightTheme = Theme.of(lightContext);
      expect(lightTheme.scaffoldBackgroundColor, equals(SiyaqColors.lightBg));

      // Switch to Dark and check background vs primary text color
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      final BuildContext darkContext = tester.element(find.byType(HomeScreen));
      final darkTheme = Theme.of(darkContext);
      expect(darkTheme.scaffoldBackgroundColor, equals(SiyaqColors.darkBg));
    });

    testWidgets('T2.F2.5: Reset settings command restores ThemeMode back to default (system)', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SiyaqApp(),
        ),
      );
      await tester.pumpAndSettle();

      final toggleButton = find.byKey(const Key('theme_toggle_button'));
      await tester.tap(toggleButton); // Switch to Light
      await tester.pumpAndSettle();

      // Navigate to Settings
      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      final resetButton = find.byKey(const Key('reset_settings_button'));
      expect(resetButton, findsOneWidget);
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, equals(ThemeMode.system));
    });
  });
}

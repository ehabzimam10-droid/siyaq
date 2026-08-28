# Siyaq E2E Test Implementation Analysis Report

## Executive Summary
This report analyzes the Siyaq codebase structure and provides a comprehensive guide for implementing the 49 E2E test cases across Tiers 1-4. It details state provider mappings, identifies implementation gaps in theme toggling and prayer name localization, and recommends a modular testing architecture using Flutter Widget Test Harness with custom mock overrides.

---

## 1. Codebase Examination & Feature Mapping

Based on the exploration of the `lib/` directory, we mapped the target features to their corresponding files, classes, and state providers, identifying key implementation details and gaps.

### Feature 1: Arabic Locale & Date Formatting
- **Target Files**:
  - `lib/features/calendar/screens/calendar_screen.dart` (Calendar UI)
  - `lib/features/dashboard/screens/dashboard_screen.dart` (Main Dashboard UI)
  - `lib/features/dashboard/providers/schedule_provider.dart` (Date State & Providers)
- **Key Classes & Providers**:
  - `CalendarScreen` (Stateless widget rendering calendar view)
  - `selectedDateProvider`: `NotifierProvider<SelectedDateNotifier, DateTime>` which tracks the active day.
  - `prayerTimesProvider`: `FutureProvider.family<PrayerTimes, DateTime>` which resolves the daily prayer times.
- **Formatting Logic**:
  - `CalendarScreen` uses `DateFormat('EEEE', 'ar')` and `DateFormat('dd MMMM yyyy', 'ar')` to format dates in Arabic.
  - `DashboardScreen` uses `DateFormat('EEEE, d MMMM', 'ar')` to display the formatted date.
- **Critical Caveat**: There is no call to `initializeDateFormatting('ar', null)` anywhere in the application code. Under `flutter test`, this will immediately throw a `LocaleDataException` when attempting to build the widgets. Furthermore, `MaterialApp` in `lib/main.dart` is not configured with `localizationsDelegates` or `supportedLocales` for Arabic.

### Feature 2: Theme Mode Toggle
- **Target Files**:
  - `lib/main.dart` (Root app setup)
  - `lib/features/settings/providers/settings_provider.dart` (Settings State Provider)
  - `lib/features/settings/screens/settings_screen.dart` (Settings Screen UI)
- **Key Classes & Providers**:
  - `SiyaqApp` (Root widget)
  - `settingsProvider`: `NotifierProvider<SettingsNotifier, SiyaqSettings>` which handles app settings state.
- **Current State Discrepancy (Gap)**:
  - **No theme setting**: `SiyaqSettings` and `SettingsNotifier` do not manage theme state.
  - **Hardcoded MaterialApp**: `SiyaqApp` has a hardcoded `themeMode: ThemeMode.system`.
  - **No Toggle Button**: Neither `FloatingAppBar` nor `SettingsScreen` contains a toggle button to cycle or switch themes.
- **Proposed Solution**: 
  - Update `SiyaqSettings` to include `themeMode` (defaulting to `ThemeMode.system`).
  - Add `setThemeMode(ThemeMode mode)` to `SettingsNotifier`, persisting the state inside `SharedPreferences` (e.g. key: `'setting_theme_mode'`).
  - Modify `SiyaqApp` in `lib/main.dart` to extend `ConsumerWidget` and bind `themeMode` to the state watched from `settingsProvider`.
  - Add a cycle-toggle button in `FloatingAppBar` or `SettingsScreen` (cycling: `light` -> `dark` -> `system`) matching the test criteria.

### Feature 3: Frosted Glass BackdropFilter
- **Target Files**:
  - `lib/core/widgets/floating_app_bar.dart` (App Bar with dynamic blur logic)
  - `lib/core/widgets/solarium_glass_container.dart` (Frosted Glass container wrapper)
- **Key Classes & Widgets**:
  - `FloatingAppBar` (PreferredSizeWidget updating container styling on scroll)
  - `SolariumGlassContainer` (Renders the blur visual styling)
  - `ScrollController` (Passed down from screens to monitor scroll positions)
- **Blur Logic**:
  - `FloatingAppBar` registers a scroll listener. If `scrollController.offset > 5` pixels, it sets the local state `_isFloating = true`.
  - Under `_isFloating = true`, the nested `SolariumGlassContainer` is passed `blur: 25.0`, yielding non-zero blur.
  - When `scrollController.offset <= 5` pixels, `_isFloating = false` and `blur: 0.0`, rendering zero blur (completely transparent).
  - Internally, `SolariumGlassContainer` wraps a `BackdropFilter` with `ImageFilter.blur(sigmaX: blur, sigmaY: blur)`.

### Feature 4: Arabic Prayer Names on SettingsScreen
- **Target Files**:
  - `lib/features/settings/screens/settings_screen.dart` (Settings UI)
  - `lib/features/settings/providers/settings_provider.dart` (Default configs)
  - `lib/core/models/prayer_config.dart` (PrayerConfig model)
- **Key Classes & Providers**:
  - `SettingsScreen` (Displays lists of prayer configurations)
  - `settingsProvider` (Provides prayer configuration mapping)
- **Current State Discrepancy (Gap)**:
  - In `SettingsScreen`, the label is rendered using `'صلاة ${config.prayerName}'` where `config.prayerName` is English (e.g. `'Fajr'`, `'Dhuhr'`). This yields "صلاة Fajr", "صلاة Dhuhr" instead of Arabic names.
- **Proposed Solution**: 
  - Map English keys to Arabic inside `SettingsScreen` before rendering the title using a helper translation:
    ```dart
    const Map<String, String> _prayerArabicNames = {
      'fajr': 'الفجر',
      'dhuhr': 'الظهر',
      'asr': 'العصر',
      'maghrib': 'المغرب',
      'isha': 'العشاء',
    };
    ```
    Then, display `'صلاة ${_prayerArabicNames[config.prayerName.toLowerCase()] ?? config.prayerName}'`.

---

## 2. E2E Test Architecture and File Structure

We recommend organizing the E2E tests inside the `test/e2e/` folder. Since they require pumping the full widget tree and interacting with services, they are categorized as integration widget tests.

### Recommended File Directory Structure
```
siyaq/
└── test/
    └── e2e/
        ├── locale_e2e_test.dart        # Feature 1: Arabic Locale & Dates
        ├── theme_e2e_test.dart         # Feature 2: Theme Toggle & Persistence
        ├── frosted_glass_e2e_test.dart  # Feature 3: Scroll & Frosted Glass Blur
        ├── prayer_names_e2e_test.dart   # Feature 4: Arabic Prayer Names & Sliders
        ├── combined_e2e_test.dart       # Cross-Feature & Real Scenarios (Tiers 3-4)
        └── helpers/
            └── test_helper.dart         # Shared mocks and test setup utilities
```

### Necessary Packages & Imports
To write these tests, the following packages are required in the test files:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Project imports
import 'package:siyaq/main.dart';
import 'package:siyaq/features/settings/providers/settings_provider.dart';
import 'package:siyaq/features/dashboard/providers/schedule_provider.dart';
import 'package:siyaq/core/services/prayer_service.dart';
import 'package:siyaq/core/models/prayer_times.dart';
import 'package:siyaq/core/widgets/solarium_glass_container.dart';
import 'package:siyaq/features/calendar/screens/calendar_screen.dart';
```

---

## 3. Test Harness Setup & Mocking Strategy

To isolate the E2E tests from system-dependent side effects (such as physical files and network calls), we override specific Riverpod providers and mock third-party libraries.

### 1. Mocking SharedPreferences
Flutter's `shared_preferences` package provides a built-in mock backend. Call this in the `setUp` hook of every test file:
```dart
setUp(() {
  SharedPreferences.setMockInitialValues({
    // Pre-populate keys to prevent runtime settings lookup empty states
    'setting_gemini_key': 'test_gemini_key',
    'setting_openai_key': 'test_openai_key',
    'setting_ramadan_mode': false,
  });
});
```

### 2. Mocking PrayerService
Since `PrayerService` makes external API requests to `api.aladhan.com`, we should replace it with a mock that returns fixed times instantly. This speeds up tests and removes internet dependencies.
Create a class in `test/e2e/helpers/test_helper.dart`:
```dart
class MockPrayerService implements PrayerService {
  @override
  Future<PrayerTimes> getPrayerTimes(DateTime date) async {
    final y = date.year;
    final m = date.month;
    final d = date.day;
    final dateStr = DateFormat('dd-MM-yyyy').format(date);
    
    return PrayerTimes(
      fajr: DateTime(y, m, d, 4, 30),
      sunrise: DateTime(y, m, d, 5, 50),
      dhuhr: DateTime(y, m, d, 12, 10),
      asr: DateTime(y, m, d, 15, 30),
      maghrib: DateTime(y, m, d, 18, 45),
      isha: DateTime(y, m, d, 20, 15),
      dateString: dateStr,
    );
  }
}
```

### 3. Pumping Widgets and Riverpod Scope
To run the full app inside tests, we pump `SiyaqApp` inside a `ProviderScope` containing the mock provider overrides:
```dart
Widget createTestableWidget() {
  return ProviderScope(
    overrides: [
      prayerServiceProvider.overrideWith((ref) => MockPrayerService()),
    ],
    child: const MaterialApp(
      title: 'سياق',
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('ar'),
        Locale('en'),
      ],
      locale: Locale('ar'),
      home: SiyaqApp(),
    ),
  );
}
```
*Note: We wrap with explicit localization delegates and force the locale to `'ar'` to test the Arabic localizations.*

---

## 4. Decomposed Test Case Implementation Strategies

Below are code patterns and logic steps to implement the specific test tiers outlined in the test infrastructure.

### Tier 1 & 2: Feature 1 (Arabic Locale & Date Formatting)
To verify dates display in Arabic without crashing on startup:
```dart
void main() {
  setUpAll(() async {
    // 1. Initialise the Arabic date format symbols to prevent LocaleDataException
    await initializeDateFormatting('ar', null);
  });

  testWidgets('T1.F1.1: App starts and loads Calendar Screen without crashing', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    // 2. Navigate to Calendar Screen via Bottom Navigation Bar
    final calendarTab = find.text('التقويم');
    expect(calendarTab, findsOneWidget);
    await tester.tap(calendarTab);
    await tester.pumpAndSettle();

    // 3. Confirm CalendarScreen is rendered by checking widgets or specific text
    expect(find.byType(CalendarScreen), findsOneWidget);
  });

  testWidgets('T1.F1.2 & T1.F1.3: EEEE and dd MMMM formatters render correct Arabic texts', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    // Go to calendar tab
    await tester.tap(find.text('التقويم'));
    await tester.pumpAndSettle();

    // Check if the current day name and date exist in the date display
    final now = DateTime.now();
    final expectedDay = DateFormat('EEEE', 'ar').format(now);
    final expectedMonthDate = DateFormat('dd MMMM yyyy', 'ar').format(now);

    expect(find.text(expectedDay), findsOneWidget);
    expect(find.text(expectedMonthDate), findsOneWidget);
  });
}
```

### Tier 1 & 2: Feature 2 (Theme Mode Toggle)
Assuming the theme provider state gap is closed by implementing `themeMode` in `settingsProvider`, here is how to test toggles and persistence:
```dart
testWidgets('T1.F2.5 & T2.F2.1: Tapping theme toggle cycles states and persists in SharedPreferences', (WidgetTester tester) async {
  // Prep mock shared preferences values
  SharedPreferences.setMockInitialValues({'setting_theme_mode': 'system'});

  await tester.pumpWidget(createTestableWidget());
  await tester.pumpAndSettle();

  // Find theme toggle button (using key 'theme_toggle_button')
  final toggleBtn = find.byKey(const Key('theme_toggle_button'));
  expect(toggleBtn, findsOneWidget);

  // 1. Verify initial mode matches (e.g., System)
  // 2. Tap to cycle -> Light mode
  await tester.tap(toggleBtn);
  await tester.pumpAndSettle();
  
  // Verify brightness is Light
  var app = tester.widget<MaterialApp>(find.byType(MaterialApp));
  expect(app.themeMode, ThemeMode.light);

  // 3. Tap to cycle -> Dark mode
  await tester.tap(toggleBtn);
  await tester.pumpAndSettle();
  
  app = tester.widget<MaterialApp>(find.byType(MaterialApp));
  expect(app.themeMode, ThemeMode.dark);

  // 4. Verify value was updated in SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  expect(prefs.getString('setting_theme_mode'), 'dark');
});
```

### Tier 1 & 2: Feature 3 (Frosted Glass Effect)
To test the dynamic blur transitions on the app bar when scrolling:
```dart
testWidgets('T1.F3.3 & T1.F3.4: Scroll offsets toggle frosted glass blur dynamically', (WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(createTestableWidget());
  await tester.pumpAndSettle();

  // Find BackdropFilter widget inside FloatingAppBar
  // Initially, scroll offset is 0.0, blur must be 0.0
  var glassContainers = tester.widgetList<SolariumGlassContainer>(find.byType(SolariumGlassContainer));
  // Find the one corresponding to FloatingAppBar
  final appBarContainer = glassContainers.first;
  expect(appBarContainer.blur, 0.0);

  // Scroll down the main Dashboard list view to trigger floating blur state
  final listFinder = find.byType(ListView).first;
  await tester.drag(listFinder, const Offset(0.0, -100.0)); // Scroll down 100 pixels
  await tester.pumpAndSettle(); // Settle animation container (300ms transition)

  // Verify blur is now 25.0
  final updatedContainers = tester.widgetList<SolariumGlassContainer>(find.byType(SolariumGlassContainer));
  final updatedAppBarContainer = updatedContainers.first;
  expect(updatedAppBarContainer.blur, 25.0);

  // Scroll back to top
  await tester.drag(listFinder, const Offset(0.0, 100.0)); // Scroll up 100 pixels
  await tester.pumpAndSettle();

  // Verify blur returns to 0.0
  final finalContainers = tester.widgetList<SolariumGlassContainer>(find.byType(SolariumGlassContainer));
  expect(finalContainers.first.blur, 0.0);
});
```

### Tier 1 & 2: Feature 4 (Arabic Prayer Names on Settings Screen)
Assuming the translation helper fix is applied in the `SettingsScreen` UI layer:
```dart
testWidgets('T1.F4.1 - T1.F4.5: Verify Settings Screen renders prayer configuration in Arabic', (WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(createTestableWidget());
  await tester.pumpAndSettle();

  // Go to Settings Screen
  await tester.tap(find.text('الإعدادات'));
  await tester.pumpAndSettle();

  // Check section header
  expect(find.text('تخصيص أوقات الصلوات والعبادة'), findsOneWidget);

  // Verify individual prayer names are rendered in Arabic
  expect(find.text('صلاة الفجر'), findsOneWidget);
  expect(find.text('صلاة الظهر'), findsOneWidget);
  expect(find.text('صلاة العصر'), findsOneWidget);
  expect(find.text('صلاة المغرب'), findsOneWidget);
  expect(find.text('صلاة العشاء'), findsOneWidget);
});
```

### Tier 3 & 4: Multi-Feature and User Scenarios
Combining navigation, tasks, and state transitions:
```dart
testWidgets('T4.2 (Theme & Settings Persistence Flow)', (WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({'setting_theme_mode': 'light'});
  await tester.pumpWidget(createTestableWidget());
  await tester.pumpAndSettle();

  // 1. Toggle Theme to Dark
  final toggleBtn = find.byKey(const Key('theme_toggle_button'));
  await tester.tap(toggleBtn); // Cycles light -> dark
  await tester.pumpAndSettle();

  // 2. Navigate to Settings Screen
  await tester.tap(find.text('الإعدادات'));
  await tester.pumpAndSettle();

  // 3. Find Fajr offset slider
  // In SettingsScreen, look for the Slider widgets
  final sliders = find.byType(Slider);
  expect(sliders, findsAtLeastNWidgets(2)); // Offset and duration sliders for 5 prayers
  
  // Drag the first slider (Fajr offset) to change values
  await tester.drag(sliders.first, const Offset(50.0, 0.0));
  await tester.pumpAndSettle();

  // 4. Verify settings persistence
  final prefs = await SharedPreferences.getInstance();
  expect(prefs.getString('setting_theme_mode'), 'dark');
});
```

---

## 5. Verification Command Summary

To execute and verify these test cases:
1. Ensure the Dart SDK package references are resolved:
   ```cmd
   C:\tools\flutter\bin\flutter.bat pub get
   ```
2. Execute the entire test suite:
   ```cmd
   C:\tools\flutter\bin\flutter.bat test
   ```
3. Run specific test files to check feature sets individually:
   ```cmd
   C:\tools\flutter\bin\flutter.bat test test/e2e/locale_e2e_test.dart
   C:\tools\flutter\bin\flutter.bat test test/e2e/theme_e2e_test.dart
   C:\tools\flutter\bin\flutter.bat test test/e2e/frosted_glass_e2e_test.dart
   C:\tools\flutter\bin\flutter.bat test test/e2e/prayer_names_e2e_test.dart
   C:\tools\flutter\bin\flutter.bat test test/e2e/combined_e2e_test.dart
   ```

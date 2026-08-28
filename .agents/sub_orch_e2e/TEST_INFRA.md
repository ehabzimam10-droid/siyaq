# E2E Test Infra: Siyaq

## Test Philosophy
- **Opaque-Box Testing**: Verify features by building the app widget tree and interacting with it as a user would (taps, scrolls, inputs, and navigation).
- **Requirement-Driven**: Tests are based strictly on user-facing requirements:
  - Startup must not crash due to uninitialized locales (Arabic dates).
  - Theme mode must cycle between light, dark, and system, reflecting on the UI.
  - Frosted glass effect must activate on scroll and apply a blur filter to content beneath the FloatingAppBar.
  - Settings screen must display Arabic prayer names instead of English.

## Feature Inventory
| # | Feature | Target Widget/Module | Key Validation |
|---|---------|----------------------|----------------|
| 1 | Arabic Locale/Date formatting | `CalendarScreen`, `main.dart` | Avoid `LocaleDataException`, format EEEE/dd MMMM in Arabic. |
| 2 | Theme Mode Toggle | `FloatingAppBar`, `SettingsNotifier`, `SiyaqApp` | Switch theme (light/dark/system) and update widget style. |
| 3 | Frosted Glass Effect | `FloatingAppBar`, `SolariumGlassContainer` | Scroll list to toggle blur/opacity on appBar container. |
| 4 | Arabic Prayer Names | `SettingsScreen`, `PrayerConfig` | Show "الفجر", "الظهر", "العصر", "المغرب", "العشاء". |

## Test Architecture
- **Test Runner**: Flutter Widget Test Harness (`flutter test`).
- **Target Files**:
  - `test/e2e/locale_e2e_test.dart` (Feature 1 tests)
  - `test/e2e/theme_e2e_test.dart` (Feature 2 tests)
  - `test/e2e/frosted_glass_e2e_test.dart` (Feature 3 tests)
  - `test/e2e/prayer_names_e2e_test.dart` (Feature 4 tests)
  - `test/e2e/combined_e2e_test.dart` (Tiers 3 and 4 tests)
- **Invocation Command**: `flutter test`

---

## Decomposed Test Cases (Tiers 1-4)

### Tier 1 - Feature Coverage (20 tests)
#### Feature 1: Arabic Locale & Dates
- **T1.F1.1**: App starts and navigates to Calendar Screen without throwing `LocaleDataException`.
- **T1.F1.2**: EEEE date format displays Arabic day names (e.g. "الجمعة", "السبت").
- **T1.F1.3**: dd MMMM yyyy format displays Arabic month names (e.g. "يوليو", "أغسطس").
- **T1.F1.4**: Arabic locale is correctly propagated to DateFormat formatters without default fallback issues.
- **T1.F1.5**: Initial app load configures Global Material Localizations for Arabic.

#### Feature 2: Theme Mode Toggle
- **T1.F2.1**: Verify default system theme starts correctly in MaterialApp.
- **T1.F2.2**: Changing theme to Light applies light brightness theme colors.
- **T1.F2.3**: Changing theme to Dark applies dark brightness theme colors.
- **T1.F2.4**: Verify the presence of a theme toggle button in the appBar/actions.
- **T1.F2.5**: Tapping the theme toggle button cycles through ThemeMode states (light -> dark -> system).

#### Feature 3: Frosted Glass Effect
- **T1.F3.1**: Verify FloatingAppBar utilizes a `BackdropFilter` widget.
- **T1.F3.2**: BackdropFilter has `sigmaX` and `sigmaY` blur values matching the target state.
- **T1.F3.3**: Scroll offset at 0.0 results in zero blur (completely transparent/no glass style).
- **T1.F3.4**: Scroll offset greater than 5.0 results in non-zero blur (glass style active).
- **T1.F3.5**: FloatingAppBar remains interactive and visible under blurred states.

#### Feature 4: Arabic Prayer Names
- **T1.F4.1**: Verify Settings Screen renders the prayer customization header "تخصيص أوقات الصلوات والعبادة".
- **T1.F4.2**: Verify the Fajr prayer displays Arabic label "صلاة الفجر".
- **T1.F4.3**: Verify the Dhuhr prayer displays Arabic label "صلاة الظهر".
- **T1.F4.4**: Verify the Asr prayer displays Arabic label "صلاة العصر".
- **T1.F4.5**: Verify Maghrib and Isha prayers display Arabic labels "صلاة المغرب" and "صلاة العشاء".

---

### Tier 2 - Boundary & Corner Cases (20 tests)
#### Feature 1: Arabic Locale & Dates
- **T2.F1.1**: Verify date formatting handles Leap Years (e.g. Feb 29) without crashing or failing.
- **T2.F1.2**: Verify date formatting handles dates far in the future (e.g., year 2036).
- **T2.F1.3**: Verify date formatting handles past dates correctly.
- **T2.F1.4**: Verify rapid switching between calendar days does not cause rendering lags or formatting failures.
- **T2.F1.5**: Verify that date picker dialog uses localizations corresponding to Arabic locale.

#### Feature 2: Theme Mode Toggle
- **T2.F2.1**: Theme state is persisted in SharedPreferences and loaded correctly on subsequent app boots.
- **T2.F2.2**: Fast consecutive taps on the theme toggle button do not cause race conditions or state desyncs.
- **T2.F2.3**: React to system brightness changes in real-time when ThemeMode is set to system.
- **T2.F2.4**: Ensure text styling retains acceptable readability contrast when theme toggles.
- **T2.F2.5**: Reset settings command restores ThemeMode back to default (system).

#### Feature 3: Frosted Glass Effect
- **T2.F3.1**: Scroll offset exactly at the transition boundary (5.0) behaves deterministically.
- **T2.F3.2**: Scroll offset at extremely high values (e.g. 5000.0) clamps blur and does not overflow or crash.
- **T2.F3.3**: Rapid scrolling up and down updates the glass background blur smoothly.
- **T2.F3.4**: A completely empty non-scrollable list keeps the frosted glass effect disabled.
- **T2.F3.5**: Resize or screen orientation changes update FloatingAppBar margins without breaking layout.

#### Feature 4: Arabic Prayer Names
- **T2.F4.1**: Settings reset keeps prayer names displayed in Arabic.
- **T2.F4.2**: Prayer offsets slider handles negative limit (-20) and positive limit (+20) updates correctly.
- **T2.F4.3**: Prayer duration slider handles min limit (10) and max limit (60) updates correctly.
- **T2.F4.4**: Slider adjustments for all prayers update their state concurrently without layout constraints.
- **T2.F4.5**: Scroll Settings Screen to ensure all 5 prayer configuration cards are reachable and interactable.

---

### Tier 3 - Cross-Feature Combinations (4 tests)
- **T3.1 (Locale + Theme)**: Navigate to Calendar (ar locale formatted) and cycle theme mode, verifying date strings update colors/fonts without loosing Arabic values.
- **T3.2 (Theme + Blur)**: Toggle dark mode, scroll Settings Screen to trigger blur, and verify appBar BackdropFilter colors blend correctly with dark theme styling.
- **T3.3 (Locale + Scroll + Dialog)**: Scroll Calendar Screen to trigger blur, open DatePicker dialog, verify localization in dialog matches, and close it without affecting appBar state.
- **T3.4 (Prayer settings + Theme)**: Switch to Dark theme, navigate to settings, verify Arabic prayer titles and sliders reflect dark mode colors.

---

### Tier 4 - Real-World Application Scenarios (5 tests)
- **T4.1 (User Onboarding Flow)**: App launches safely -> navigates to Calendar (verifying Arabic date labels) -> select a date -> verify no crashes.
- **T4.2 (Theme & Settings Configuration)**: User launches app, toggles theme to Dark, navigates to settings, scrolls to prayers, adjusts Fajr offset to +10, verifies UI displays correct text, and checks if settings persist.
- **T4.3 (Calendar Interaction & Scrolling)**: User navigates to Calendar, scrolls down to see schedule, verifies frosted glass effect activates, opens Task addition sheet, adds a custom task, and verifies the list updates.
- **T4.4 (Continuous Theme & Blur performance)**: Cycle through all theme modes while repeatedly scrolling page up and down, verifying BackdropFilter handles rapid changes gracefully.
- **T4.5 (Complete Settings Adjustments)**: Go to Settings Screen, adjust offsets for all 5 prayers, toggle theme mode, scroll down, verify the application version card, and return to main dashboard.

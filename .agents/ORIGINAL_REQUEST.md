# Original User Request

## Initial Request — 2026-07-10T18:12:53Z

# Teamwork Project Prompt — Draft

> Status: Launched
> Goal: Fix core UI/UX and localization bugs in the Siyaq Flutter App

Fix 4 specific bugs in a Flutter Riverpod application (Siyaq) to improve the UI/UX and localization.

Working directory: c:/Users/ehabz/OneDrive/المستندات/projects/siyaq

## Requirements

### R1. Fix LocaleDataException
Initialize the `intl` package for Arabic date formatting in `main.dart` to prevent the red screen error on startup.

### R2. Implement Theme Mode Toggle
Add a `themeMode` state to the existing `SettingsNotifier` (light/dark/system). Connect it to `SiyaqApp` in `main.dart`. Add a UI toggle button in `FloatingAppBar` to switch themes. Ensure `SiyaqColors` work for both modes.

### R3. Fix Frosted Glass Effect on FloatingAppBar
Adjust `FloatingAppBar` and `SolariumGlassContainer` so that when `_isFloating` is true, the `BackdropFilter` correctly blurs the background content scrolling underneath it. Ensure the background color of the glass container has opacity to allow the blur to be visible.

### R4. Arabic Prayer Names
Update `SettingsScreen` to display the prayer names in Arabic (الفجر، الظهر، العصر، المغرب، العشاء) instead of English.

## Acceptance Criteria

### Verification
- [ ] App launches without `LocaleDataException`.
- [ ] Toggling the theme changes the app's colors instantly between Light and Dark mode.
- [ ] Scrolling down the screen causes the `FloatingAppBar` to apply a frosted glass blur effect to the content beneath it.
- [ ] Prayer names in `SettingsScreen` are strictly in Arabic.

## Follow-up — 2026-07-11T05:26:40Z

# Teamwork Project Prompt — Draft

> Status: Launched
> Goal: Fix remaining UI/UX bugs, implement Dark/Light theme toggle, and fix frosted glass effect in Siyaq App.

Working directory: c:/Users/ehabz/OneDrive/المستندات/projects/siyaq
Integrity mode: development

Note: The user has already fixed the `LocaleDataException` by adding `initializeDateFormatting('ar', null)` and localized MaterialApp delegates in `lib/main.dart` and updated `test/widget_test.dart` to use `ProviderScope`.

## Requirements

### R1. Theme Mode Toggle (Dark / Light Mode)
- Implement a way to toggle between Light and Dark mode.
- Save the selection in the app's settings using the existing Riverpod provider `settingsProvider` in `lib/features/settings/providers/settings_provider.dart` and persist it via `SharedPreferences`.
- Connect the selected theme mode to `SiyaqApp` in `lib/main.dart` so it respects the user's manual selection (or defaults to system).
- Add a theme toggle button (moon/sun icon) in the `FloatingAppBar` (or next to the notifications button) that transitions instantly.
- Ensure all screens use the theme colors correctly from `SiyaqColors` (backgrounds, glass cards, texts) based on the active theme mode.

### R2. Frosted Glass (Liquid Glass) Effect
- Fix the `BackdropFilter` implementation in `FloatingAppBar` (`lib/core/widgets/floating_app_bar.dart`) and `SolariumGlassContainer` (`lib/core/widgets/solarium_glass_container.dart`).
- When scrolled down (`_isFloating` is true), the appBar must blur the text and elements scrolling behind/underneath it with a sleek, glass-like frosted visual look.
- Ensure the background color opacity is low enough to make the blur clearly visible.

### R3. Arabic Prayer Names in Settings
- Update the prayer configuration slider UI in `lib/features/settings/screens/settings_screen.dart` to show prayer names in proper Arabic:
  - 'Fajr' -> 'صلاة الفجر'
  - 'Dhuhr' -> 'صلاة الظهر'
  - 'Asr' -> 'صلاة العصر'
  - 'Maghrib' -> 'صلاة المغرب'
  - 'Isha' -> 'صلاة العشاء'
  - Do not use mixed strings like 'Fajr صلاة'. Translate the UI display dynamically while keeping data keys consistent.

## Acceptance Criteria

### Verification Checklist
- [ ] Changing the theme mode via the top bar toggle switches the app's theme (colors of backgrounds, cards, and texts) instantly.
- [ ] Theme mode preference is persisted on app restart.
- [ ] When scrolling content under the `FloatingAppBar`, the content behind it is blurred (frosted glass effect is visible).
- [ ] Prayer sliders in Settings display "صلاة الفجر", "صلاة الظهر", etc., instead of English names or mixed names.
- [ ] No compilation errors and `npm run dev` / `flutter run` starts successfully.

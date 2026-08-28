# Project: Siyaq Bug Fixes & Improvements

## Architecture
Siyaq is a Flutter application using Riverpod for state management.
- `lib/main.dart`: App entry point.
- `lib/core/theme/`: Theme definitions.
- `lib/core/widgets/`: Core reusable widgets (e.g. FloatingAppBar, SolariumGlassContainer).
- `lib/features/settings/`: App settings screen and providers.

## Milestones
| # | Name | Scope | Dependencies | Status | Conversation ID |
|---|------|-------|-------------|--------|-----------------|
| 1 | E2E Testing Suite | Create E2E test infra and test cases (Tiers 1-4) in test folder. Publish `TEST_READY.md`. | none | IN_PROGRESS | 00570925-2c24-433b-824c-e0ea0cf20211 |
| 2 | R1: Fix LocaleDataException | Initialize `intl` for Arabic date formatting in `main.dart`. | none | DONE | 48d57925-48eb-41a8-b99e-562e120a52e4 |
| 3 | R2: Implement Theme Mode Toggle | Add themeMode to `SettingsNotifier`, connect to `SiyaqApp`, add toggle to `FloatingAppBar`. | R1 | IN_PROGRESS | ff307c95-4b56-47e3-ba4f-2bc60f75b6f7 |
| 4 | R3: Fix Frosted Glass Effect | Ensure `FloatingAppBar` blurs content scrolling underneath using `BackdropFilter` and opacity. | R2 | IN_PROGRESS | ff307c95-4b56-47e3-ba4f-2bc60f75b6f7 |
| 5 | R4: Arabic Prayer Names | Display Arabic prayer names instead of English in `SettingsScreen`. | R1 | IN_PROGRESS | ff307c95-4b56-47e3-ba4f-2bc60f75b6f7 |
| 6 | E2E Pass & Adversarial Hardening | Verify all tests pass, perform white-box coverage hardening (Tier 5). | M1, M2, M3, M4, M5 | PLANNED | TBD |

## Interface Contracts
- **SettingsNotifier State**: Expose themeMode (light, dark, system).
- **SiyaqApp**: Listen to themeMode from SettingsNotifier and apply it to MaterialApp's themeMode property.
- **FloatingAppBar theme toggle**: Triggers SettingsNotifier to toggle the theme.
- **Arabic Prayer Names translation**: SettingsScreen uses Arabic strings for prayer names.

## Code Layout
- `lib/main.dart`
- `lib/core/theme/colors.dart`
- `lib/core/theme/theme.dart`
- `lib/core/widgets/floating_app_bar.dart`
- `lib/core/widgets/solarium_glass_container.dart`
- `lib/features/settings/providers/settings_provider.dart`
- `lib/features/settings/screens/settings_screen.dart`

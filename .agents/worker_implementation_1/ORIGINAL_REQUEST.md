## 2026-07-11T05:56:01Z
You are a worker agent. Your task is to fix the remaining UI/UX and localization bugs in the Siyaq Flutter App based on requirements R1 (Theme Mode Toggle), R2 (Frosted Glass Effect), R3 (Arabic Prayer Names in Settings).

Please perform the following tasks:
1. Run the existing test suite using `flutter test` in `c:/Users/ehabz/OneDrive/المستندات/projects/siyaq` to verify the initial state.
2. Apply the following implementation changes:
   - In `lib/features/settings/providers/settings_provider.dart`:
     Add a `resetSettings()` method to `SettingsNotifier` that clears SharedPreferences keys (`setting_theme_mode`, `setting_prayer_configs`, `setting_gemini_key`, `setting_openai_key`, `setting_ramadan_mode`) and resets the notifier state to default values.
   - In `lib/core/widgets/floating_app_bar.dart`:
     - Add `key: const Key('theme_toggle_button')` to the theme toggle `IconButton`.
     - Update its `onPressed` logic to cycle the theme mode: `system` -> `light` -> `dark` -> `system` using `settings.themeMode` from `settingsProvider`.
   - In `lib/features/settings/screens/settings_screen.dart`:
     - Add a Reset Settings button with `key: const Key('reset_settings_button')` that calls `ref.read(settingsProvider.notifier).resetSettings()`. Place it as a `TextButton.icon` next to the 'تخصيص أوقات الصلوات والعبادة' header (inside a Row).
   - In `lib/core/widgets/solarium_glass_container.dart`:
     - Disable the `LinearGradient` in the container's decoration if `customBgColor` is set to `Colors.transparent`, to ensure complete transparency.
3. Run the test suite again using `flutter test` to verify all tests (including `locale_e2e_test.dart`, `theme_e2e_test.dart`, `frosted_glass_e2e_test.dart`, `prayer_names_e2e_test.dart`, `combined_e2e_test.dart`) pass successfully.
4. Create and write `TEST_READY.md` at the project root `c:/Users/ehabz/OneDrive/المستندات/projects/siyaq/TEST_READY.md` using the template provided in the Project Pattern of the system prompt.
5. Provide a detailed handoff report in your working directory (`c:/Users/ehabz/OneDrive/المستندات/projects/siyaq/.agents/worker_implementation_1/handoff.md`) with command outputs, test results, and details of modified files.

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

## 2026-07-10T18:44:33Z
You are a Worker subagent. Your working directory is c:\Users\ehabz\OneDrive\المستندات\projects\siyaq\.agents\teamwork_preview_worker_e2e_1.
Your mission is to write the complete E2E test suite for Siyaq in the `test/e2e/` folder, containing exactly the 49 tests mapped in `c:\Users\ehabz\OneDrive\المستندات\projects\siyaq\.agents\sub_orch_e2e\TEST_INFRA.md`.

MANDATORY INTEGRITY WARNING:
> DO NOT CHEAT. All implementations must be genuine. DO NOT
> hardcode test results, create dummy/facade implementations, or
> circumvent the intended task. A Forensic Auditor will independently
> verify your work. Integrity violations WILL be detected and your
> work WILL be rejected.

### Instructions:
1. Create the `test/e2e/` directory and implement the following test files:
   - `test/e2e/helpers/test_helper.dart`: Includes `MockPrayerService` (mocking `PrayerService`) and `createTestableWidget(Widget child)` (providing `ProviderScope` with the mocked overrides and localization settings).
   - `test/e2e/locale_e2e_test.dart`: 5 Tier 1 and 5 Tier 2 tests for Arabic Locale & Date formatting (T1.F1.1 to T1.F1.5, T2.F1.1 to T2.F1.5).
   - `test/e2e/theme_e2e_test.dart`: 5 Tier 1 and 5 Tier 2 tests for Theme Mode Toggle (T1.F2.1 to T1.F2.5, T2.F2.1 to T2.F2.5).
   - `test/e2e/frosted_glass_e2e_test.dart`: 5 Tier 1 and 5 Tier 2 tests for Frosted Glass BackdropFilter (T1.F3.1 to T1.F3.5, T2.F3.1 to T2.F3.5).
   - `test/e2e/prayer_names_e2e_test.dart`: 5 Tier 1 and 5 Tier 2 tests for Arabic Prayer Names (T1.F4.1 to T1.F4.5, T2.F4.1 to T2.F4.5).
   - `test/e2e/combined_e2e_test.dart`: 4 Tier 3 cross-feature tests (T3.1 to T3.4) and 5 Tier 4 real-world application tests (T4.1 to T4.5).

2. Make sure all tests compile and reference existing code (e.g. `SiyaqApp`, `settingsProvider`, etc.). Where UI elements like the theme toggle button do not exist yet in the codebase, write the finder lookups as expected (e.g. `find.byKey(const Key('theme_toggle_button'))`) so that the tests will fail gracefully on the current broken app, rather than failing to compile.
3. Run the E2E test suite using the command:
   `C:\tools\flutter\bin\flutter.bat test test/e2e/`
   (Note: some tests will fail on the current broken app, which is expected. Verify that the tests compile and run, and log the test output).
4. Document the exact test code and execution results in `handoff.md` in your working directory and send a message when done.

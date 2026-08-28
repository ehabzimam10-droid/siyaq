# Scope: R1 - Fix LocaleDataException

## Architecture
- In `lib/main.dart`, the `intl` package needs to be initialized for Arabic date formatting before running/building the app.
- We need to import the required initialization methods and run them in `main()`.

## Milestones
- R1 Implementation: Explorer -> Worker -> Reviewer -> Auditor cycle to fix `LocaleDataException`.
- Verification: Clean compile, no startup LocaleDataException.

## Interface Contracts
- None.

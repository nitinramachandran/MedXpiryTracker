# MedXpiryTracker — Agent Context

Auto-maintained by `/speckit.plan` (via `.specify/scripts/bash/update-agent-context.sh`).
Hand edits between the MANUAL ADDITIONS markers are preserved.

MedXpiryTracker (target "Medicine Date Alerter", brand "PillEye") is a privacy-first iPhone app:
scan or type a medicine's name and manufacturing/expiry dates, then get a local reminder before it
expires. All data stays on-device.

## Active Technologies
- Swift 5.9+ / Xcode 16+, SwiftUI, Swift Concurrency, Observation (`@Observable`)
- VisionKit (`DataScannerViewController`) for on-device OCR
- UserNotifications for local reminders; CoreTransferable + UniformTypeIdentifiers for backups
- Testing framework (unit) + XCUIAutomation (UI); `Medicine Date Alerter.xctestplan`

## Project Structure
```
Medicine Date Alerter/            # app sources + entry (Medicine_Date_AlerterApp, ContentView)
*.swift                           # Medicine, MedicineStore, parsers, schedulers, views (repo root)
Medicine Date AlerterTests/       # unit tests
Medicine Date AlerterUITests/     # UI tests
.specify/                         # constitution, templates, SDD scripts
.claude/commands/                 # /speckit.* slash commands
specs/                            # feature specs, plans, tasks
```

## Development Workflow (Spec-Driven Development)
All non-trivial changes go through SpecKit. Do NOT vibe-code new features directly.
1. `/speckit.specify "<what & why>"` → creates `specs/<n>-<slug>/spec.md` on a new branch.
2. `/speckit.clarify` → resolve ambiguities.
3. `/speckit.plan` → technical plan + Constitution Check (`.specify/memory/constitution.md`).
4. `/speckit.tasks` → ordered, test-first task list.
5. `/speckit.analyze` → consistency/coverage check.
6. `/speckit.implement` → build it, honoring the constitution.

See `specs/001-medicine-expiry-tracker/` for the worked example covering the current app.

## Code Style (see .specify/memory/constitution.md for the binding rules)
- On-device only: no network, no analytics. Sandbox storage with `.completeFileProtection`;
  notifications carry only a medicine `UUID`.
- Keep correctness logic pure and unit-tested; inject system boundaries via protocols
  (`NotificationScheduling`), test-first.
- SwiftUI + async/await only — no Combine. Stores are `@MainActor @Observable`; never block the
  main actor on launch.
- Codable stays forward-compatible (`decodeIfPresent` defaults; don't remove persisted fields).
- Reuse `PillEyePalette` and `DimensionalButtonStyle`; keep light mode + portrait; give interactive
  elements stable `accessibilityIdentifier`s.

## Recent Changes
- 001-medicine-expiry-tracker: retro-specified the shipped app (scan/save/remind, backup, edit lead).

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->

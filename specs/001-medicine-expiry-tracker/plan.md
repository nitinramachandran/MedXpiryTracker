# Implementation Plan: Medicine Expiry Tracker

**Branch**: `001-medicine-expiry-tracker` | **Date**: 2026-08-21 | **Spec**: [spec.md](./spec.md)
**Input**: `specs/001-medicine-expiry-tracker/spec.md`

## Summary
Deliver an on-device iPhone app to capture medicines (name + manufacturing/expiry dates) via camera
OCR or manual entry, persist them locally, and fire local notifications a configurable lead time
before expiry. The design keeps all correctness-critical logic (date parsing, validation, reminder
math) in pure, unit-testable types, and hides system boundaries (notifications, disk) behind a
protocol so tests and previews use fakes.

## Technical Context
**Language/Version**: Swift 5.9+ (Xcode 16+)
**Primary Frameworks**: SwiftUI, Swift Concurrency, Observation, VisionKit (`DataScannerViewController`),
UserNotifications, CoreTransferable, UniformTypeIdentifiers
**Storage**: JSON file in Application Support (app sandbox), `.completeFileProtection`
**Testing**: Testing framework (unit), XCUIAutomation (UI); `Medicine Date Alerter.xctestplan`
**Target Platform**: iPhone, portrait, light mode
**Project Type**: Single iOS app target
**Performance Goals**: No main-actor blocking on launch; disk load runs off-main
**Constraints**: On-device only, no network/accounts; camera & notification permissions requested lazily
**Scale/Scope**: One screen + scanner sheet + three center popups; ~12 source files

## Constitution Check
*GATE: passed initial and post-design.*

| Principle | Compliant? | Notes |
|-----------|-----------|-------|
| I. On-Device Privacy First | [x] | No network; sandbox + complete file protection; notifications carry only medicine `UUID` |
| II. Testable Core, Injected Boundaries | [x] | `MedicineDateParser`, `MedicineValidator`, `Medicine.reminderDate` are pure; `NotificationScheduling` protocol + optional storage URL enable fakes |
| III. Native SwiftUI + Structured Concurrency | [x] | `@Observable @MainActor MedicineStore`; async/await throughout; no Combine; detached disk load |
| IV. Forward-Compatible Persistence | [x] | `Medicine.init(from:)` uses `decodeIfPresent` for `reminderLeadDays`, ignores legacy `snoozeMinutes`; ISO-8601, sorted keys |
| V. Accessible, Consistent Design System | [x] | `PillEyePalette` + `DimensionalButtonStyle`; light mode + portrait locked; stable identifiers |
| VI. Simplicity & Scope Discipline | [x] | No third-party dependencies; `MedicineUpdate` models near-term edit reuse, not speculation |

**Violations**: none.

## Project Structure

### Documentation
```
specs/001-medicine-expiry-tracker/
├── plan.md          # This file
├── spec.md          # Feature specification
├── research.md      # Phase 0 decisions
├── data-model.md    # Medicine / Reminder / Backup
├── quickstart.md    # Manual validation steps
└── tasks.md         # Ordered task list
```

### Source (repository root)
```
Medicine Date Alerter/
  Medicine Date Alerter/
    Medicine_Date_AlerterApp.swift   # @main entry, app-delegate adaptor
    ContentView.swift                # Main form, popups, design system (PillEyePalette)
    Assets.xcassets
  Medicine.swift                     # Medicine, MedicineUpdate, MedicineValidator
  MedicineStore.swift                # @Observable store, persistence, backup, MedicineBackupFile
  NotificationScheduler.swift        # NotificationScheduling + LocalNotificationScheduler
  AppNotificationDelegate.swift      # Snooze/Cancel/tap handling, orientation lock
  MedicineNotificationRoute.swift    # Notification → view routing
  AlarmNotificationSound.swift       # Urgent reminder sound
  TextScannerView.swift              # VisionKit OCR scanner UI
  MedicineDateParser.swift           # OCR date extraction/parsing (pure)
  MedicineNameParser.swift           # OCR name selection (pure)
  ReminderLeadOption.swift           # Reminder lead choices + labels
  DimensionalButtonStyle.swift       # Shared button style
Medicine Date AlerterTests/          # Unit tests
Medicine Date AlerterUITests/        # UI tests
```

## Phase 0: Outline & Research
Key decisions (see `research.md`):
- **OCR**: VisionKit `DataScannerViewController` for live on-device text — no images leave the device.
- **Date parsing** is a pure function over strings (regex for numeric + month-name forms) so it is
  fully unit-testable without a camera; handles the OCR `O`→`0` misread and 2-digit years (2000-based).
- **Notifications**: `UNCalendarNotificationTrigger`; a passed reminder time falls back to now+60s.
  Payload holds only the medicine id to satisfy privacy.
- **Persistence**: JSON in Application Support with complete file protection; atomic writes; in-memory
  cache for fast UI; forward-compatible decoding.
- **Concurrency**: `@MainActor @Observable` store; disk read via `Task.detached`, result assigned on main.

## Phase 1: Design & Contracts
- **data-model.md**: `Medicine` (+ derived `reminderDate`, `isExpired`), `MedicineUpdate`,
  `MedicineValidationError`, `MedicineBackupFile`; Codable compatibility rules.
- **contracts/**: `NotificationScheduling` protocol; `MedicineStore` public surface
  (`load/save/update/delete/exportData/importData`); `MedicineDateParser` static API.
- **quickstart.md**: add/scan/save/edit/delete + notification tap + backup round-trip steps.
- Post-design Constitution Check: PASS (unchanged).

## Phase 2: Task Planning Approach
Tasks derived test-first: pure parsers/validators and store behavior get failing unit tests before
implementation; primary flows get XCUIAutomation tests. See `tasks.md`.

## Complexity Tracking
None — no principle violations.

## Progress Tracking
- [x] Phase 0: Research complete
- [x] Phase 1: Design complete
- [x] Constitution Check: initial PASS
- [x] Constitution Check: post-design PASS
- [x] Phase 2: Task planning approach described

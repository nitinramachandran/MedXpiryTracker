# Tasks: Medicine Expiry Tracker

**Input**: Design documents from `specs/001-medicine-expiry-tracker/`
**Status**: Implemented (retro-specified) — all tasks reflect shipped code at v1.2.

## Conventions
- **[P]** = parallelizable (different files, no ordering dependency).
- Test-first: failing-test tasks precede their implementation tasks.

## Phase 3.1: Setup
- [x] T001 Create the SwiftUI iPhone app target, portrait + light mode lock (`Medicine_Date_AlerterApp.swift`, `AppNotificationDelegate.swift`).
- [x] T002 [P] Define the shared design system: `PillEyePalette` and `DimensionalButtonStyle.swift`.
- [x] T003 [P] Define reminder-lead options in `ReminderLeadOption.swift`.

## Phase 3.2: Tests First ⚠️
- [x] T004 [P] Unit tests for OCR date parsing (numeric, month-name, O→0, 2-digit years) in `Medicine Date AlerterTests/`.
- [x] T005 [P] Unit tests for `MedicineValidator` (empty name, expiry-not-after-manufacturing) in `Medicine Date AlerterTests/`.
- [x] T006 [P] Unit tests for `Medicine.reminderDate` / `isExpired` and Codable backward compatibility.
- [x] T007 [P] Unit tests for `MedicineStore` save/update/delete/import/export using a fake scheduler and memory-only store.
- [x] T008 [P] UI test for the add → save → appears-in-list flow in `Medicine Date AlerterUITests/`.

## Phase 3.3: Core Implementation
- [x] T009 [P] `Medicine`, `MedicineUpdate`, `MedicineValidationError`, `MedicineValidator` in `Medicine.swift`.
- [x] T010 [P] Pure OCR parsing in `MedicineDateParser.swift` and `MedicineNameParser.swift`.
- [x] T011 `NotificationScheduling` protocol + `LocalNotificationScheduler` in `NotificationScheduler.swift`.
- [x] T012 `@Observable @MainActor MedicineStore` with async disk load, atomic writes, file protection in `MedicineStore.swift`.
- [x] T013 Main form UI, date popups, edit/details popups, and save/validation wiring in `ContentView.swift`.
- [x] T014 VisionKit scanner UI in `TextScannerView.swift`; scanner modes (name/mfg/expiry) wired in `ContentView.swift`.

## Phase 3.4: Integration
- [x] T015 Notification actions (Snooze/Cancel), foreground presentation, and tap routing in `AppNotificationDelegate.swift` + `MedicineNotificationRoute.swift`.
- [x] T016 Urgent reminder sound in `AlarmNotificationSound.swift`.
- [x] T017 Backup export/import: `MedicineBackupFile` (Transferable) + ShareLink/`fileImporter` with replace confirmation in `MedicineStore.swift` / `ContentView.swift`.
- [x] T018 Forward-compatible decoding: `decodeIfPresent` for `reminderLeadDays`, ignore legacy `snoozeMinutes`.

## Phase 3.5: Polish
- [x] T019 [P] Accessibility identifiers on key controls/messages (`medicineNameField`, `saveMedicineButton`, `validationMessage`, backup buttons).
- [x] T020 [P] Empty-state (`ContentUnavailableView`) and "Expired" marker in the saved list.
- [x] T021 Wire the `Medicine Date Alerter.xctestplan`; build and run all tests green.

## Dependencies
- T004–T008 (tests) precede T009–T014 (implementation).
- T009 (model) → T012 (store) → T013 (UI).
- T011 (scheduler protocol) precedes T012 (store uses it) and T015 (delegate).

## Parallel Execution Example
```
# Independent test suites can be authored together:
T004 Date parser tests
T005 Validator tests
T006 Medicine model tests
T007 Store tests
```

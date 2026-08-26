# Tasks: Compact Date Entry & Saved-Medicines Popup

**Input**: `specs/002-compact-dates-saved-popup/spec.md`
**Status**: Implemented

## Phase 1: Compact date entry (main author)
- [x] T001 Add `activeDateField` state and replace the two date rows with a single `dateEntryRow`
  (menu dropdown to pick Manufacturing/Expiry) in `Medicine Date Alerter/ContentView.swift`.
- [x] T002 Add `activeDateValue` and `dateSummaryChip` so both captured dates stay visible; Set/Scan
  act on the selected field. Identifier `dateFieldPicker`.
- [x] T003 Verify no diagnostics via XcodeRefreshCodeIssuesInFile.

## Phase 2: Saved-medicines popup (delegated agent)
- [x] T004 Add a "Saved medicines" button (`savedMedicinesButton`) and remove the inline saved list
  in `ContentView.swift`; present `SavedMedicinesView` as a sheet.
- [x] T005 Create `SavedMedicinesView.swift`: `MedicineFilter` (all/expiring/expired) with
  `includes(_:)` over `Medicine.isExpired`; default Expiring.
- [x] T006 Three radio-style filter options colored All = green, Expiring = orange, Expired = red
  (`filterAll`/`filterExpiring`/`filterExpired`); rows tinted by status (expired red, else orange).
- [x] T007 Empty-store and empty-filter states via `ContentUnavailableView`.
- [x] T008 Keep edit (dismiss sheet → existing edit popup) and delete (swipe → `store.delete`).
- [x] T009 Add `PillEyePalette.filter{Green,Orange,Red}`; register `SavedMedicinesView.swift` in the
  Xcode target (repo-root files are explicit references, not auto-synced).

## Phase 3: Verify
- [x] T010 BuildProject succeeds; both edited files report no issues.

## Phase 4: Post-implementation polish (2026-08-26 cleanup)
- [x] T011 Unit tests for `Medicine.isExpiringSoon` boundaries (expired / within / at edge /
  beyond the 60-day window) and `MedicineFilter.includes` — closes this feature's test-first gap.
- [x] T012 `MedicineFilter.includes` accepts an injectable `now`; the popup evaluates the whole
  list against one instant. Legacy SF Symbol `largecircle.fill.circle` → `circle.inset.filled`.

## Phase 5: Date-entry refinements (2026-08-26, FR-001/FR-002a/FR-002b)
- [x] T013 Remove the "Not set" value line; empty dates show as red dashes in the Mfg/Exp chips.
- [x] T014 Add Clear buttons: `clearDatesButton` beside Set (empties both dates, resets the
  dropdown to Manufacturing) and `clearMedicineNameButton` beside Scan medicine name. Both
  disabled when empty.
- [x] T015 Auto-advance the dropdown to the other date field after each manual or scanned capture
  (`ManualDateTarget.other`).

## Notes
- Constitution compliance: SwiftUI + async/await only; design system reused; light mode + portrait;
  stable accessibility identifiers added. No persistence/model changes.

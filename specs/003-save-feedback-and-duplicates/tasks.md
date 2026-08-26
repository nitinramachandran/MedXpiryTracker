# Tasks: Save Feedback & Duplicate Protection

**Input**: `specs/003-save-feedback-and-duplicates/spec.md`
**Status**: Implemented

## Phase 1: Tests First
- [x] T001 Unit test: duplicate save (same name any case/whitespace + same dates) throws
  `duplicateMedicine` and leaves the list unchanged; same name with a different expiry saves
  (`storeRejectsDuplicateMedicineButAllowsDifferentDates`).

## Phase 2: Core
- [x] T002 `Medicine.isDuplicate(ofName:manufacturingDate:expiryDate:calendar:)` — pure,
  calendar-day comparison, injectable calendar.
- [x] T003 `MedicineValidationError.duplicateMedicine` with user-facing message.
- [x] T004 `MedicineStore.save` rejects duplicates and returns the saved `Medicine`
  (`@discardableResult`, existing callers unaffected).

## Phase 3: UI
- [x] T005 Saved Medicines button shows the record count when nonzero.
- [x] T006 Dissolving confirmation card (`saveConfirmationCard`): spring fade-in, ~2.4 s hold,
  0.8 s ease-out dissolve; touches pass through; newer save supersedes an active card; combined
  accessibility element.

## Phase 4: Verify
- [x] T007 Build clean (no warnings); 26/26 tests pass.

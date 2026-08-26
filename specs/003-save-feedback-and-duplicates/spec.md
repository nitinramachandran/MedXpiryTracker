# Feature Specification: Save Feedback & Duplicate Protection

**Feature Branch**: `003-save-feedback-and-duplicates`
**Created**: 2026-08-27
**Status**: Implemented
**Input**: "Show the number of saved records on the Saved Medicines button; warn when saving a
duplicate medicine; show a dissolving confirmation window with the medicine details after a save."

## User Scenarios & Testing *(mandatory)*

### Primary User Story
After saving a medicine, the user gets clear feedback: a confirmation card appears showing what
was saved and dissolves on its own. If they try to save the same medicine twice, the app tells
them instead of quietly creating a second identical record. The Saved Medicines button shows how
many records exist without opening the popup.

### Acceptance Scenarios
1. **Given** saved medicines, **When** viewing the main screen, **Then** the Saved Medicines
   button reads "Saved medicines (N)"; with an empty list it reads just "Saved medicines".
2. **Given** a saved medicine, **When** the user saves the same name with the same manufacturing
   and expiry dates (any letter case / surrounding whitespace), **Then** the save is rejected with
   "This medicine is already saved with the same dates." and the list is unchanged.
3. **Given** a saved medicine, **When** the user saves the same name with a different expiry
   date, **Then** it is stored as a separate record (a second box of the same medicine).
4. **Given** a successful save, **Then** a confirmation card appears showing the name, both
   dates, and the reminder lead, fades in, stays briefly, and dissolves away by itself without
   blocking interaction.

### Edge Cases
- A second save while a confirmation is still showing replaces it; the older card's dismissal
  does not cut the newer one short.
- The confirmation card never intercepts touches (taps pass through to the form).

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: The Saved Medicines button MUST display the current record count when nonzero.
- **FR-002**: Saving MUST be rejected with a clear message when a record with the same name
  (case-insensitive, whitespace-trimmed) and the same manufacturing and expiry calendar days
  already exists. Same name with different dates MUST remain saveable.
- **FR-003**: A successful save MUST show a transient, self-dismissing confirmation with the
  saved medicine's name, dates, and reminder lead, styled like the app's other cards.

### Non-Functional Requirements
- **Testability**: duplicate detection lives in the core (`Medicine.isDuplicate`,
  `MedicineStore.save`) and is unit-tested; the store returns the saved medicine for the UI.
- **Accessibility**: the confirmation card reads as one combined element and has a stable
  identifier (`saveConfirmationCard`).

### Key Entities
- No new persisted entities; adds a duplicate predicate to `Medicine` and a new
  `MedicineValidationError.duplicateMedicine` case.

## Review & Acceptance Checklist
- [x] Requirements testable and unambiguous
- [x] Duplicate definition stated (name + both calendar days)
- [x] No persistence format changes (backward compatible)

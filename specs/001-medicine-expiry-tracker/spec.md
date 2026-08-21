# Feature Specification: Medicine Expiry Tracker

**Feature Branch**: `001-medicine-expiry-tracker`
**Created**: 2026-08-21
**Status**: Implemented (retro-specified)
**Input**: "An iPhone app that lets a person scan or type the name, manufacturing date, and
expiry date of a medicine, then reminds them before it expires — all on-device, with backup
export/import."

> This specification was written retroactively to bring the shipped MedXpiryTracker (PillEye)
> app under Spec-Driven Development. It describes the product as it exists at version 1.2.

## User Scenarios & Testing *(mandatory)*

### Primary User Story
A person has a drawer full of medicines and cannot remember which are close to expiring. They
open the app, capture each medicine's name and its printed manufacturing and expiry dates —
either by pointing the camera at the label or by typing — and save it. The app then reminds
them before each medicine expires so they can use or replace it in time. Everything stays on
their phone, and they can move their list to a new phone with a backup file.

### Acceptance Scenarios
1. **Given** an empty list, **When** the user enters a name, a manufacturing date, and a later
   expiry date and taps Save, **Then** the medicine appears in "Saved medicines" and a reminder
   is scheduled for the chosen lead time before expiry.
2. **Given** the camera is aimed at a label, **When** the user scans the name, **Then** the
   detected text is capitalized and placed in the name field.
3. **Given** the user scans a date label like `DEC-2026` or `05/2026`, **When** they tap the
   correct detected date, **Then** it is parsed into a real date and applied to the chosen field.
4. **Given** a manufacturing date and an earlier expiry date, **When** the user tries to save,
   **Then** the app blocks the save and shows "Expiry date must be after the manufacturing date."
5. **Given** a saved medicine, **When** the user swipes and taps Edit and changes the reminder
   lead, **Then** the reminder is rescheduled and the row updates.
6. **Given** a delivered expiry notification, **When** the user taps it, **Then** the app opens a
   details popup for that medicine with Delete and Cancel actions.
7. **Given** saved medicines, **When** the user exports a backup and imports it on another iPhone,
   **Then** the same medicines appear and their reminders are rescheduled.

### Edge Cases
- **Camera/notification permission denied**: manual date entry and saving still work; reminders
  simply do not fire until permission is granted.
- **Unreadable OCR date**: the app shows "Could not read a valid … date. You can still edit it
  manually." and leaves the field unchanged.
- **Reminder time already passed** (e.g. importing an old medicine): a near-future reminder is
  scheduled so the medicine still surfaces rather than being silently dropped.
- **Corrupt or non-backup file on import**: the list is left unchanged and a clear message is shown.
- **Importing over an existing list**: the user must confirm replacement, which states how many
  medicines will be replaced.
- **Old backups missing the reminder-lead field**: they import successfully, defaulting to a 1-day lead.

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: Users MUST be able to add a medicine with a name, a manufacturing date, and an
  expiry date, and MUST be able to save it to a persistent list.
- **FR-002**: Users MUST be able to enter the name by typing or by scanning printed text with the camera.
- **FR-003**: Users MUST be able to enter each date manually via a date picker or by scanning a
  printed date; scanned dates in numeric (`05/2026`, `01-05-26`) and month-name (`DEC-2026`, `JAN 26`)
  forms MUST be parsed into real dates, tolerating the common OCR `O`→`0` misread.
- **FR-004**: The app MUST reject a save when the name is empty or the expiry date is not after the
  manufacturing date, showing a specific message.
- **FR-005**: Users MUST be able to choose how far before expiry to be reminded, from the set
  {1 day, 1 week, 2 weeks, 1 month, 2 months}, defaulting to 1 day.
- **FR-006**: The app MUST schedule a local reminder at the chosen lead time before expiry; if that
  moment has already passed, it MUST schedule a near-future reminder instead.
- **FR-007**: A delivered reminder MUST offer Snooze (defers one day) and Cancel actions, and tapping
  the reminder body MUST open that medicine's details.
- **FR-008**: Users MUST be able to view saved medicines showing name, manufacturing/expiry dates,
  reminder time and lead, and an "Expired" marker once the expiry date has passed.
- **FR-009**: Users MUST be able to edit a saved medicine's reminder lead and delete a saved medicine;
  deleting MUST cancel its pending reminder.
- **FR-010**: Users MUST be able to export all medicines as a single shareable backup file and import
  a backup file, replacing the current list after confirmation.
- **FR-011**: Importing a backup MUST cancel reminders for the replaced medicines and schedule reminders
  for the imported ones.

### Non-Functional Requirements
- **Privacy**: All data stays on-device. No network calls, analytics, or accounts. Saved data lives
  in the app sandbox with complete file protection. Notifications carry only the medicine's identifier.
- **Compatibility**: Saved files and backups from older versions MUST remain importable; newer fields
  default gracefully.
- **Accessibility**: Key controls and status messages expose stable accessibility identifiers for UI
  testing (e.g. `medicineNameField`, `saveMedicineButton`, `validationMessage`).
- **Platform**: iPhone only, portrait, light mode.

### Key Entities
- **Medicine**: a saved item — stable id, name, manufacturing date, expiry date, reminder lead (days),
  created-at timestamp. Derives a reminder date and an expired flag.
- **Reminder**: a local notification derived from a medicine, identified by the medicine's id, firing at
  the reminder date, with Snooze/Cancel actions.
- **Backup**: the full medicine list serialized to a portable JSON file for transfer between devices.

## Review & Acceptance Checklist

### Content Quality
- [x] No implementation details in requirements
- [x] Focused on user value
- [x] All mandatory sections completed

### Requirement Completeness
- [x] No `[NEEDS CLARIFICATION]` markers remain
- [x] Requirements are testable and unambiguous
- [x] Scope is clearly bounded (single-user, on-device, iPhone)
- [x] Assumptions stated (permissions optional; OCR best-effort)

## Execution Status
- [x] User description parsed
- [x] Key concepts extracted
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [x] Review checklist passed

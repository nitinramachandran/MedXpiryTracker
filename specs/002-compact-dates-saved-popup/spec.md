# Feature Specification: Compact Date Entry & Saved-Medicines Popup

**Feature Branch**: `002-compact-dates-saved-popup`
**Created**: 2026-08-26
**Status**: Implemented
**Input**: "Save screen real estate: collapse the two date rows (manufacturing/expiry) into one
row with a dropdown to choose which date is being set. Move the saved medicines out of the main
page into a popup opened by a 'Saved Medicines' button; the popup has three filters — All,
Expiring, Expired (Expiring selected by default) — colored Green/Orange/Red respectively."

## User Scenarios & Testing *(mandatory)*

### Primary User Story
While adding a medicine, the user sets both the manufacturing and expiry dates from a single
compact row: a dropdown selects which date they are entering, and both captured values stay
visible. The main screen no longer lists saved medicines inline; instead a "Saved Medicines"
button opens a popup where the user filters by All / Expiring / Expired.

### Acceptance Scenarios
1. **Given** the add form, **When** the user picks "Manufacturing" (default) or "Expiry" from the
   date dropdown and taps Set/Scan, **Then** the value is captured for that field, and a compact
   summary shows both the manufacturing and expiry dates.
2. **Given** saved medicines, **When** the user taps "Saved Medicines", **Then** a popup opens with
   three radio options (All, Expiring, Expired) and "Expiring" selected by default.
3. **Given** the popup, **When** the user selects a filter, **Then** the list shows only medicines
   in that category (All = every medicine; Expiring = not yet expired; Expired = past expiry).
4. **Given** the popup, **Then** the option labels are colored All = green, Expiring = orange,
   Expired = red, and medicine rows are tinted by their own status (expired = red, otherwise orange).

### Edge Cases
- No saved medicines → popup shows an empty state; a selected filter with no matches shows a
  "nothing here" message rather than a blank list.
- Existing edit/delete behavior on a medicine remains available from the popup.

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: The add form MUST capture manufacturing and expiry dates from a single row using a
  dropdown to select the active field; both captured dates MUST remain visible simultaneously.
- **FR-002**: Set-manually and Scan actions MUST apply to the field currently selected in the dropdown.
- **FR-003**: The main screen MUST replace the inline saved-medicines list with a "Saved Medicines"
  button that opens a popup.
- **FR-004**: The popup MUST offer three mutually exclusive filters — All, Expiring, Expired —
  with Expiring selected by default.
- **FR-005**: Filtering MUST categorize medicines as: Expired = `expiryDate < now`; Expiring =
  not expired AND `expiryDate <= now + 60 days`; All = every medicine (including not-yet-expired
  medicines more than 60 days out, which appear only under All).
- **FR-006**: Filter labels MUST use these colors — All: green, Expiring: orange, Expired: red.
- **FR-007**: Edit and delete of a medicine MUST remain available from the popup.

### Non-Functional Requirements
- **Design**: reuse `PillEyePalette` / `DimensionalButtonStyle`; light mode + portrait preserved.
- **Accessibility**: the "Saved Medicines" button and each filter option expose stable
  accessibility identifiers.

### Key Entities
- No new persisted entities. Uses existing `Medicine` (`isExpired`, dates).

## Review & Acceptance Checklist
- [x] Requirements testable and unambiguous
- [x] Scope bounded to UI (no persistence/model change)
- [x] Assumptions stated (Expiring = not-yet-expired)

## Notes
"Expiring" means not-yet-expired medicines that expire within `Medicine.expiringSoonWindowDays`
(60 days). Medicines expiring further out are not "Expiring" and appear only under "All". Row name
colors follow the same three buckets: expired = red, expiring soon = orange, otherwise green.

# Phase 1 Data Model: Medicine Expiry Tracker

## Medicine
The core saved record. `Identifiable, Codable, Hashable`.

| Field | Type | Notes |
|-------|------|-------|
| `id` | `UUID` | Stable identity; also the notification identifier key. |
| `name` | `String` | Trimmed + localized-capitalized on init. |
| `manufacturingDate` | `Date` | |
| `expiryDate` | `Date` | MUST be after `manufacturingDate` (validation). |
| `reminderLeadDays` | `Int` | One of {1, 7, 14, 30, 60}. Added v1.2; defaults to 1 when absent. |
| `createdAt` | `Date` | Insertion timestamp. |

Derived:
- `reminderDate` = `expiryDate − reminderLeadDays` (Calendar day math).
- `isExpired` = `expiryDate < now`.

**Codable compatibility**: custom `init(from:)` uses `decodeIfPresent` for `reminderLeadDays`
(default 1) and ignores the legacy `snoozeMinutes` field. Encoding is ISO-8601, sorted keys.

## MedicineUpdate
Describes a partial edit to an existing medicine. All fields optional; `nil` = unchanged.
Currently only `reminderLeadDays` is edited by the UI, but `name`/`manufacturingDate`/`expiryDate`
exist so a future edit screen reuses the same `MedicineStore.update(medicineID:changes:)` path.

## MedicineValidationError
`Error, Equatable, LocalizedError` — `missingName`, `expiryNotAfterManufacturing`. Each provides a
user-facing `errorDescription`.

## Validation rules (`MedicineValidator.validate`)
- Name MUST be non-empty after trimming → else `missingName`.
- `expiryDate` MUST be strictly after `manufacturingDate` → else `expiryNotAfterManufacturing`.

## Backup (MedicineBackupFile)
A `Transferable` wrapper exporting the full `[Medicine]` list as a JSON file
(`MedXpiryTracker-Backup-YYYY-MM-DD.json`). Written lazily only when a share destination is chosen.
Import decodes the same array, replaces the list (after confirmation), and reschedules reminders.

## State transitions
```
draft form ──save()──▶ validated Medicine ──▶ persisted (disk) ──▶ reminder scheduled
saved ──update(lead)──▶ re-persisted ──▶ reminder rescheduled
saved ──delete()──▶ removed from disk ──▶ reminder cancelled
backup file ──importData()──▶ list replaced ──▶ old reminders cancelled, new ones scheduled
```

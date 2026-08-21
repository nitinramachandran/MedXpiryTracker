# Phase 0 Research: Medicine Expiry Tracker

## On-device OCR
- **Decision**: Use VisionKit `DataScannerViewController` for live text recognition.
- **Rationale**: On-device, real-time, no image ever leaves the phone — satisfies Principle I.
  Lets the user tap the exact detected word/date instead of the app guessing.
- **Alternatives considered**: Uploading photos to a cloud OCR service (rejected: violates
  on-device privacy); Vision `VNRecognizeTextRequest` on still photos (rejected: worse UX than live
  scanning for small label text).

## Date parsing from OCR text
- **Decision**: A pure `MedicineDateParser` over `String`, using ordered regex for numeric
  (`d/m/yy`, `m/yyyy`, …) and month-name (`DEC-2026`, `JAN 26`) forms. Normalize the common OCR
  `O`→`0` misread only when adjacent to digits (so `NOV`/`OCT` survive). Treat 2-digit years as 2000-based.
- **Rationale**: Keeping parsing free of camera/system state makes it fully unit-testable in
  milliseconds (Principle II) and locale-injectable via `Calendar`.
- **Alternatives considered**: `NSDataDetector` (rejected: misses partial `MM/YYYY` medicine-label
  formats and month-abbreviation styles); free-form `DateFormatter` guessing (rejected: ambiguous,
  untestable).

## Local reminders
- **Decision**: `UNCalendarNotificationTrigger` at `expiry − leadDays`; if that instant has passed,
  fall back to `now + 60s`. Payload carries only `medicineID`. Snooze/Cancel actions via a
  registered notification category; Snooze defers a fixed one day.
- **Rationale**: Calendar triggers survive relaunches; the id-only payload keeps sensitive data off
  the lock screen (Principle I). A near-future fallback means imported/expired items still surface.
- **Alternatives considered**: Time-interval triggers computed at save (rejected: drift across app
  launches); per-medicine configurable snooze (rejected: adds config surface for little value —
  `reminderLeadDays` already governs the planned alert).

## Persistence
- **Decision**: JSON array in Application Support (`PillEye/medicines.json`), atomic writes,
  `.completeFileProtection`, ISO-8601 dates, sorted keys; in-memory cache for UI. Disk read runs in a
  `Task.detached`, assigning results on the main actor.
- **Rationale**: Simple, inspectable, and portable to the backup format for free. File protection and
  the off-main load satisfy Principles I and III.
- **Alternatives considered**: SwiftData/Core Data (rejected: heavier than a small flat list needs —
  Principle VI); UserDefaults (rejected: not for user documents, no file protection story).

## Backward compatibility
- **Decision**: `Medicine.init(from:)` decodes `reminderLeadDays` with `decodeIfPresent ?? 1` and
  ignores the legacy `snoozeMinutes` field.
- **Rationale**: Old saved files and shared backups must never fail to import (Principle IV).
- **Alternatives considered**: Versioned schema envelope (rejected: unnecessary for additive changes
  so far; revisit if a breaking migration is ever required).

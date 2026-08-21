# Phase 1 Contracts: Medicine Expiry Tracker

Interface sketches only — signatures, not implementations. These are the seams the tests and
SwiftUI previews inject fakes into (Principle II).

## NotificationScheduling
The boundary that hides `UserNotifications` from the store so tests use a fake scheduler.

```swift
protocol NotificationScheduling {
    /// Schedules the expiry reminder for one medicine.
    func scheduleExpiryReminder(for medicine: Medicine) async throws
    /// Cancels the reminder for a medicine by its stable UUID.
    func cancelReminder(for medicineID: UUID) async
}
```

Implementations:
- `LocalNotificationScheduler` — real iOS local notifications (category with Snooze/Cancel;
  calendar trigger with a `now + 60s` fallback; payload = `medicineID` only).
- Test/preview fakes — no-op or recording doubles.

## MedicineStore (public surface)
`@MainActor @Observable`. Constructed either for the real app (disk + local notifications) or with an
injected scheduler and optional storage URL (`nil` = memory-only) for tests.

```swift
@MainActor @Observable
final class MedicineStore {
    private(set) var medicines: [Medicine]

    init()                                                             // real app
    init(notificationScheduler: NotificationScheduling, storageURL: URL? = nil) // tests/previews

    func load() async
    func save(name: String, manufacturingDate: Date, expiryDate: Date, reminderLeadDays: Int) async throws
    func update(medicineID: UUID, changes: MedicineUpdate) async throws
    func delete(_ medicine: Medicine) async throws
    func exportData() throws -> Data
    func importData(_ data: Data) async throws
}
```

Guarantees: disk writes are atomic; a failed write rolls the in-memory list back; imports/deletes
reconcile scheduled reminders.

## MedicineDateParser (pure, static)
```swift
enum/struct MedicineDateParser {
    static func extractDateStrings(from text: String) -> [String]
    static func extractDates(from text: String, calendar: Calendar = .current) -> [Date]   // sorted
    static func firstDate(from text: String, calendar: Calendar = .current) -> Date?
    static func inferredManufacturingAndExpiryDates(from text: String) -> (manufacturing: Date, expiry: Date)?
}
```
No system state; `calendar` is injectable for deterministic tests.

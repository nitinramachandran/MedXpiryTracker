import Foundation
import Testing
@testable import Medicine_Date_Alerter

/// Unit tests for the non-UI app logic.
///
/// These tests are fast because they do not open the app UI or use the real camera.
struct Medicine_Date_AlerterTests {
    /// Verifies that blank medicine names are rejected.
    @Test func validatorRejectsMissingName() throws {
        let manufacturing = try #require(makeDate(year: 2026, month: 5, day: 1))
        let expiry = try #require(makeDate(year: 2027, month: 5, day: 1))

        #expect(throws: MedicineValidationError.missingName) {
            try MedicineValidator.validate(name: "   ", manufacturingDate: manufacturing, expiryDate: expiry)
        }
    }

    /// Verifies that expiry must be after manufacturing date.
    @Test func validatorRejectsExpiryBeforeManufacturingDate() throws {
        let manufacturing = try #require(makeDate(year: 2026, month: 5, day: 1))
        let expiry = try #require(makeDate(year: 2026, month: 4, day: 30))

        #expect(throws: MedicineValidationError.expiryNotAfterManufacturing) {
            try MedicineValidator.validate(name: "Paracetamol", manufacturingDate: manufacturing, expiryDate: expiry)
        }
    }

    /// Verifies medicine names are stored in Title Case.
    @Test func medicineNameIsStoredInTitleCase() throws {
        let manufacturing = try #require(makeDate(year: 2026, month: 5, day: 1))
        let expiry = try #require(makeDate(year: 2027, month: 5, day: 1))
        let medicine = Medicine(name: "crocin advance tablet", manufacturingDate: manufacturing, expiryDate: expiry)

        #expect(medicine.name == "Crocin Advance Tablet")
    }

    /// Verifies medicine-name scanning keeps short rows and ignores sentence-like OCR text.
    @Test func medicineNameParserKeepsOneToThreeWordRows() {
        let candidates = MedicineNameParser.candidates(from: [
            "take one tablet daily",
            "dolo-650",
            "crocin advance",
            "vitamin d3 1000",
            "EXP 08/2027",
            "crocin®",
            "500"
        ])

        #expect(candidates == ["Dolo-650", "Crocin Advance", "Vitamin D3 1000", "Crocin"])
    }

    /// Verifies text spanning two label rows is never merged into one name candidate.
    @Test func medicineNameParserDoesNotMergeRows() {
        let candidates = MedicineNameParser.candidates(from: ["ZINCOVIT\nSyrup"])

        #expect(candidates == ["Zincovit", "Syrup"])
        #expect(MedicineNameParser.candidate(from: "ZINCOVIT\nSyrup") == nil)
    }

    /// Verifies snooze durations use one shared label source.
    @Test func snoozeOptionLabelsAreUserFriendly() {
        #expect(SnoozeOption.allDurationsInMinutes == [1440, 10080, 43200, 86400])
        #expect(SnoozeOption.label(for: 1440) == "1 Day")
        #expect(SnoozeOption.label(for: 10080) == "1 Week")
        #expect(SnoozeOption.label(for: 43200) == "1 Month")
        #expect(SnoozeOption.label(for: 86400) == "2 Months")
    }

    /// Verifies the reminder is calculated as one day before expiry.
    @Test func reminderDateIsOneDayBeforeExpiry() throws {
        let manufacturing = try #require(makeDate(year: 2026, month: 5, day: 1))
        let expiry = try #require(makeDate(year: 2026, month: 5, day: 20))
        let medicine = Medicine(name: "Paracetamol", manufacturingDate: manufacturing, expiryDate: expiry)
        let expected = try #require(makeDate(year: 2026, month: 5, day: 19))

        #expect(Calendar.current.isDate(medicine.reminderDate, inSameDayAs: expected))
    }

    /// Verifies OCR date extraction ignores non-date words.
    @Test func dateParserExtractsOnlyDateStrings() {
        let dates = MedicineDateParser.extractDateStrings(from: "MFG May text 05/2026 Batch X EXP 08/2027 DEC-2026")

        #expect(dates == ["05/2026", "08/2027", "DEC-2026"])
    }

    /// Verifies one selected OCR date can be parsed by itself.
    @Test func dateParserParsesSingleSelectedDate() throws {
        let date = try #require(MedicineDateParser.firstDate(from: "EXP 08/2027"))

        #expect(Calendar.current.component(.month, from: date) == 8)
        #expect(Calendar.current.component(.year, from: date) == 2027)
    }

    /// Verifies month-name dates can use dash, dot, or space separators.
    @Test func dateParserParsesMonthNameDates() throws {
        let dates = MedicineDateParser.extractDates(from: "MFG NOV.2026 EXP DEC-2027 RETEST JAN 28")

        #expect(Calendar.current.component(.month, from: dates[0]) == 11)
        #expect(Calendar.current.component(.year, from: dates[0]) == 2026)
        #expect(Calendar.current.component(.month, from: dates[1]) == 12)
        #expect(Calendar.current.component(.year, from: dates[1]) == 2027)
        #expect(Calendar.current.component(.month, from: dates[2]) == 1)
        #expect(Calendar.current.component(.year, from: dates[2]) == 2028)
    }

    /// Verifies OCR-like text can be parsed into manufacturing and expiry dates.
    @Test func dateParserInfersManufacturingAndExpiryDates() throws {
        let result = try #require(MedicineDateParser.inferredManufacturingAndExpiryDates(from: "MFG 05/2026 EXP 08/2027"))

        #expect(Calendar.current.component(.month, from: result.manufacturing) == 5)
        #expect(Calendar.current.component(.year, from: result.manufacturing) == 2026)
        #expect(Calendar.current.component(.month, from: result.expiry) == 8)
        #expect(Calendar.current.component(.year, from: result.expiry) == 2027)
    }

    /// Verifies the store saves a medicine and asks the scheduler to create a reminder.
    @Test @MainActor func storeSavesMedicineAndSchedulesReminder() async throws {
        let scheduler = SpyNotificationScheduler()
        let store = MedicineStore(notificationScheduler: scheduler)
        let manufacturing = try #require(makeDate(year: 2026, month: 5, day: 1))
        let expiry = try #require(makeDate(year: 2027, month: 5, day: 1))

        try await store.save(name: "Cetirizine", manufacturingDate: manufacturing, expiryDate: expiry, snoozeMinutes: 15)

        #expect(store.medicines.count == 1)
        #expect(scheduler.scheduledMedicineNames == ["Cetirizine"])
    }

    /// Verifies medicines are written to disk and loaded by a new store instance.
    @Test @MainActor func storePersistsMedicinesToDisk() async throws {
        let storageURL = temporaryStorageURL()
        try? FileManager.default.removeItem(at: storageURL.deletingLastPathComponent())

        let manufacturing = try #require(makeDate(year: 2026, month: 5, day: 1))
        let expiry = try #require(makeDate(year: 2027, month: 5, day: 1))
        let firstStore = MedicineStore(notificationScheduler: SpyNotificationScheduler(), storageURL: storageURL)

        try await firstStore.save(name: "dolo 650", manufacturingDate: manufacturing, expiryDate: expiry, snoozeMinutes: 1440)

        let secondStore = MedicineStore(notificationScheduler: SpyNotificationScheduler(), storageURL: storageURL)
        #expect(secondStore.medicines.map(\.name) == ["Dolo 650"])
        #expect(secondStore.medicines.first?.snoozeMinutes == 1440)

        try? FileManager.default.removeItem(at: storageURL.deletingLastPathComponent())
    }

    /// Verifies editing snooze updates the saved medicine and refreshes its reminder.
    @Test @MainActor func storeUpdatesSnoozeAndReschedulesReminder() async throws {
        let scheduler = SpyNotificationScheduler()
        let store = MedicineStore(notificationScheduler: scheduler)
        let manufacturing = try #require(makeDate(year: 2026, month: 5, day: 1))
        let expiry = try #require(makeDate(year: 2027, month: 5, day: 1))

        try await store.save(name: "Cetirizine", manufacturingDate: manufacturing, expiryDate: expiry, snoozeMinutes: 1440)
        let medicine = try #require(store.medicines.first)
        try await store.update(medicineID: medicine.id, changes: MedicineUpdate(snoozeMinutes: 10080))

        #expect(store.medicines.first?.snoozeMinutes == 10080)
        #expect(scheduler.scheduledMedicineNames == ["Cetirizine", "Cetirizine"])
    }

    /// Verifies delete removes a medicine and asks the scheduler to cancel its reminder.
    @Test @MainActor func storeDeletesMedicineAndCancelsReminder() async throws {
        let scheduler = SpyNotificationScheduler()
        let store = MedicineStore(notificationScheduler: scheduler)
        let manufacturing = try #require(makeDate(year: 2026, month: 5, day: 1))
        let expiry = try #require(makeDate(year: 2027, month: 5, day: 1))

        try await store.save(name: "Cetirizine", manufacturingDate: manufacturing, expiryDate: expiry, snoozeMinutes: 1440)
        let medicine = try #require(store.medicines.first)
        try await store.delete(medicine)

        #expect(store.medicines.isEmpty)
        #expect(scheduler.cancelledMedicineIDs == [medicine.id])
    }
}

/// Helper for building predictable dates in tests.
///
/// Returning an optional `Date?` matches Swift's safe style: if the date cannot be built,
/// the test can fail using `#require` instead of force-unwrapping.
private func makeDate(year: Int, month: Int, day: Int) -> Date? {
    var components = DateComponents()
    components.calendar = Calendar.current
    components.year = year
    components.month = month
    components.day = day
    components.hour = 9
    return components.date
}

/// Builds a unique file URL in the temporary directory for persistence tests.
private func temporaryStorageURL() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
        .appendingPathComponent("medicines.json")
}

/// Fake notification scheduler used by tests.
///
/// It records what would have been scheduled without talking to iOS notifications.
@MainActor
private final class SpyNotificationScheduler: NotificationScheduling {
    var scheduledMedicineNames: [String] = []
    var cancelledMedicineIDs: [UUID] = []

    /// Records the scheduled medicine name instead of scheduling a real notification.
    func scheduleExpiryReminder(for medicine: Medicine) async throws {
        scheduledMedicineNames.append(medicine.name)
    }

    /// Records cancellation requests without talking to iOS notifications.
    func cancelReminder(for medicineID: UUID) async {
        cancelledMedicineIDs.append(medicineID)
    }
}

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

    /// Verifies reminder lead times use one shared label source.
    @Test func reminderLeadOptionLabelsAreUserFriendly() {
        #expect(ReminderLeadOption.allDays == [1, 7, 14, 30, 60])
        #expect(ReminderLeadOption.label(for: 1) == "1 Day")
        #expect(ReminderLeadOption.label(for: 7) == "1 Week")
        #expect(ReminderLeadOption.label(for: 14) == "2 Weeks")
        #expect(ReminderLeadOption.label(for: 30) == "1 Month")
        #expect(ReminderLeadOption.label(for: 60) == "2 Months")
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

    /// Verifies full day/month/year dates parse as one date, not as a month/year prefix.
    ///
    /// Regression test: the numeric pattern once listed the month/year alternative
    /// first, so `01/05/2026` matched as just `01/05` and became January 2005.
    @Test func dateParserParsesFullNumericDates() throws {
        #expect(MedicineDateParser.extractDateStrings(from: "EXP 01/05/2026") == ["01/05/2026"])

        let date = try #require(MedicineDateParser.firstDate(from: "EXP 01/05/2026"))
        #expect(Calendar.current.component(.day, from: date) == 1)
        #expect(Calendar.current.component(.month, from: date) == 5)
        #expect(Calendar.current.component(.year, from: date) == 2026)

        let shortYear = try #require(MedicineDateParser.firstDate(from: "15-08-27"))
        #expect(Calendar.current.component(.day, from: shortYear) == 15)
        #expect(Calendar.current.component(.month, from: shortYear) == 8)
        #expect(Calendar.current.component(.year, from: shortYear) == 2027)
    }

    /// Verifies the OCR O→0 fix repairs misread digits without corrupting month names.
    ///
    /// Regression test: replacing every letter O once turned `NOV` into `N0V` and
    /// `OCT` into `0CT`, so those months could never be recognized.
    @Test func dateParserFixesMisreadZerosWithoutBreakingMonthNames() throws {
        let november = try #require(MedicineDateParser.firstDate(from: "EXP NOV 2O26"))
        #expect(Calendar.current.component(.month, from: november) == 11)
        #expect(Calendar.current.component(.year, from: november) == 2026)

        let october = try #require(MedicineDateParser.firstDate(from: "EXP OCT-2027"))
        #expect(Calendar.current.component(.month, from: october) == 10)
        #expect(Calendar.current.component(.year, from: october) == 2027)

        let misreadRun = try #require(MedicineDateParser.firstDate(from: "EXP 08/2OO6"))
        #expect(Calendar.current.component(.year, from: misreadRun) == 2006)
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

        try await store.save(name: "Cetirizine", manufacturingDate: manufacturing, expiryDate: expiry)

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

        try await firstStore.save(name: "dolo 650", manufacturingDate: manufacturing, expiryDate: expiry, reminderLeadDays: 7)

        let secondStore = MedicineStore(notificationScheduler: SpyNotificationScheduler(), storageURL: storageURL)
        #expect(secondStore.medicines.map(\.name) == ["Dolo 650"])
        #expect(secondStore.medicines.first?.reminderLeadDays == 7)

        try? FileManager.default.removeItem(at: storageURL.deletingLastPathComponent())
    }

    /// Verifies editing the reminder lead updates the saved medicine and refreshes its reminder.
    @Test @MainActor func storeUpdatesReminderLeadAndReschedulesReminder() async throws {
        let scheduler = SpyNotificationScheduler()
        let store = MedicineStore(notificationScheduler: scheduler)
        let manufacturing = try #require(makeDate(year: 2026, month: 5, day: 1))
        let expiry = try #require(makeDate(year: 2027, month: 5, day: 1))

        try await store.save(name: "Cetirizine", manufacturingDate: manufacturing, expiryDate: expiry)
        let medicine = try #require(store.medicines.first)
        try await store.update(medicineID: medicine.id, changes: MedicineUpdate(reminderLeadDays: 30))

        #expect(store.medicines.first?.reminderLeadDays == 30)
        #expect(scheduler.scheduledMedicineNames == ["Cetirizine", "Cetirizine"])
    }

    /// Verifies delete removes a medicine and asks the scheduler to cancel its reminder.
    @Test @MainActor func storeDeletesMedicineAndCancelsReminder() async throws {
        let scheduler = SpyNotificationScheduler()
        let store = MedicineStore(notificationScheduler: scheduler)
        let manufacturing = try #require(makeDate(year: 2026, month: 5, day: 1))
        let expiry = try #require(makeDate(year: 2027, month: 5, day: 1))

        try await store.save(name: "Cetirizine", manufacturingDate: manufacturing, expiryDate: expiry)
        let medicine = try #require(store.medicines.first)
        try await store.delete(medicine)

        #expect(store.medicines.isEmpty)
        #expect(scheduler.cancelledMedicineIDs == [medicine.id])
    }

    /// Verifies an exported backup can be imported by another store, replacing its
    /// contents, cancelling old reminders, and scheduling new ones.
    @Test @MainActor func storeExportsAndImportsBackup() async throws {
        let manufacturing = try #require(makeDate(year: 2026, month: 5, day: 1))
        let expiry = try #require(makeDate(year: 2027, month: 5, day: 1))

        let sourceStore = MedicineStore(notificationScheduler: SpyNotificationScheduler())
        try await sourceStore.save(name: "Cetirizine", manufacturingDate: manufacturing, expiryDate: expiry)
        let backup = try sourceStore.exportData()

        let scheduler = SpyNotificationScheduler()
        let destinationStore = MedicineStore(notificationScheduler: scheduler)
        try await destinationStore.save(name: "Old Med", manufacturingDate: manufacturing, expiryDate: expiry)
        let oldID = try #require(destinationStore.medicines.first?.id)

        try await destinationStore.importData(backup)

        #expect(destinationStore.medicines.map(\.name) == ["Cetirizine"])
        #expect(scheduler.cancelledMedicineIDs == [oldID])
        #expect(scheduler.scheduledMedicineNames == ["Old Med", "Cetirizine"])
    }

    /// Verifies the reminder respects the configured lead time before expiry.
    @Test func reminderDateHonorsConfiguredLeadDays() throws {
        let manufacturing = try #require(makeDate(year: 2026, month: 5, day: 1))
        let expiry = try #require(makeDate(year: 2027, month: 5, day: 1))
        let medicine = Medicine(
            name: "Insulin",
            manufacturingDate: manufacturing,
            expiryDate: expiry,
            reminderLeadDays: 30
        )

        #expect(medicine.reminderDate == Calendar.current.date(byAdding: .day, value: -30, to: expiry))
    }

    /// Verifies the expiring-soon window: not expired yet AND within 60 days of expiry.
    ///
    /// Boundaries matter here: a medicine expiring exactly 60 days from `now` still counts,
    /// one expiring 61 days out does not, and an already-expired medicine never counts.
    @Test func expiringSoonCoversOnlyTheSixtyDayWindow() throws {
        let now = try #require(makeDate(year: 2026, month: 8, day: 26))
        let manufacturing = try #require(makeDate(year: 2025, month: 1, day: 1))

        func medicine(expiringOn expiry: Date) -> Medicine {
            Medicine(name: "Test", manufacturingDate: manufacturing, expiryDate: expiry)
        }

        let expired = medicine(expiringOn: try #require(makeDate(year: 2026, month: 8, day: 25)))
        let withinWindow = medicine(expiringOn: try #require(makeDate(year: 2026, month: 9, day: 30)))
        let atWindowEdge = medicine(expiringOn: try #require(makeDate(year: 2026, month: 10, day: 25)))
        let beyondWindow = medicine(expiringOn: try #require(makeDate(year: 2026, month: 10, day: 26)))

        #expect(Medicine.expiringSoonWindowDays == 60)
        #expect(!expired.isExpiringSoon(now: now))
        #expect(withinWindow.isExpiringSoon(now: now))
        #expect(atWindowEdge.isExpiringSoon(now: now))
        #expect(!beyondWindow.isExpiringSoon(now: now))
    }

    /// Verifies the saved-medicines filters categorize by expiry status.
    ///
    /// Expired and Expiring are disjoint; medicines expiring beyond the 60-day window
    /// belong to neither and appear only under All.
    @Test func medicineFilterCategorizesByExpiryStatus() throws {
        let now = try #require(makeDate(year: 2026, month: 8, day: 26))
        let manufacturing = try #require(makeDate(year: 2025, month: 1, day: 1))

        let expired = Medicine(
            name: "Expired",
            manufacturingDate: manufacturing,
            expiryDate: try #require(makeDate(year: 2026, month: 8, day: 1))
        )
        let expiringSoon = Medicine(
            name: "Expiring",
            manufacturingDate: manufacturing,
            expiryDate: try #require(makeDate(year: 2026, month: 9, day: 15))
        )
        let farOut = Medicine(
            name: "Far Out",
            manufacturingDate: manufacturing,
            expiryDate: try #require(makeDate(year: 2027, month: 8, day: 1))
        )

        for medicine in [expired, expiringSoon, farOut] {
            #expect(MedicineFilter.all.includes(medicine, now: now))
        }
        #expect(MedicineFilter.expired.includes(expired, now: now))
        #expect(!MedicineFilter.expired.includes(expiringSoon, now: now))
        #expect(!MedicineFilter.expired.includes(farOut, now: now))
        #expect(MedicineFilter.expiring.includes(expiringSoon, now: now))
        #expect(!MedicineFilter.expiring.includes(expired, now: now))
        #expect(!MedicineFilter.expiring.includes(farOut, now: now))
    }

    /// Verifies data saved before version 1.2 (no reminderLeadDays field) still decodes,
    /// falling back to the original one-day lead. This protects old backups and upgrades.
    @Test func legacyBackupWithoutLeadDaysDecodesWithOneDayDefault() throws {
        let json = """
        [{"id":"11111111-2222-3333-4444-555555555555","name":"Dolo 650",\
        "manufacturingDate":"2026-05-01T09:00:00Z","expiryDate":"2027-05-01T09:00:00Z",\
        "snoozeMinutes":1440,"createdAt":"2026-05-01T09:00:00Z"}]
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let medicines = try decoder.decode([Medicine].self, from: Data(json.utf8))

        #expect(medicines.first?.name == "Dolo 650")
        #expect(medicines.first?.reminderLeadDays == 1)
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

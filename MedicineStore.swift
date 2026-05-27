import Foundation
import Observation

/// Storage for medicines shown by the app.
///
/// This plays the role of a small repository/service object. It keeps the medicines in
/// memory for fast UI updates and also writes them to a JSON file inside the app's own
/// sandbox. iOS deletes that sandbox automatically when the user deletes the app.
@MainActor
@Observable
final class MedicineStore {
    /// `private(set)` means other files can read `medicines`, but only this class can modify it.
    private(set) var medicines: [Medicine] = []

    private let notificationScheduler: NotificationScheduling
    private let storageURL: URL?

    /// Creates the store used by the real app, wired to iOS local notifications and disk storage.
    init() {
        self.notificationScheduler = LocalNotificationScheduler()
        self.storageURL = Self.defaultStorageURL()
        loadFromDisk()
    }

    /// Creates the store with a custom scheduler.
    ///
    /// Tests and SwiftUI previews use this to pass fake schedulers, similar to dependency
    /// injection in Java/Spring or passing mocks in JS/Python tests. Passing `nil` for
    /// `storageURL` keeps the store memory-only, which avoids tests touching real app data.
    init(notificationScheduler: NotificationScheduling, storageURL: URL? = nil) {
        self.notificationScheduler = notificationScheduler
        self.storageURL = storageURL

        if storageURL != nil {
            loadFromDisk()
        }
    }

    /// Validates, stores, persists, and schedules a reminder for a medicine.
    ///
    /// `async throws` means this function does asynchronous work and can fail. The caller
    /// must use `await` and `try`, then handle any thrown validation, disk, or notification error.
    func save(name: String, manufacturingDate: Date, expiryDate: Date, snoozeMinutes: Int) async throws {
        try MedicineValidator.validate(
            name: name,
            manufacturingDate: manufacturingDate,
            expiryDate: expiryDate
        )

        let medicine = Medicine(
            name: name,
            manufacturingDate: manufacturingDate,
            expiryDate: expiryDate,
            snoozeMinutes: snoozeMinutes
        )

        try await notificationScheduler.scheduleExpiryReminder(for: medicine)
        medicines.insert(medicine, at: 0)
        try persistToDisk()
    }

    /// Applies changes to an existing medicine, saves them to disk, and refreshes its reminder.
    ///
    /// The `MedicineUpdate` struct is intentionally broader than the current UI. Right now
    /// only snooze is editable, but future name/date edits can use the same update path.
    func update(medicineID: UUID, changes: MedicineUpdate) async throws {
        guard let index = medicines.firstIndex(where: { $0.id == medicineID }) else { return }

        let current = medicines[index]
        let updated = Medicine(
            id: current.id,
            name: changes.name ?? current.name,
            manufacturingDate: changes.manufacturingDate ?? current.manufacturingDate,
            expiryDate: changes.expiryDate ?? current.expiryDate,
            snoozeMinutes: changes.snoozeMinutes ?? current.snoozeMinutes,
            createdAt: current.createdAt
        )

        try MedicineValidator.validate(
            name: updated.name,
            manufacturingDate: updated.manufacturingDate,
            expiryDate: updated.expiryDate
        )

        try await notificationScheduler.scheduleExpiryReminder(for: updated)
        medicines[index] = updated
        try persistToDisk()
    }

    /// Removes a medicine from memory, saves the changed list to disk, and cancels its notification.
    func delete(_ medicine: Medicine) async {
        medicines.removeAll { $0.id == medicine.id }
        try? persistToDisk()
        await notificationScheduler.cancelReminder(for: medicine.id)
    }

    /// Converts the medicines into JSON data.
    ///
    /// This keeps the storage portable because the array can be exported or imported as JSON.
    func exportData() throws -> Data {
        try Self.encoder.encode(medicines)
    }

    /// Replaces the current list from previously exported JSON data and saves it to disk.
    func importData(_ data: Data) throws {
        medicines = try Self.decoder.decode([Medicine].self, from: data)
        try persistToDisk()
    }

    /// Location of the JSON file inside this app's sandbox.
    ///
    /// `Application Support` is private to this app. The system removes it when the app is
    /// uninstalled, which matches the requested behavior.
    private static func defaultStorageURL() -> URL? {
        guard let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return nil
        }

        return applicationSupportURL
            .appendingPathComponent("PillEye", isDirectory: true)
            .appendingPathComponent("medicines.json")
    }

    /// Reads medicines from disk when the app starts.
    ///
    /// If the file does not exist yet, the app starts with an empty list. If the file is
    /// damaged, the app also starts empty instead of crashing.
    private func loadFromDisk() {
        guard let storageURL, FileManager.default.fileExists(atPath: storageURL.path) else {
            medicines = []
            return
        }

        do {
            let data = try Data(contentsOf: storageURL)
            medicines = try Self.decoder.decode([Medicine].self, from: data)
        } catch {
            medicines = []
        }
    }

    /// Writes the current medicine list to the app sandbox as JSON.
    private func persistToDisk() throws {
        guard let storageURL else { return }

        let directoryURL = storageURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let data = try exportData()
        try data.write(to: storageURL, options: [.atomic])
    }

    /// Shared JSON encoder so dates are written in a stable, readable format.
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    /// Shared JSON decoder that matches the encoder above.
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

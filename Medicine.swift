import Foundation

/// The main data object for the app.
///
/// This is similar to a Java/TypeScript model class or a Python dataclass.
/// `Identifiable` lets SwiftUI use this object in lists, `Codable` lets us convert it
/// to and from JSON, and `Hashable` lets Swift compare/store it efficiently.
struct Medicine: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var manufacturingDate: Date
    var expiryDate: Date
    var reminderLeadDays: Int
    let createdAt: Date

    /// Creates a new medicine record.
    ///
    /// Parameters with `= ...` are default values, similar to optional/default
    /// parameters in Python or JavaScript. Callers can pass only the fields they need.
    init(
        id: UUID = UUID(),
        name: String,
        manufacturingDate: Date,
        expiryDate: Date,
        reminderLeadDays: Int = 1,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines).localizedCapitalized
        self.manufacturingDate = manufacturingDate
        self.expiryDate = expiryDate
        self.reminderLeadDays = reminderLeadDays
        self.createdAt = createdAt
    }

    /// Restores a medicine from saved JSON.
    ///
    /// `reminderLeadDays` was added in version 1.2, so files and backups written by
    /// older versions do not contain it. Decoding falls back to the original one-day
    /// lead instead of failing, which keeps old data and old backups importable.
    /// Older files also carry a per-medicine `snoozeMinutes` value; it is ignored now
    /// that the notification snooze uses one fixed duration.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        manufacturingDate = try container.decode(Date.self, forKey: .manufacturingDate)
        expiryDate = try container.decode(Date.self, forKey: .expiryDate)
        reminderLeadDays = try container.decodeIfPresent(Int.self, forKey: .reminderLeadDays) ?? 1
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    /// The date when the app should remind the user.
    ///
    /// This is a computed property: it behaves like a field, but Swift calculates it
    /// each time it is read. The reminder fires `reminderLeadDays` before expiry.
    var reminderDate: Date {
        Calendar.current.date(byAdding: .day, value: -reminderLeadDays, to: expiryDate) ?? expiryDate
    }

    /// Returns `true` when the medicine expiry date has already passed.
    var isExpired: Bool {
        expiryDate < Date()
    }

    /// How soon (in days) before expiry a medicine counts as "expiring soon".
    static let expiringSoonWindowDays = 60

    /// Returns `true` when the medicine has not expired yet but expires within the next
    /// `expiringSoonWindowDays` days. Already-expired medicines are excluded.
    ///
    /// The optional `now` and `calendar` parameters keep this testable with fixed inputs.
    func isExpiringSoon(now: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard expiryDate >= now else { return false }
        guard let threshold = calendar.date(byAdding: .day, value: Self.expiringSoonWindowDays, to: now) else {
            return false
        }
        return expiryDate <= threshold
    }
}

/// Describes editable changes to an existing medicine.
///
/// Today the UI only changes `reminderLeadDays`, but this struct already has fields for
/// name and dates so future edit screens can reuse the same store update function.
struct MedicineUpdate {
    var name: String?
    var manufacturingDate: Date?
    var expiryDate: Date?
    var reminderLeadDays: Int?
}

/// All validation failures that can happen while saving a medicine.
///
/// `LocalizedError` lets each error provide a user-readable message through
/// `localizedDescription`, similar to storing an error message in an exception.
enum MedicineValidationError: Error, Equatable, LocalizedError {
    case missingName
    case expiryNotAfterManufacturing

    /// Converts each validation case into text that can be shown in the UI.
    var errorDescription: String? {
        switch self {
        case .missingName:
            return "Enter a medicine name."
        case .expiryNotAfterManufacturing:
            return "Expiry date must be after the manufacturing date."
        }
    }
}

/// Holds validation rules for medicine records.
///
/// This is an `enum` with only static functions, which is a common Swift way to
/// group utility functions without allowing anyone to create an instance.
enum MedicineValidator {
    /// Checks that the form values are valid before saving.
    ///
    /// `throws` means this function can fail by throwing an error, similar to Java
    /// exceptions. Callers must use `try` and handle the error.
    static func validate(name: String, manufacturingDate: Date, expiryDate: Date) throws {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw MedicineValidationError.missingName
        }

        guard expiryDate > manufacturingDate else {
            throw MedicineValidationError.expiryNotAfterManufacturing
        }
    }
}

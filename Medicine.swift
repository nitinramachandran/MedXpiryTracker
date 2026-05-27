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
    var snoozeMinutes: Int
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
        snoozeMinutes: Int = 60,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines).localizedCapitalized
        self.manufacturingDate = manufacturingDate
        self.expiryDate = expiryDate
        self.snoozeMinutes = snoozeMinutes
        self.createdAt = createdAt
    }

    /// The date when the app should remind the user.
    ///
    /// This is a computed property: it behaves like a field, but Swift calculates it
    /// each time it is read. The reminder is one day before the expiry date.
    var reminderDate: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: expiryDate) ?? expiryDate
    }

    /// Returns `true` when the medicine expiry date has already passed.
    var isExpired: Bool {
        expiryDate < Date()
    }
}

/// Describes editable changes to an existing medicine.
///
/// Today the UI only changes `snoozeMinutes`, but this struct already has fields for
/// name and dates so future edit screens can reuse the same store update function.
struct MedicineUpdate {
    var name: String?
    var manufacturingDate: Date?
    var expiryDate: Date?
    var snoozeMinutes: Int?
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

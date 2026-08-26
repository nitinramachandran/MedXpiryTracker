import Foundation

/// Shared reminder lead times used by the form and the saved-medicine edit popup.
///
/// The lead is how long before the expiry date the reminder fires. A strip of tablets
/// may only need a day's notice, while a large or expensive bottle is worth replacing
/// weeks early so it can still be used up.
nonisolated enum ReminderLeadOption {
    static let allDays = [1, 7, 14, 30, 60]

    /// Converts a stored day count into user-friendly text.
    static func label(for days: Int) -> String {
        switch days {
        case 1:
            return "1 Day"
        case 7:
            return "1 Week"
        case 14:
            return "2 Weeks"
        case 30:
            return "1 Month"
        case 60:
            return "2 Months"
        default:
            return "\(days) days"
        }
    }
}

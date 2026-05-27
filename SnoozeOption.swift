import Foundation

/// Shared snooze durations used by the form, saved medicine rows, and edit popup.
///
/// Keeping these values in one place prevents the UI from showing different labels for
/// the same stored number of minutes.
enum SnoozeOption {
    static let allDurationsInMinutes = [1440, 10080, 43200, 86400]

    /// Converts a stored minute value into user-friendly text.
    static func label(for minutes: Int) -> String {
        switch minutes {
        case 1440:
            return "1 Day"
        case 10080:
            return "1 Week"
        case 43200:
            return "1 Month"
        case 86400:
            return "2 Months"
        default:
            return "\(minutes) minutes"
        }
    }
}

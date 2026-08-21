import Foundation
import UserNotifications

/// A small abstraction around notification scheduling.
///
/// Protocols in Swift are similar to interfaces in Java/TypeScript. The app depends
/// on this protocol so tests can provide a fake scheduler instead of using real iOS
/// notifications.
protocol NotificationScheduling {
    /// Schedules the expiry reminder for one medicine.
    func scheduleExpiryReminder(for medicine: Medicine) async throws

    /// Cancels the reminder for a medicine by its stable UUID.
    func cancelReminder(for medicineID: UUID) async
}

/// Real implementation of `NotificationScheduling` using iOS local notifications.
struct LocalNotificationScheduler: NotificationScheduling {
    static let categoryIdentifier = "MEDICINE_EXPIRY_REMINDER"
    static let snoozeActionIdentifier = "SNOOZE_MEDICINE_REMINDER"
    static let cancelActionIdentifier = "CANCEL_MEDICINE_REMINDER"

    /// How long the notification's Snooze button defers the reminder (one day).
    ///
    /// Snooze is intentionally not configurable per medicine: it is a quick "not now"
    /// on the lock screen, while `reminderLeadDays` controls the planned first alert.
    static let snoozeMinutes = 1440

    private let center: UNUserNotificationCenter

    /// Creates a scheduler using the system notification center.
    ///
    /// The default `.current()` value points to the notification center for this app.
    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    /// Requests permission if needed, builds the notification, and schedules it with iOS.
    ///
    /// The trigger is normally one day before expiry. If that time has already passed,
    /// the app schedules a near-future notification so the behavior can still be tested.
    func scheduleExpiryReminder(for medicine: Medicine) async throws {
        try await requestAuthorizationIfNeeded()
        Self.configureNotificationActions(on: center)

        let content = UNMutableNotificationContent()
        content.title = "Expiry reminder"
        content.body = medicine.reminderLeadDays == 1
            ? "One saved item expires tomorrow."
            : "One saved item expires in \(ReminderLeadOption.label(for: medicine.reminderLeadDays).lowercased())."
        AlarmNotificationSound.applyUrgency(to: content)
        content.categoryIdentifier = Self.categoryIdentifier
        content.userInfo = [
            "medicineID": medicine.id.uuidString
        ]

        let triggerDate = max(medicine.reminderDate, Date().addingTimeInterval(60))
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.identifier(for: medicine.id),
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    /// Removes pending and already-delivered notifications for this medicine.
    func cancelReminder(for medicineID: UUID) async {
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier(for: medicineID)])
        center.removeDeliveredNotifications(withIdentifiers: [Self.identifier(for: medicineID)])
    }

    /// Creates the unique notification identifier used by iOS.
    ///
    /// Keeping this in one function avoids spelling the identifier format in many places.
    static func identifier(for medicineID: UUID) -> String {
        "medicine-expiry-\(medicineID.uuidString)"
    }

    /// Registers the notification buttons that appear on the lock screen / notification UI.
    ///
    /// iOS shows these actions when a notification has this scheduler's category ID.
    static func configureNotificationActions(on center: UNUserNotificationCenter = .current()) {
        let snooze = UNNotificationAction(
            identifier: snoozeActionIdentifier,
            title: "Snooze",
            options: []
        )
        let cancel = UNNotificationAction(
            identifier: cancelActionIdentifier,
            title: "Cancel",
            options: [.destructive]
        )
        let category = UNNotificationCategory(
            identifier: categoryIdentifier,
            actions: [snooze, cancel],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        center.setNotificationCategories([category])
    }

    /// Asks the user for notification permission unless the app already has it.
    ///
    /// iOS only plays sounds or shows alerts after the user grants permission.
    private func requestAuthorizationIfNeeded() async throws {
        let settings = await center.notificationSettings()
        let status = settings.authorizationStatus
        guard status != .authorized, status != .provisional else { return }
        _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }
}

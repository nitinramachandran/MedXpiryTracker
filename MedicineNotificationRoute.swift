import Foundation

/// Small bridge between UIKit notification callbacks and the SwiftUI screen.
///
/// `AppNotificationDelegate` is a UIKit-style object, while `ContentView` is SwiftUI.
/// Posting a local `NotificationCenter` event lets the delegate announce "this medicine
/// notification was tapped" without directly knowing about the screen or the store.
@MainActor
enum MedicineNotificationRoute {
    static let medicineTapped = Notification.Name("MedicineNotificationRoute.medicineTapped")
    static let medicineIDKey = "medicineID"

    private static var pendingMedicineID: UUID?

    /// Sends an in-app event saying the user tapped the notification for one medicine.
    ///
    /// The pending ID matters when the app is opened from a notification. In that case,
    /// UIKit may receive the tap before `ContentView` has started listening.
    static func postMedicineTapped(medicineID: UUID) {
        pendingMedicineID = medicineID
        NotificationCenter.default.post(
            name: medicineTapped,
            object: nil,
            userInfo: [medicineIDKey: medicineID.uuidString]
        )
    }

    /// Returns and clears any notification tap that happened before the UI was ready.
    static func consumePendingMedicineID() -> UUID? {
        let medicineID = pendingMedicineID
        pendingMedicineID = nil
        return medicineID
    }

    /// Reads the medicine UUID back from the `NotificationCenter` event.
    static func medicineID(from notification: Notification) -> UUID? {
        guard let medicineIDString = notification.userInfo?[medicineIDKey] as? String else {
            return nil
        }

        return UUID(uuidString: medicineIDString)
    }
}

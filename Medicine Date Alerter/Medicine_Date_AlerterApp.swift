import SwiftUI

/// The app entry point.
///
/// This is the SwiftUI equivalent of `main()` in Java or the root `App` component setup
/// in a React app. The `@main` attribute tells iOS to start here.
@main
struct Medicine_Date_AlerterApp: App {
    /// Connects the UIKit app delegate so notification callbacks can be handled.
    ///
    /// SwiftUI apps do not normally have an app delegate, so this adapter bridges one in.
    @UIApplicationDelegateAdaptor(AppNotificationDelegate.self) private var notificationDelegate

    /// Describes the windows/scenes that this app can show.
    ///
    /// `WindowGroup` creates the main app window and puts `ContentView` inside it.
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

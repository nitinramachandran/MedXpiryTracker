import XCTest

/// UI tests that launch the app and interact with it like a user would.
///
/// UI tests are slower than unit tests because they run the full app in a simulator or device.
final class Medicine_Date_AlerterUITests: XCTestCase {

    /// Runs before each UI test.
    ///
    /// `continueAfterFailure = false` stops the test immediately after the first failure,
    /// which usually makes UI failures easier to understand.
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Runs after each UI test.
    ///
    /// This is empty for now, but it is where cleanup code would go if tests created
    /// shared state that needed to be reset.
    override func tearDownWithError() throws {}

    /// Verifies that the app can launch successfully.
    ///
    /// This is intentionally simple. More UI tests can later type into fields and tap
    /// buttons using the accessibility identifiers defined in `ContentView`.
    @MainActor
    func testExample() throws {
        let app = XCUIApplication()
        app.launch()
    }

    /// Measures how long the app takes to launch.
    ///
    /// Xcode records this as a performance metric so future changes can be compared.
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}

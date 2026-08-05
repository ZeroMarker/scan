import XCTest

/// Equivalent of the Android MainScreenTest.
final class MainScreenUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testStartScanningButtonExists() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Start Scanning"].exists)
    }
}

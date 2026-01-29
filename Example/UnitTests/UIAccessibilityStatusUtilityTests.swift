import AccessibilitySnapshotParser_ObjC
import XCTest

final class UIAccessibilityStatusUtilityTests: XCTestCase {
    func testInvertColorsStatus() {
        let statusUtility = UIAccessibilityStatusUtility()

        XCTAssertFalse(UIAccessibility.isInvertColorsEnabled)

        statusUtility.mockInvertColorsStatus()
        XCTAssertTrue(UIAccessibility.isInvertColorsEnabled)

        statusUtility.unmockStatuses()
        XCTAssertFalse(UIAccessibility.isInvertColorsEnabled)
    }
}

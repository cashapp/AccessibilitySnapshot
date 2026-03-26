import FBSnapshotTestCase_Accessibility
import iOSSnapshotTestCase

@testable import AccessibilitySnapshotDemo

final class SwiftUIMenuTests: SnapshotTestCase {
    func testMenu() {
        if #available(iOS 14.0, *) {
            SnapshotVerifyAccessibility(SwiftUIMenu(), size: UIScreen.main.bounds.size)
        }
    }

    func testMenuAtSizeThatFits() {
        if #available(iOS 14.0, *) {
            SnapshotVerifyAccessibility(SwiftUIMenu())
        }
    }
}

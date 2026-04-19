import FBSnapshotTestCase_Accessibility
import iOSSnapshotTestCase

@testable import AccessibilitySnapshotDemo

final class SwiftUIDisclosureGroupTests: SnapshotTestCase {
    override func setUp() {
        super.setUp()
        recordMode = true
    }

    func testDisclosureGroup() {
        if #available(iOS 16.0, *) {
            SnapshotVerifyAccessibility(SwiftUIDisclosureGroup(), size: UIScreen.main.bounds.size)
        }
    }
}

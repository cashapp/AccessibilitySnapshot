import FBSnapshotTestCase_Accessibility
import iOSSnapshotTestCase

@testable import AccessibilitySnapshotDemo

final class SwiftUIDisclosureGroupTests: SnapshotTestCase {
    func testDisclosureGroup() {
        if #available(iOS 16.0, *) {
            SnapshotVerifyAccessibility(SwiftUIDisclosureGroup(), size: UIScreen.main.bounds.size)
        }
    }
}

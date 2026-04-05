import FBSnapshotTestCase_Accessibility
import iOSSnapshotTestCase

@testable import AccessibilitySnapshotDemo

final class SwiftUISnapshotTests: SnapshotTestCase {
    func testSimpleView() {
        SnapshotVerifyAccessibility(SwiftUIView(), size: UIScreen.main.bounds.size)
    }

    func testSimpleViewAtSizeThatFits() {
        SnapshotVerifyAccessibility(SwiftUIView())
    }
}

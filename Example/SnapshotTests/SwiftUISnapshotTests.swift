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

    @available(iOS 16.0, *)
    func testSearchableToolbarPlacement() {
        SnapshotVerifyAccessibility(SwiftUISearchableView(), size: UIScreen.main.bounds.size)
    }
}

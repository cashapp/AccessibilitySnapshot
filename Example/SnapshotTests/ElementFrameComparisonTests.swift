import FBSnapshotTestCase_Accessibility
import iOSSnapshotTestCase

@testable import AccessibilitySnapshotDemo

final class ElementFrameComparisonTests: SnapshotTestCase {
    func testFrames() {
        let viewController = ElementFrameComparisonController()
        viewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(viewController.view)
    }
}

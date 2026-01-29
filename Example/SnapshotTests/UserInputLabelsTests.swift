import FBSnapshotTestCase_Accessibility
import iOSSnapshotTestCase

@testable import AccessibilitySnapshotDemo

final class UserInputLabelsTests: SnapshotTestCase {
    func testUserInputLabels() {
        let viewController = UserInputLabelsViewController()
        viewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(viewController.view)
    }

    func testUserInputLabels_defaults() {
        let viewController = UserInputLabelsViewController()
        viewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(viewController.view, snapshotConfiguration: .init(viewRenderingMode: viewRenderingMode, includesInputLabels: .always))
    }
}

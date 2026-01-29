import FBSnapshotTestCase_Accessibility
import iOSSnapshotTestCase

@testable import AccessibilitySnapshotDemo

final class ActivationPointTests: SnapshotTestCase {
    func testActivationPointDisabled() {
        let viewController = ActivationPointViewController()
        viewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(
            viewController.view,
            snapshotConfiguration: .init(viewRenderingMode: viewRenderingMode, activationPointDisplay: .never)
        )
    }

    func testActivationPointEnabledWhenOverridden() {
        let viewController = ActivationPointViewController()
        viewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(
            viewController.view,
            snapshotConfiguration: .init(viewRenderingMode: viewRenderingMode, activationPointDisplay: .whenOverridden)
        )
    }

    func testActivationPointEnabled() {
        let viewController = ActivationPointViewController()
        viewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(
            viewController.view,
            snapshotConfiguration: .init(viewRenderingMode: viewRenderingMode, activationPointDisplay: .always)
        )
    }
}

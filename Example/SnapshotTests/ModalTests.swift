import FBSnapshotTestCase_Accessibility
import iOSSnapshotTestCase

@testable import AccessibilitySnapshotDemo

final class ModalTests: SnapshotTestCase {
    func testSingleModal() {
        let vc = ModalAccessibilityViewController(configuration: .singleModal)
        vc.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(vc.view)
    }

    func testSingleDirectlySpecifiedModal() {
        let vc = ModalAccessibilityViewController(configuration: .singleDirectModal)
        vc.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(vc.view)
    }

    func testSingleInaccessibleModal() {
        let vc = ModalAccessibilityViewController(configuration: .singleInaccessibleModal)
        vc.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(vc.view)
    }

    func testTwoModals() {
        let vc = ModalAccessibilityViewController(configuration: .twoModals)
        vc.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(vc.view)
    }

    func testModalWithForeground() {
        let vc = ModalAccessibilityViewController(configuration: .modalWithForeground)
        vc.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(vc.view)
    }
}

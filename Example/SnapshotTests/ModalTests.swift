import FBSnapshotTestCase_Accessibility
import iOSSnapshotTestCase

@testable import AccessibilitySnapshotDemo

final class ModalTests: SnapshotTestCase {
    func testSingleModal() {
        let modalAccessibilityViewController = ModalAccessibilityViewController(
            topLevelCount: 1,
            containerCount: 0,
            modalAccessibilityMode: .viewContainsAccessibleElement
        )
        modalAccessibilityViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(modalAccessibilityViewController.view)
    }

    func testSingleDirectlySpecifiedModal() {
        let modalAccessibilityViewController = ModalAccessibilityViewController(
            topLevelCount: 1,
            containerCount: 0,
            modalAccessibilityMode: .viewIsAccessible
        )
        modalAccessibilityViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(modalAccessibilityViewController.view)
    }

    func testSingleInaccessibleModal() {
        let modalAccessibilityViewController = ModalAccessibilityViewController(
            topLevelCount: 1,
            containerCount: 0,
            modalAccessibilityMode: .viewIsInaccessible
        )
        modalAccessibilityViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(modalAccessibilityViewController.view)
    }

    func testTwoModals() {
        let modalAccessibilityViewController = ModalAccessibilityViewController(
            topLevelCount: 2,
            containerCount: 0,
            modalAccessibilityMode: .viewContainsAccessibleElement
        )
        modalAccessibilityViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(modalAccessibilityViewController.view)
    }

    func testTwoContainers() {
        let modalAccessibilityViewController = ModalAccessibilityViewController(
            topLevelCount: 0,
            containerCount: 2,
            modalAccessibilityMode: .viewContainsAccessibleElement
        )
        modalAccessibilityViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(modalAccessibilityViewController.view)
    }

    func testOneModalOneContainer() {
        let modalAccessibilityViewController = ModalAccessibilityViewController(
            topLevelCount: 1,
            containerCount: 1,
            modalAccessibilityMode: .viewContainsAccessibleElement
        )
        modalAccessibilityViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(modalAccessibilityViewController.view)
    }
}

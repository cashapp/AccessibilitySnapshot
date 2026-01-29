import FBSnapshotTestCase_Accessibility
import iOSSnapshotTestCase

@testable import AccessibilitySnapshotDemo

final class ElementOrderTests: SnapshotTestCase {
    func testScatter() {
        let elementOrderViewController = ElementOrderViewController(configurations: .scatter)
        elementOrderViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementOrderViewController.view)
    }

    func testGrid() {
        let elementOrderViewController = ElementOrderViewController(configurations: .grid)
        elementOrderViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementOrderViewController.view)
    }

    func testContainerInElementStack() {
        let elementOrderViewController = ElementOrderViewController(configurations: .containerInElementStack)
        elementOrderViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementOrderViewController.view)
    }

    func testZeroSizedContainerInElementStack() {
        let elementOrderViewController = ElementOrderViewController(configurations: .zeroSizedContainerInElementStack)
        elementOrderViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementOrderViewController.view)
    }

    func testGroupedViewsInElementStack() {
        let elementOrderViewController = ElementOrderViewController(configurations: .groupedViewsInElementStack)
        elementOrderViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementOrderViewController.view)
    }

    func testUngroupedViewsInElementStack() {
        let elementOrderViewController = ElementOrderViewController(configurations: .ungroupedViewsInElementStack)
        elementOrderViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementOrderViewController.view)
    }

    func testUngroupedViewsInAccessibleParent() {
        let elementOrderViewController = ElementOrderViewController(configurations: .ungroupedViewsInAccessibleParent)
        elementOrderViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementOrderViewController.view)
    }
}

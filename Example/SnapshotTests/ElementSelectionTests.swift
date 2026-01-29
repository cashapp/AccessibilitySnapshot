import FBSnapshotTestCase_Accessibility
import iOSSnapshotTestCase

@testable import AccessibilitySnapshotDemo

final class ElementSelectionTests: SnapshotTestCase {
    func testTwoAccessibilityElements() {
        let elementSelectionViewController = ElementSelectionViewController(
            configurations: .twoAccessibilityElements
        )
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementSelectionViewController.view)
    }

    func testAccessibilityElementWithElementsHidden() {
        let elementSelectionViewController = ElementSelectionViewController(
            configurations: .accessibilityElementWithElementsHidden
        )
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementSelectionViewController.view)
    }

    func testAccessibilityElementHidden() {
        let elementSelectionViewController = ElementSelectionViewController(
            configurations: .accessibilityElementHidden
        )
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementSelectionViewController.view)
    }

    func testNoAccessibilityElements() {
        let elementSelectionViewController = ElementSelectionViewController(
            configurations: .noAccessibilityElements
        )
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementSelectionViewController.view)
    }

    func testMixedAccessibilityElements() {
        let elementSelectionViewController = ElementSelectionViewController(
            configurations: .mixedAccessibilityElements
        )
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementSelectionViewController.view)
    }

    func testAccessibilityContainer() {
        let elementSelectionViewController = ElementSelectionViewController(
            configurations: .accessibilityContainer
        )
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementSelectionViewController.view)
    }

    func testAccessibilityContainerWithElementsHidden() {
        let elementSelectionViewController = ElementSelectionViewController(
            configurations: .accessibilityContainerWithElementsHidden
        )
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementSelectionViewController.view)
    }

    func testAccessibilityContainerHidden() {
        let elementSelectionViewController = ElementSelectionViewController(
            configurations: .accessibilityContainerHidden
        )
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementSelectionViewController.view)
    }

    func testGroupedViews() {
        let elementSelectionViewController = ElementSelectionViewController(
            configurations: .groupedViews
        )
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementSelectionViewController.view)
    }

    func testGroupedViewsInParentThatHidesElements() {
        let elementSelectionViewController = ElementSelectionViewController(
            configurations: .groupedViewsInParentThatHidesElements
        )
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementSelectionViewController.view)
    }

    func testGroupedViewsInHiddenParent() {
        let elementSelectionViewController = ElementSelectionViewController(
            configurations: .groupedViewsInHiddenParent
        )
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementSelectionViewController.view)
    }
}

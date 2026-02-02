@testable import SwiftUIExperimentalDemo

@available(iOS 18.0, *)
final class SwiftUIRendererTests: SwiftUIExperimentalTestCase {
    func testBasicAccessibilityDemo() {
        snapshotVerifyAccessibility(BasicAccessibilityDemo())
    }

    func testCustomActionsDemo() {
        snapshotVerifyAccessibility(CustomActionsDemo())
    }

    func testCustomRotorsDemo() {
        snapshotVerifyAccessibility(CustomRotorsDemo())
    }

    func testInputLabelsDemo() {
        snapshotVerifyAccessibility(InputLabelsDemo())
    }

    func testActivationPointDemo() {
        snapshotVerifyAccessibility(ActivationPointDemo())
    }

    func testSortPriorityDemo() {
        snapshotVerifyAccessibility(SortPriorityDemo())
    }

    func testContainersDemo() {
        snapshotVerifyAccessibility(ContainersDemo())
    }
}

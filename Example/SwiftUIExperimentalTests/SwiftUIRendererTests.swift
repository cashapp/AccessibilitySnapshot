import AccessibilitySnapshotCore
import FBSnapshotTestCase_Accessibility
import iOSSnapshotTestCase
@testable import SwiftUIExperimentalDemo

@available(iOS 16.0, *)
final class SwiftUIRendererTests: SnapshotTestCase {
    override var layoutEngine: LayoutEngine { .swiftui }

    func testBasicAccessibilityDemo() {
        snapshotVerifyAccessibility(BasicAccessibilityDemo())
    }

    func testCustomActionsDemo() {
        snapshotVerifyAccessibility(CustomActionsDemo())
    }

    func testCustomRotorsDemo() {
        snapshotVerifyAccessibility(CustomRotorsDemo())
    }

    func testCustomContentDemo() {
        snapshotVerifyAccessibility(CustomContentDemo())
    }
}

import UIKit

@testable import AccessibilitySnapshotPreviewsDemo

@available(iOS 16.0, *)
final class SwiftUIRendererTests: AccessibilitySnapshotPreviewsTestCase {
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

    func testPathShapesDemo() {
        snapshotVerifyAccessibility(PathShapesDemo())
    }

    func testUnspokenTraitsDemo() {
        snapshotVerifyAccessibility(UnspokenTraitsDemoView())
    }

    /// In `.always` mode, elements without authored input labels must show the synthesized Voice
    /// Control defaults (label split on spaces, plus trait phrases), matching the UIKit renderer.
    func testBasicAccessibilityDemoWithInputLabelsAlways() {
        SnapshotVerifyAccessibility(
            BasicAccessibilityDemo(),
            size: UIScreen.main.bounds.size,
            layoutEngine: .swiftui,
            snapshotConfiguration: .init(viewRenderingMode: viewRenderingMode, includesInputLabels: .always)
        )
    }
}

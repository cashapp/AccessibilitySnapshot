import AccessibilitySnapshotCore
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

    func testContainerDemoWithoutContainers() {
        snapshotVerifyAccessibility(
            ContainerDemo(),
            identifier: "no_containers"
        )
    }

    func testContainerDemo() {
        snapshotVerifyAccessibility(
            ContainerDemo(),
            configuration: .init(viewRenderingMode: .renderLayerInContext, showContainers: true)
        )
    }
}

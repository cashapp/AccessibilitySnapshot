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
            configuration: .init(viewRenderingMode: .drawHierarchyInRect, showContainers: true)
        )
    }

    func testListContainerDemo() {
        snapshotVerifyAccessibility(
            ListContainerDemo(),
            configuration: .init(viewRenderingMode: .drawHierarchyInRect, showContainers: true)
        )
    }

    func testLandmarkContainerDemo() {
        snapshotVerifyAccessibility(
            LandmarkContainerDemo(),
            configuration: .init(viewRenderingMode: .drawHierarchyInRect, showContainers: true)
        )
    }

    func testDataTableContainerDemo() {
        snapshotVerifyAccessibility(
            DataTableContainerDemo(),
            configuration: .init(viewRenderingMode: .drawHierarchyInRect, showContainers: true)
        )
    }

    func testSwiftUITableDemo() {
        snapshotVerifyAccessibility(
            SwiftUITableDemo(),
            configuration: .init(viewRenderingMode: .drawHierarchyInRect, showContainers: true)
        )
    }

    func testTabBarContainerDemo() {
        snapshotVerifyAccessibility(
            TabBarContainerDemo(),
            configuration: .init(viewRenderingMode: .drawHierarchyInRect, showContainers: true)
        )
    }
}

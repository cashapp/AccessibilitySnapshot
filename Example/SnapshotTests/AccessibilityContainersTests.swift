@testable import AccessibilitySnapshot
import FBSnapshotTestCase

@testable import AccessibilitySnapshotDemo

final class AccessibilityContainersTests: SnapshotTestCase {

    // This test technically doesn't match VoiceOver behavior. VoiceOver says the
    // last cell is element "5 of 1," which seems like a bug in VoiceOver that isn't
    // easy to replicate in the snapshots.
    func testDataTable() {
        let viewController = DataTableViewController(configuration: .basic)
        viewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(viewController.view)
    }

    func testDataTableWithHeaders() {
        let viewController = DataTableViewController(configuration: .withHeaders)
        viewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(viewController.view)
    }

    func testDataTableWithUndefinedRows() {
        let viewController = DataTableViewController(configuration: .undefinedRows)
        viewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(viewController.view)
    }

    // This test is disabled because it doesn't match VoiceOver behavior. The handling
    // of cells with `NSNotFound` columns seems to use a similar scanning algorithm to
    // figure out which cell is the beginning of each row.
    func testDataTableWithUndefinedColumns() {
        let viewController = DataTableViewController(configuration: .undefinedColumns)
        viewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(viewController.view)
    }

    // This test is disabled because it doesn't match VoiceOver behavior. See comment
    // above on the handling of cells with `NSNotFound` columns.
    func testDataTableWithUndefinedRowsAndColumns() {
        let viewController = DataTableViewController(configuration: .undefinedRowsAndColumns)
        viewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(viewController.view)
    }

    func testList() {
        let viewController = ListContainerViewController()
        viewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(viewController.view)
    }

    func testLandmark() {
        let viewController = LandmarkContainerViewController()
        viewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(viewController.view)
    }

    func testContainerHierarchy() {
        let viewController = ContainerHierarchyViewController()
        viewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(
            viewController.view,
            snapshotConfiguration: .withContainers()
        )
    }

}


extension AccessibilitySnapshotConfiguration {
    
    /// Creates a configuration with container visualization enabled.
    ///
    /// This is a convenience factory method that returns a configuration suitable for
    /// visualizing accessibility containers with dashed borders around semantic groups,
    /// lists, landmarks, and other container types.
    ///
    /// - Parameter viewRenderingMode: The preferred strategy for converting a view to an image. Defaults to `.drawHierarchyInRect`.
    /// - Returns: A configuration with `showContainers` enabled.
    fileprivate static func withContainers(
        viewRenderingMode: ViewRenderingMode = .drawHierarchyInRect
    ) -> AccessibilitySnapshotConfiguration {
        return AccessibilitySnapshotConfiguration(
            snapshot: Snapshot(viewRenderingMode: viewRenderingMode, colorMode: .monochrome),
            overlay: Overlay(colors: MarkerColors.defaultColors, activationPointDisplay: .whenOverridden, showContainers: true),
            legend: Legend()
        )
    }

}

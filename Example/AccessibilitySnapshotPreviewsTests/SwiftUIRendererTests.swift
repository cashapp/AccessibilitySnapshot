import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
@testable import AccessibilitySnapshotPreviews
@testable import AccessibilitySnapshotPreviewsDemo
import SwiftUI
import XCTest

@available(iOS 16.0, *)
final class SwiftUIInputLabelTests: XCTestCase {
    func testLegendEntryUsesInputLabelDisplayMode() throws {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
        view.isAccessibilityElement = true
        view.accessibilityLabel = "Label"
        view.accessibilityRespondsToUserInteraction = true
        for (labels, mode, expected) in [
            (["Label"], AccessibilityContentDisplayMode.whenOverridden, []),
            (["Label"], .always, ["Label"]),
            (["Custom"], .whenOverridden, ["Custom"]),
            (["Custom"], .never, []),
        ] {
            view.accessibilityUserInputLabels = labels
            let marker = try XCTUnwrap(AccessibilityHierarchyParser().parseAccessibilityHierarchy(in: view).flattenToElements().first)
            let entry = LegendEntryView(
                index: 0,
                marker: marker,
                palette: .default,
                configuration: .init(viewRenderingMode: .renderLayerInContext, includesInputLabels: mode, showsUnspokenTraits: false)
            )
            XCTAssertEqual(entry.userInputLabels, expected)
            XCTAssertFalse(entry.configuration.showsUnspokenTraits)
        }
    }

    func testLegendAcceptsSharedConfiguration() {
        let configuration = AccessibilitySnapshotConfiguration(
            viewRenderingMode: .renderLayerInContext,
            includesInputLabels: .always,
            showsUnspokenTraits: false
        )
        let legend = LegendView(markers: [], palette: .default, configuration: configuration)
        XCTAssertTrue(legend.showUserInputLabels)
        XCTAssertFalse(legend.showUnspokenTraits)

        let legacyLegend = LegendView(markers: [], palette: .default, showUserInputLabels: false)
        XCTAssertFalse(legacyLegend.showUserInputLabels)
        XCTAssertTrue(legacyLegend.showUnspokenTraits)
    }
}

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
}

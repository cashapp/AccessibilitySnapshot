@testable import AccessibilitySnapshotCore
@testable import AccessibilitySnapshotParser
import UIKit
import XCTest

final class InputLabelDisplayTests: XCTestCase {
    func testDefaultTableCellInputLabelEchoIsHiddenWhenOverridden() throws {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.frame = CGRect(x: 0, y: 0, width: 200, height: 44)
        cell.isAccessibilityElement = true
        cell.accessibilityLabel = "Row label"
        let marker = try XCTUnwrap(AccessibilityHierarchyParser().parseAccessibilityHierarchy(in: cell).flattenToElements().first)
        XCTAssertEqual(marker.userInputLabels, ["Row label"])
        let legend = AccessibilitySnapshotView.LegendView(
            marker: marker,
            fillColor: .red,
            configuration: .init(viewRenderingMode: .renderLayerInContext, includesInputLabels: .whenOverridden)
        )
        XCTAssertFalse(legend.subviews.contains { $0 is AccessibilitySnapshotView.PillsView })
    }

    func testInputLabelDisplayModes() throws {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
        view.isAccessibilityElement = true
        view.accessibilityLabel = "Row label"
        view.accessibilityRespondsToUserInteraction = true
        let always = AccessibilitySnapshotConfiguration(viewRenderingMode: .renderLayerInContext, includesInputLabels: .always)
        let whenOverridden = AccessibilitySnapshotConfiguration(viewRenderingMode: .renderLayerInContext, includesInputLabels: .whenOverridden)
        let never = AccessibilitySnapshotConfiguration(viewRenderingMode: .renderLayerInContext, includesInputLabels: .never)
        for (labels, expectedOverrides) in [
            (["Row label"], []),
            (["Select row"], ["Select row"]),
            (["Row label", "Select row"], ["Row label", "Select row"]),
        ] {
            view.accessibilityUserInputLabels = labels
            let marker = try XCTUnwrap(AccessibilityHierarchyParser().parseAccessibilityHierarchy(in: view).flattenToElements().first)
            XCTAssertEqual(marker.userInputLabels, labels)
            XCTAssertEqual(always.inputLabels(for: marker), labels)
            XCTAssertEqual(whenOverridden.inputLabels(for: marker), expectedOverrides)
            XCTAssertEqual(never.inputLabels(for: marker), [])
        }
        view.accessibilityRespondsToUserInteraction = false
        view.accessibilityUserInputLabels = ["Select row"]
        let noninteractive = try XCTUnwrap(AccessibilityHierarchyParser().parseAccessibilityHierarchy(in: view).flattenToElements().first)
        XCTAssertEqual(whenOverridden.inputLabels(for: noninteractive), [])
        XCTAssertEqual(always.inputLabels(for: noninteractive), ["Select row"])
    }

    func testAlwaysInputLabelsUsesDefaultWordsAndTraits() throws {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
        view.isAccessibilityElement = true
        view.accessibilityLabel = "Volume control"
        view.accessibilityTraits = [.button, .adjustable]
        view.accessibilityLanguage = "en-US"
        let always = AccessibilitySnapshotConfiguration(viewRenderingMode: .renderLayerInContext, includesInputLabels: .always)
        let whenOverridden = AccessibilitySnapshotConfiguration(viewRenderingMode: .renderLayerInContext, includesInputLabels: .whenOverridden)
        let never = AccessibilitySnapshotConfiguration(viewRenderingMode: .renderLayerInContext, includesInputLabels: .never)
        for labels: [String]? in [nil, []] {
            view.accessibilityUserInputLabels = labels
            let marker = try XCTUnwrap(AccessibilityHierarchyParser().parseAccessibilityHierarchy(in: view).flattenToElements().first)
            XCTAssertEqual(always.inputLabels(for: marker), ["Volume", "control", "Button.", "Adjustable."])
            XCTAssertEqual(whenOverridden.inputLabels(for: marker), [])
            XCTAssertEqual(never.inputLabels(for: marker), [])
        }
    }

    func testUIKitLegendInputLabelDisplayModes() throws {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
        view.isAccessibilityElement = true
        view.accessibilityLabel = "Label"
        view.accessibilityRespondsToUserInteraction = true
        for (labels, mode, showsPills) in [
            (["Label"], AccessibilityContentDisplayMode.whenOverridden, false),
            (["Label"], .always, true),
            (["Custom"], .whenOverridden, true),
            (["Custom"], .never, false),
        ] {
            view.accessibilityUserInputLabels = labels
            let marker = try XCTUnwrap(AccessibilityHierarchyParser().parseAccessibilityHierarchy(in: view).flattenToElements().first)
            let legend = AccessibilitySnapshotView.LegendView(
                marker: marker,
                fillColor: .red,
                configuration: .init(viewRenderingMode: .renderLayerInContext, includesInputLabels: mode)
            )
            XCTAssertEqual(legend.subviews.contains { $0 is AccessibilitySnapshotView.PillsView }, showsPills)
        }
    }
}

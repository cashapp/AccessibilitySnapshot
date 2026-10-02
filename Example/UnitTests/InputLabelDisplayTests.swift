@testable import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import UIKit
import XCTest

final class InputLabelDisplayTests: XCTestCase {
    func testInputLabelDisplayModes() {
        let always = AccessibilitySnapshotConfiguration(viewRenderingMode: .renderLayerInContext, includesInputLabels: .always)
        let whenOverridden = AccessibilitySnapshotConfiguration(viewRenderingMode: .renderLayerInContext, includesInputLabels: .whenOverridden)
        let never = AccessibilitySnapshotConfiguration(viewRenderingMode: .renderLayerInContext, includesInputLabels: .never)
        let fallback = ["Volume", "control", "Button.", "Adjustable."]
        for (labels, interactive, expectedAlways, expectedOverrides) in [
            (nil as [String]?, true, fallback, []),
            ([], true, fallback, []),
            (["Volume control"], true, ["Volume control"], []),
            (["Set volume"], true, ["Set volume"], ["Set volume"]),
            (["Volume control", "Set volume"], true, ["Volume control", "Set volume"], ["Volume control", "Set volume"]),
            (["Set volume"], false, ["Set volume"], []),
        ] {
            let marker = AccessibilityMarker(
                description: "Volume control. Button. Adjustable.",
                label: "Volume control",
                value: nil,
                traits: [.button, .adjustable],
                identifier: nil,
                hint: nil,
                userInputLabels: labels,
                shape: .frame(.zero),
                activationPoint: .zero,
                usesDefaultActivationPoint: true,
                customActions: [],
                customContent: [],
                customRotors: [],
                accessibilityLanguage: "en-US",
                respondsToUserInteraction: interactive
            )
            XCTAssertEqual(always.inputLabels(for: marker), expectedAlways)
            XCTAssertEqual(whenOverridden.inputLabels(for: marker), expectedOverrides)
            XCTAssertEqual(never.inputLabels(for: marker), [])
        }
    }

    func testUIKitLegendUsesInputLabelDisplayMode() {
        let marker = AccessibilityMarker(
            description: "Label",
            label: "Label",
            value: nil,
            traits: [],
            identifier: nil,
            hint: nil,
            userInputLabels: ["Label"],
            shape: .frame(.zero),
            activationPoint: .zero,
            usesDefaultActivationPoint: true,
            customActions: [],
            customContent: [],
            customRotors: [],
            accessibilityLanguage: "en-US",
            respondsToUserInteraction: true
        )
        for (mode, showsPills) in [
            (AccessibilityContentDisplayMode.whenOverridden, false),
            (.always, true),
        ] {
            let legend = AccessibilitySnapshotView.LegendView(
                marker: marker,
                fillColor: .red,
                configuration: .init(viewRenderingMode: .renderLayerInContext, includesInputLabels: mode)
            )
            XCTAssertEqual(legend.subviews.contains { $0 is AccessibilitySnapshotView.PillsView }, showsPills)
        }
    }
}

import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
@testable import AccessibilitySnapshotPreviews
@testable import AccessibilitySnapshotPreviewsDemo
import SwiftUI
import XCTest

@available(iOS 16.0, *)
final class SwiftUIInputLabelTests: XCTestCase {
    func testLegendEntryHidesInputLabelEchoWhenOverridden() {
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
        for (mode, expected) in [
            (AccessibilityContentDisplayMode.whenOverridden, []),
            (.always, ["Label"]),
        ] {
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

    @MainActor
    func testSnapshotRendersFallbackInputLabelsOnlyWhenAlways() {
        let marker = AccessibilityMarker(
            description: "Volume control. Button. Adjustable.",
            label: "Volume control",
            value: nil,
            traits: [.button, .adjustable],
            identifier: nil,
            hint: nil,
            userInputLabels: nil,
            shape: .frame(.zero),
            activationPoint: .zero,
            usesDefaultActivationPoint: true,
            customActions: [],
            customContent: [],
            customRotors: [],
            accessibilityLanguage: "en-US",
            respondsToUserInteraction: true
        )
        let renderSize = CGSize(width: 400, height: 40)
        let image = UIGraphicsImageRenderer(size: renderSize).image { _ in }
        let heights = [AccessibilityContentDisplayMode.always, .whenOverridden].map { mode in
            let snapshot = PreParsedAccessibilitySnapshotView(
                snapshotImage: image,
                markers: [marker],
                configuration: .init(viewRenderingMode: .renderLayerInContext, includesInputLabels: mode, showsUnspokenTraits: false),
                renderSize: renderSize
            )
            let hosting = UIHostingController(rootView: snapshot)
            return hosting.sizeThatFits(in: CGSize(width: renderSize.width, height: UIView.layoutFittingExpandedSize.height)).height
        }
        XCTAssertGreaterThan(heights[0], heights[1])
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

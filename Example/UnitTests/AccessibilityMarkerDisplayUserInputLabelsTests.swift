@testable import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import XCTest

/// Coverage for `AccessibilityMarker.displayUserInputLabels(_:)`, the input-label resolution shared
/// by the UIKit and SwiftUI legend renderers. In particular, `.always` mode must synthesize the
/// Voice Control default labels (the accessibility label split on spaces, plus trait phrases) for
/// elements without authored input labels, since the parser no longer surfaces UIKit's derived echo.
final class AccessibilityMarkerDisplayUserInputLabelsTests: XCTestCase {
    func testAlwaysSynthesizesDefaultLabelsWhenNoneAuthored() {
        XCTAssertEqual(
            makeMarker(label: "Add item").displayUserInputLabels(.always),
            ["Add", "item"]
        )
        XCTAssertEqual(
            makeMarker(label: "Add item", traits: [.button, .adjustable]).displayUserInputLabels(.always),
            ["Add", "item", Strings.buttonInputLabelText(for: nil), Strings.adjustableInputLabelText(for: nil)]
        )
    }

    func testAlwaysUsesAuthoredLabels() {
        XCTAssertEqual(
            makeMarker(label: "Submit", userInputLabels: ["Send", "Go"]).displayUserInputLabels(.always),
            ["Send", "Go"]
        )
    }

    func testWhenOverriddenRequiresAuthoredLabelsAndUserInteraction() {
        XCTAssertEqual(
            makeMarker(label: "Submit", userInputLabels: ["Send"], respondsToUserInteraction: true).displayUserInputLabels(.whenOverridden),
            ["Send"]
        )
        XCTAssertNil(
            makeMarker(label: "Submit", userInputLabels: ["Send"], respondsToUserInteraction: false).displayUserInputLabels(.whenOverridden)
        )
        XCTAssertNil(
            makeMarker(label: "Submit", respondsToUserInteraction: true).displayUserInputLabels(.whenOverridden)
        )
    }

    func testNeverShowsNothing() {
        XCTAssertNil(
            makeMarker(label: "Submit", userInputLabels: ["Send"], respondsToUserInteraction: true).displayUserInputLabels(.never)
        )
    }

    // MARK: - Private Helpers

    private func makeMarker(
        label: String?,
        traits: AccessibilityTraits = [],
        userInputLabels: [String]? = nil,
        respondsToUserInteraction: Bool = false
    ) -> AccessibilityMarker {
        AccessibilityMarker(
            description: label ?? "",
            label: label,
            value: nil,
            traits: traits,
            identifier: nil,
            hint: nil,
            userInputLabels: userInputLabels,
            shape: .frame(AccessibilityRect(x: 0, y: 0, width: 100, height: 44)),
            activationPoint: AccessibilityPoint(x: 50, y: 22),
            usesDefaultActivationPoint: true,
            customActions: [],
            customContent: [],
            customRotors: [],
            accessibilityLanguage: nil,
            respondsToUserInteraction: respondsToUserInteraction
        )
    }
}

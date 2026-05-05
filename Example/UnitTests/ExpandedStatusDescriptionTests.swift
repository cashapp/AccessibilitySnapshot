@testable import AccessibilitySnapshotParser
import UIKit
import XCTest

final class ExpandedStatusDescriptionTests: XCTestCase {
    func testExpandedAppendsToDescription() {
        let view = UIView()
        view.isAccessibilityElement = true
        view.accessibilityLabel = "Section"

        let (description, hint) = view.accessibilityDescription(context: nil, expandedStatus: .expanded)

        XCTAssertEqual(description, "Section. Expanded.")
        XCTAssertEqual(hint, "Double tap to collapse.")
    }

    func testCollapsedAppendsToDescription() {
        let view = UIView()
        view.isAccessibilityElement = true
        view.accessibilityLabel = "Section"

        let (description, hint) = view.accessibilityDescription(context: nil, expandedStatus: .collapsed)

        XCTAssertEqual(description, "Section. Collapsed.")
        XCTAssertEqual(hint, "Double tap to expand.")
    }

    func testUnsupportedLeavesDescriptionAndHintAlone() {
        let view = UIView()
        view.isAccessibilityElement = true
        view.accessibilityLabel = "Section"

        let (description, hint) = view.accessibilityDescription(context: nil, expandedStatus: .unsupported)

        XCTAssertEqual(description, "Section")
        XCTAssertNil(hint)
    }

    func testExpandedHintConcatenatesWithExistingHint() {
        let view = UIView()
        view.isAccessibilityElement = true
        view.accessibilityLabel = "Section"
        view.accessibilityHint = "Shows more content."

        let (_, hint) = view.accessibilityDescription(context: nil, expandedStatus: .expanded)

        XCTAssertEqual(hint, "Shows more content. Double tap to collapse.")
    }

    func testCollapsedHintConcatenatesWithHintMissingTrailingPeriod() {
        let view = UIView()
        view.isAccessibilityElement = true
        view.accessibilityLabel = "Section"
        view.accessibilityHint = "Shows more content"

        let (_, hint) = view.accessibilityDescription(context: nil, expandedStatus: .collapsed)

        XCTAssertEqual(hint, "Shows more content. Double tap to expand.")
    }

    func testDefaultExpandedStatusParameterIsUnsupported() {
        let view = UIView()
        view.isAccessibilityElement = true
        view.accessibilityLabel = "Section"

        let (description, hint) = view.accessibilityDescription(context: nil)

        XCTAssertEqual(description, "Section")
        XCTAssertNil(hint)
    }
}

@testable import AccessibilitySnapshotParser
import UIKit
import XCTest

final class ExpandedStatusDescriptionTests: XCTestCase {
    func testExpandedAppendsToDescription() {
        let view = makeView(expandedStatus: .expanded)

        let (description, hint) = view.accessibilityDescription(context: nil)

        XCTAssertEqual(description, "Section. Expanded.")
        XCTAssertEqual(hint, "Double tap to collapse.")
    }

    func testCollapsedAppendsToDescription() {
        let view = makeView(expandedStatus: .collapsed)

        let (description, hint) = view.accessibilityDescription(context: nil)

        XCTAssertEqual(description, "Section. Collapsed.")
        XCTAssertEqual(hint, "Double tap to expand.")
    }

    func testUnsupportedLeavesDescriptionAndHintAlone() {
        let view = makeView(expandedStatus: .unsupported)

        let (description, hint) = view.accessibilityDescription(context: nil)

        XCTAssertEqual(description, "Section")
        XCTAssertNil(hint)
    }

    func testExpandedHintConcatenatesWithExistingHint() {
        let view = makeView(expandedStatus: .expanded)
        view.accessibilityHint = "Shows more content."

        let (_, hint) = view.accessibilityDescription(context: nil)

        XCTAssertEqual(hint, "Shows more content. Double tap to collapse.")
    }

    func testCollapsedHintConcatenatesWithHintMissingTrailingPeriod() {
        let view = makeView(expandedStatus: .collapsed)
        view.accessibilityHint = "Shows more content"

        let (_, hint) = view.accessibilityDescription(context: nil)

        XCTAssertEqual(hint, "Shows more content. Double tap to expand.")
    }

    func testDisabledExpandedElementDoesNotAddActionHint() {
        let view = makeView(expandedStatus: .expanded)
        view.accessibilityTraits = [.notEnabled]

        let (description, hint) = view.accessibilityDescription(context: nil)

        XCTAssertEqual(description, "Section. Dimmed. Expanded.")
        XCTAssertNil(hint)
    }

    func testDisabledCollapsedElementPreservesExistingHintWithoutAddingActionHint() {
        let view = makeView(expandedStatus: .collapsed)
        view.accessibilityHint = "Read only"
        view.accessibilityTraits = [.notEnabled]

        let (description, hint) = view.accessibilityDescription(context: nil)

        XCTAssertEqual(description, "Section. Dimmed. Collapsed.")
        XCTAssertEqual(hint, "Read only")
    }

    func testMissingExpandedStatusIsUnsupported() {
        let view = makeView()

        let (description, hint) = view.accessibilityDescription(context: nil)

        XCTAssertEqual(description, "Section")
        XCTAssertNil(hint)
    }

    private func makeView(expandedStatus: AccessibilityElement.ExpandedStatus? = nil) -> UIView {
        let view: UIView
        if let expandedStatus {
            view = ExpandedStatusView(expandedStatus: expandedStatus)
        } else {
            view = UIView()
        }
        view.isAccessibilityElement = true
        view.accessibilityLabel = "Section"
        return view
    }
}

private final class ExpandedStatusView: UIView {
    private let storedExpandedStatus: AccessibilityElement.ExpandedStatus

    init(expandedStatus: AccessibilityElement.ExpandedStatus) {
        storedExpandedStatus = expandedStatus
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not implemented")
    }

    @objc(_accessibilityExpandedStatus)
    func accessibilitySnapshot_expandedStatus() -> Int {
        return storedExpandedStatus.rawValue
    }
}

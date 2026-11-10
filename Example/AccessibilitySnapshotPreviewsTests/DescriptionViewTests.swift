import AccessibilitySnapshotCore
@testable import AccessibilitySnapshotPreviews
import UIKit
import XCTest

@available(iOS 16.0, *)
final class DescriptionViewTests: XCTestCase {
    @MainActor
    func testLongDescriptionWrapsInRenderedLegend() throws {
        let singleLineHeight = try renderedHeight(
            accessibilityValue: "California: 132 days"
        )
        let multilineHeight = try renderedHeight(
            accessibilityValue: "California: 132 days, New York: 41 days, Canada: 9 days, and European Union: 4 days"
        )

        XCTAssertGreaterThan(multilineHeight, singleLineHeight)
    }

    @MainActor
    private func renderedHeight(accessibilityValue: String) throws -> CGFloat {
        let renderSize = CGSize(width: 402, height: 158)
        let content = UIView(frame: CGRect(origin: .zero, size: renderSize))
        content.backgroundColor = .white
        content.isAccessibilityElement = true
        content.accessibilityLabel = "Days in 2026"
        content.accessibilityValue = accessibilityValue

        let container = SwiftUIAccessibilitySnapshotContainerView(
            containedView: content,
            snapshotConfiguration: AccessibilitySnapshotConfiguration(
                viewRenderingMode: .drawHierarchyInRect
            )
        )
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.makeKeyAndVisible()
        container.center = window.center
        window.addSubview(container)
        defer { window.isHidden = true }

        try container.parseAccessibility()
        container.sizeToFit()

        return container.bounds.height
    }
}

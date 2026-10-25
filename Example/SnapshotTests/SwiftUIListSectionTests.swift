import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import FBSnapshotTestCase_Accessibility
import iOSSnapshotTestCase
import SwiftUI
import XCTest

@testable import AccessibilitySnapshotDemo

/// Snapshot tests for SwiftUI List with Section headers and footers.
/// These tests verify that section headers/footers are interleaved correctly
/// with their row content, matching VoiceOver's traversal order.
///
/// To validate against VoiceOver: run the corresponding SwiftUI views on a
/// device with VoiceOver enabled and swipe through elements. The snapshot
/// element order should match the VoiceOver reading order.
final class SwiftUIListSectionTests: SnapshotTestCase {
    /// iOS 17 SwiftUI List snapshots alternate between two CI renderings while
    /// preserving the same section ordering. Later runtimes are pixel-stable.
    private var iOS17ListOverallTolerance: CGFloat {
        if #available(iOS 18.0, *) {
            return 0
        }
        return 0.10
    }

    @available(iOS 15.0, *)
    func testListWithSectionHeadersReadingOrder() throws {
        try assertReadingOrder(
            of: SwiftUIListWithSections(),
            equals: ["Fruits", "Apple", "Banana", "Cherry", "Vegetables", "Carrot", "Peas"]
        )
    }

    @available(iOS 15.0, *)
    func testListWithHeadersAndFootersReadingOrder() throws {
        try assertReadingOrder(
            of: SwiftUIListWithHeadersAndFooters(),
            equals: ["Accounts", "Checking", "Savings", "Tap an account to view details", "Bills", "Electric", "Internet", "Due this month"]
        )
    }

    private func assertReadingOrder<Content: View>(of content: Content, equals expected: [String], file: StaticString = #filePath, line: UInt = #line) throws {
        let host = UIHostingController(rootView: content)
        let root = try XCTUnwrap(host.view, file: file, line: line)
        root.bounds.size = UIScreen.main.bounds.size
        let snapshot = ListReadingOrderSnapshotView(
            containedView: root,
            snapshotConfiguration: .init(viewRenderingMode: .drawHierarchyInRect)
        )
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.makeKeyAndVisible()
        snapshot.center = window.center
        window.addSubview(snapshot)
        defer {
            window.resignKey()
            window.isHidden = true
        }
        try snapshot.parseAccessibility()
        let markers = try XCTUnwrap(snapshot.markers, file: file, line: line)
        XCTAssertEqual(markers.compactMap { $0.label?.lowercased() }, expected.map { $0.lowercased() }, file: file, line: line)
    }

    @available(iOS 15.0, *)
    func testListWithSectionHeaders() {
        SnapshotVerifyAccessibility(
            SwiftUIListWithSections(),
            size: UIScreen.main.bounds.size,
            overallTolerance: iOS17ListOverallTolerance
        )
    }

    @available(iOS 15.0, *)
    func testListWithHeadersAndFooters() {
        SnapshotVerifyAccessibility(
            SwiftUIListWithHeadersAndFooters(),
            size: UIScreen.main.bounds.size,
            overallTolerance: iOS17ListOverallTolerance
        )
    }
}

private final class ListReadingOrderSnapshotView: AccessibilitySnapshotBaseView {
    var markers: [AccessibilityMarker]?

    override func render(data: ParsedAccessibilityData) {
        markers = data.markers
    }
}

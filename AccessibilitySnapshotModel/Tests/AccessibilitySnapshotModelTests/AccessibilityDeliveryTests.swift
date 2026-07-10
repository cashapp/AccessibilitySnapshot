import AccessibilitySnapshotModel
import Foundation
import XCTest

/// Coverage for the delivery transform (trim + off-screen classification) and the
/// `AccessibilityShape.boundingRect` helper it relies on. Model-only; no UIKit.
final class AccessibilityDeliveryTests: XCTestCase {
    // MARK: - Helpers

    private func element(
        _ description: String,
        visibility: AccessibilityVisibility,
        shape: AccessibilityShape = .frame(.zero)
    ) -> AccessibilityElement {
        AccessibilityElement(
            description: description, label: description, value: nil, traits: [],
            identifier: nil, hint: nil, userInputLabels: nil,
            shape: shape, activationPoint: .zero, usesDefaultActivationPoint: true,
            customActions: [], customContent: [], customRotors: [],
            accessibilityLanguage: nil, respondsToUserInteraction: false,
            visibility: visibility
        )
    }

    private func scrollable(_ frame: AccessibilityRect, children: [AccessibilityHierarchy]) -> AccessibilityHierarchy {
        .container(
            AccessibilityContainer(type: .scrollable(contentSize: AccessibilitySize(width: frame.width, height: frame.height * 3)), frame: frame),
            children: children
        )
    }

    // MARK: - Untrimmed equivalence

    func testFullTreeFlattenIncludesOffscreen() {
        let hierarchy: [AccessibilityHierarchy] = [
            .element(element("A", visibility: .onscreen), traversalIndex: 0),
            .element(element("B", visibility: .offscreen), traversalIndex: 1),
        ]
        // The unfiltered tree flattens to every element; nothing is summarized.
        XCTAssertEqual(hierarchy.flattenToElements().map { $0.label }, ["A", "B"])
    }

    // MARK: - Trimming

    func testOnscreenDropsOffscreenElements() {
        let hierarchy: [AccessibilityHierarchy] = [
            .element(element("A", visibility: .onscreen), traversalIndex: 0),
            .element(element("B", visibility: .offscreen), traversalIndex: 1),
            .element(element("C", visibility: .onscreen), traversalIndex: 2),
        ]
        XCTAssertEqual(hierarchy.onscreen().flattenToElements().map { $0.label }, ["A", "C"])
    }

    // MARK: - Empty-container pruning

    func testOnscreenDropsContainerWhoseChildrenAllWentOffscreen() {
        // A container with no surviving on-screen children is not an accessibility element and must
        // not remain in the on-screen tree.
        let group = AccessibilityHierarchy.container(
            AccessibilityContainer(type: .list, frame: AccessibilityRect(x: 0, y: 0, width: 100, height: 100)),
            children: [
                .element(element("hidden1", visibility: .offscreen), traversalIndex: 0),
                .element(element("hidden2", visibility: .offscreen), traversalIndex: 1),
            ]
        )
        let hierarchy: [AccessibilityHierarchy] = [
            .element(element("A", visibility: .onscreen), traversalIndex: 0),
            group,
        ]
        let onscreen = hierarchy.onscreen()
        // The emptied list container is gone entirely, leaving only the top-level on-screen element.
        XCTAssertEqual(onscreen.count, 1)
        XCTAssertEqual(onscreen.flattenToElements().map { $0.label }, ["A"])
    }

    func testOnscreenKeepsContainerWithAtLeastOneOnscreenChild() {
        let group = AccessibilityHierarchy.container(
            AccessibilityContainer(type: .list, frame: AccessibilityRect(x: 0, y: 0, width: 100, height: 100)),
            children: [
                .element(element("kept", visibility: .onscreen), traversalIndex: 0),
                .element(element("dropped", visibility: .offscreen), traversalIndex: 1),
            ]
        )
        let onscreen = [group].onscreen()
        XCTAssertEqual(onscreen.count, 1)
        XCTAssertEqual(onscreen.flattenToElements().map { $0.label }, ["kept"])
    }

    // MARK: - Framed classification (above / below the viewport)

    func testFramedElementsClassifyAboveAndBelow() {
        let viewport = AccessibilityRect(x: 0, y: 100, width: 100, height: 100) // visible y: 100...200
        let hierarchy = [scrollable(viewport, children: [
            .element(element("above", visibility: .offscreen, shape: .frame(AccessibilityRect(x: 0, y: 0, width: 100, height: 40))), traversalIndex: 0),
            .element(element("visible", visibility: .onscreen, shape: .frame(AccessibilityRect(x: 0, y: 120, width: 100, height: 40))), traversalIndex: 1),
            .element(element("below", visibility: .offscreen, shape: .frame(AccessibilityRect(x: 0, y: 300, width: 100, height: 40))), traversalIndex: 2),
        ])]
        let summary = hierarchy.scrollContainerSummaries().first
        XCTAssertEqual(summary?.trimmedAbove, 1)
        XCTAssertEqual(summary?.trimmedBelow, 1)
        XCTAssertEqual(summary?.trimmedElsewhere, 0)
    }

    // MARK: - Zero-frame classification (enumeration order fallback)

    func testZeroFrameElementsClassifyByEnumerationOrder() {
        let viewport = AccessibilityRect(x: 0, y: 0, width: 100, height: 100)
        let hierarchy = [scrollable(viewport, children: [
            .element(element("before", visibility: .offscreen), traversalIndex: 0), // zero frame
            .element(element("visible", visibility: .onscreen, shape: .frame(AccessibilityRect(x: 0, y: 10, width: 100, height: 40))), traversalIndex: 1),
            .element(element("after1", visibility: .offscreen), traversalIndex: 2),
            .element(element("after2", visibility: .offscreen), traversalIndex: 3),
        ])]
        let summary = hierarchy.scrollContainerSummaries().first
        XCTAssertEqual(summary?.trimmedAbove, 1)
        XCTAssertEqual(summary?.trimmedBelow, 2)
    }

    // MARK: - No scrollable ancestor → trimmed but uncounted

    func testOffscreenWithoutScrollableAncestorIsTrimmedButUncounted() {
        let hierarchy: [AccessibilityHierarchy] = [
            .element(element("A", visibility: .onscreen), traversalIndex: 0),
            .element(element("B", visibility: .offscreen), traversalIndex: 1),
        ]
        XCTAssertEqual(hierarchy.onscreen().flattenToElements().map { $0.label }, ["A"])
        XCTAssertTrue(hierarchy.scrollContainerSummaries().isEmpty)
    }

    // MARK: - Nested scrollables attribute to nearest

    func testNestedScrollablesEachOwnTheirTrimmedChildren() {
        let outerViewport = AccessibilityRect(x: 0, y: 0, width: 100, height: 400)
        let innerViewport = AccessibilityRect(x: 0, y: 0, width: 100, height: 100)
        let inner = scrollable(innerViewport, children: [
            .element(element("inner-off", visibility: .offscreen, shape: .frame(AccessibilityRect(x: 0, y: 300, width: 100, height: 40))), traversalIndex: 1),
        ])
        let hierarchy = [scrollable(outerViewport, children: [
            .element(element("outer-off", visibility: .offscreen, shape: .frame(AccessibilityRect(x: 0, y: 900, width: 100, height: 40))), traversalIndex: 0),
            inner,
        ])]
        let summaries = hierarchy.scrollContainerSummaries()
        XCTAssertEqual(summaries.count, 2)
        // The outer container's own tally must not absorb the inner container's trimmed child.
        let outer = summaries.first { $0.container.frame == outerViewport }
        XCTAssertEqual(outer?.trimmedBelow, 1)
    }

    // MARK: - boundingRect

    func testBoundingRectOfFrameIsFrame() {
        let rect = AccessibilityRect(x: 5, y: 6, width: 7, height: 8)
        XCTAssertEqual(AccessibilityShape.frame(rect).boundingRect, rect)
    }

    func testBoundingRectOfPathEnclosesAllPoints() {
        let shape = AccessibilityShape.path([
            .move(to: AccessibilityPoint(x: 10, y: 10)),
            .line(to: AccessibilityPoint(x: 30, y: 5)),
            .curve(to: AccessibilityPoint(x: 20, y: 40), control1: AccessibilityPoint(x: 0, y: 0), control2: AccessibilityPoint(x: 50, y: 20)),
            .closeSubpath,
        ])
        XCTAssertEqual(shape.boundingRect, AccessibilityRect(x: 0, y: 0, width: 50, height: 40))
    }

    func testBoundingRectOfEmptyPathIsZero() {
        XCTAssertEqual(AccessibilityShape.path([]).boundingRect, .zero)
    }
}

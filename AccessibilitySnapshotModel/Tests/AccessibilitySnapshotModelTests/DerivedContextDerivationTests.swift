import AccessibilitySnapshotModel
import Foundation
import XCTest

/// Coverage for `AccessibilityContainer.derivedContext(forChildAt:in:)` — the pure, UIKit-free
/// derivation of container context from graph position (the model-side mirror of the parser's live
/// `derivedContext`). Series/tab position is the child's ordinal + sibling count; data-table headers
/// resolve from the stored `cells` payload.
final class DerivedContextDerivationTests: XCTestCase {
    // MARK: - Helpers

    private func element(label: String? = nil, value: String? = nil) -> AccessibilityElement {
        AccessibilityElement(
            description: label ?? "", label: label, value: value, traits: [],
            identifier: nil, hint: nil, userInputLabels: nil,
            shape: .frame(.zero), activationPoint: .zero, usesDefaultActivationPoint: true,
            customActions: [], customContent: [], customRotors: [],
            accessibilityLanguage: nil, respondsToUserInteraction: false
        )
    }

    private func children(_ labels: String?...) -> [AccessibilityHierarchy] {
        labels.enumerated().map { .element(element(label: $0.element), traversalIndex: $0.offset) }
    }

    private func container(_ type: AccessibilityContainer.ContainerType) -> AccessibilityContainer {
        AccessibilityContainer(type: type, frame: .init(x: 0, y: 0, width: 1, height: 1))
    }

    // MARK: - Series

    func testSeriesDerivesOrdinalAndCount() {
        let c = container(.series)
        let kids = children("A", "B", "C")
        XCTAssertEqual(c.derivedContext(forChildAt: 0, in: kids), .series(index: 1, count: 3))
        XCTAssertEqual(c.derivedContext(forChildAt: 2, in: kids), .series(index: 3, count: 3))
    }

    // MARK: - Tab bar

    func testTabBarDerivesTab() {
        let c = container(.tabBar)
        let kids = children("Home", "Search", "Profile", "More")
        XCTAssertEqual(c.derivedContext(forChildAt: 1, in: kids), .tab(index: 2, count: 4))
    }

    // MARK: - List

    func testListStartAndEnd() {
        let c = container(.list)
        let kids = children("first", "middle", "last")
        XCTAssertEqual(c.derivedContext(forChildAt: 0, in: kids), .listStart)
        XCTAssertNil(c.derivedContext(forChildAt: 1, in: kids))
        XCTAssertEqual(c.derivedContext(forChildAt: 2, in: kids), .listEnd)
    }

    func testSoleListChildGetsOnlyStart() {
        // A single-child list gets listStart and never listEnd (mirrors the parser).
        let c = container(.list)
        let kids = children("only")
        XCTAssertEqual(c.derivedContext(forChildAt: 0, in: kids), .listStart)
    }

    // MARK: - Landmark

    func testLandmarkStartAndEnd() {
        let c = container(.landmark)
        let kids = children("a", "b", "c")
        XCTAssertEqual(c.derivedContext(forChildAt: 0, in: kids), .landmarkStart)
        XCTAssertEqual(c.derivedContext(forChildAt: 2, in: kids), .landmarkEnd)
    }

    // MARK: - Data table (header resolution)

    func testDataTableCellResolvesHeadersFromChildIndices() {
        // children: [0]=col header "Name", [1]=row header "Row1", [2]=the cell.
        let kids = children("Name", "Row1", "Bailey")
        let cell = AccessibilityContainer.DataTableCellInfo(
            row: 0, column: 1, rowSpan: 1, columnSpan: 1, isFirstInRow: true,
            rowHeaderChildIndices: [1], columnHeaderChildIndices: [0]
        )
        let c = container(.dataTable(rowCount: 1, columnCount: 2, cells: [nil, nil, cell]))

        guard case let .dataTableCell(row, column, width, height, isFirstInRow, rowHeaders, columnHeaders)? =
            c.derivedContext(forChildAt: 2, in: kids)
        else {
            return XCTFail("expected dataTableCell context")
        }
        XCTAssertEqual(row, 0)
        XCTAssertEqual(column, 1)
        XCTAssertEqual(width, 1)
        XCTAssertEqual(height, 1)
        XCTAssertTrue(isFirstInRow)
        XCTAssertEqual(rowHeaders, [.init(label: "Row1", value: nil)])
        XCTAssertEqual(columnHeaders, [.init(label: "Name", value: nil)])
    }

    func testDataTableNonCellChildYieldsNil() {
        let kids = children("header", "cell")
        let c = container(.dataTable(rowCount: 1, columnCount: 1, cells: [nil, nil]))
        XCTAssertNil(c.derivedContext(forChildAt: 0, in: kids))
    }

    // MARK: - No-context containers

    func testContextlessContainersReturnNil() {
        let kids = children("x", "y")
        for type in [
            AccessibilityContainer.ContainerType.semanticGroup(label: nil, value: nil),
            .none,
            .scrollable(contentSize: .init(width: 1, height: 1)),
        ] {
            XCTAssertNil(container(type).derivedContext(forChildAt: 0, in: kids), "\(type) should lend no context")
        }
    }

    // MARK: - Out of range

    func testOutOfRangeChildIndexReturnsNil() {
        let c = container(.series)
        let kids = children("A", "B")
        XCTAssertNil(c.derivedContext(forChildAt: -1, in: kids))
        XCTAssertNil(c.derivedContext(forChildAt: 2, in: kids))
    }
}

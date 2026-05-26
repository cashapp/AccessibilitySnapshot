@testable import AccessibilitySnapshotCore
@testable import AccessibilitySnapshotParser
@testable import AccessibilitySnapshotPreviews
import UIKit
import XCTest

/// Verifies the contract that legend colors match overlay colors:
/// an element's `colorIndex` in `HierarchyColorAssignment` equals its position in
/// `hierarchy.flattenToElements()`. Without this invariant, the hierarchical legend
/// would show different colored badges than the overlays drawn on the snapshot.
@available(iOS 16.0, *)
final class HierarchyColorAssignmentTests: XCTestCase {
    func testElementColorIndexMatchesFlattenedPosition() {
        // Hierarchy: traversalIndex is intentionally out of declaration order to verify
        // that color assignment uses sorted traversal order — same ordering as
        // flattenToElements().
        let elementA = makeElement(label: "A")
        let elementB = makeElement(label: "B")
        let elementC = makeElement(label: "C")
        let elementD = makeElement(label: "D")

        let hierarchy: [AccessibilityHierarchy] = [
            .container(
                makeContainer(.list),
                children: [
                    .element(elementC, traversalIndex: 2),
                    .element(elementA, traversalIndex: 0),
                ]
            ),
            .element(elementD, traversalIndex: 3),
            .element(elementB, traversalIndex: 1),
        ]

        let assignment = HierarchyColorAssignment.build(from: hierarchy)
        let expected = hierarchy.flattenToElements()

        // Walk assignment, collect (label, colorIndex) pairs in traversal order.
        var pairs: [(label: String, colorIndex: Int)] = []
        collect(nodes: assignment.nodes, into: &pairs)
        pairs.sort { $0.colorIndex < $1.colorIndex }

        XCTAssertEqual(pairs.map(\.label), expected.map(\.label),
                       "Element labels in colorIndex order must match flattenToElements() order")
        XCTAssertEqual(pairs.map(\.colorIndex), Array(0 ..< expected.count),
                       "Color indices must be contiguous 0..<count, matching marker overlay indices")
    }

    func testContainerColorIndicesAreSequentialAndIndependentOfElements() {
        // Containers get their own counter starting at 0, independent of element indices,
        // so they cycle through the palette separately.
        let elementA = makeElement(label: "A")
        let elementB = makeElement(label: "B")

        let hierarchy: [AccessibilityHierarchy] = [
            .container(
                makeContainer(.list),
                children: [.element(elementA, traversalIndex: 0)]
            ),
            .container(
                makeContainer(.landmark),
                children: [.element(elementB, traversalIndex: 1)]
            ),
        ]

        let assignment = HierarchyColorAssignment.build(from: hierarchy)

        var containerIndices: [Int] = []
        collectContainerIndices(nodes: assignment.nodes, into: &containerIndices)

        XCTAssertEqual(containerIndices, [0, 1],
                       "Container colorIndices should start at 0 and increment sequentially")
    }

    func testEmptyHierarchyProducesEmptyAssignment() {
        let assignment = HierarchyColorAssignment.build(from: [])
        XCTAssertTrue(assignment.nodes.isEmpty)
    }

    // MARK: - Helpers

    private func collect(
        nodes: [HierarchyColorAssignment.AssignedNode],
        into pairs: inout [(label: String, colorIndex: Int)]
    ) {
        for node in nodes {
            switch node {
            case let .element(element, colorIndex):
                pairs.append((element.label ?? "", colorIndex))
            case let .container(_, _, children):
                collect(nodes: children, into: &pairs)
            }
        }
    }

    private func collectContainerIndices(
        nodes: [HierarchyColorAssignment.AssignedNode],
        into indices: inout [Int]
    ) {
        for node in nodes {
            if case let .container(_, colorIndex, children) = node {
                indices.append(colorIndex)
                collectContainerIndices(nodes: children, into: &indices)
            }
        }
    }

    private func makeElement(label: String) -> AccessibilityElement {
        AccessibilityElement(
            description: label,
            label: label,
            value: nil,
            traits: [],
            identifier: nil,
            hint: nil,
            userInputLabels: nil,
            shape: .frame(.zero),
            activationPoint: .zero,
            usesDefaultActivationPoint: true,
            customActions: [],
            customContent: [],
            customRotors: [],
            accessibilityLanguage: nil,
            respondsToUserInteraction: false
        )
    }

    private func makeContainer(_ type: AccessibilityContainer.ContainerType) -> AccessibilityContainer {
        AccessibilityContainer(type: type, frame: .zero)
    }
}

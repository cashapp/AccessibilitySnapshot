import AccessibilitySnapshotCore
import AccessibilitySnapshotParser

/// Assigns color indices to containers and elements in the hierarchy.
///
/// Elements use their position in the sorted traversal order (matching the `markers` array
/// and overlay indices). Containers use a separate sequential counter starting at 0, so
/// elements and containers cycle through palette colors independently.
@available(iOS 16.0, *)
public struct HierarchyColorAssignment {
    /// A node with its assigned color index.
    public enum AssignedNode {
        case element(AccessibilityElement, colorIndex: Int)
        case container(AccessibilityContainer, colorIndex: Int, children: [AssignedNode])
    }

    /// The assigned nodes in hierarchy order.
    public let nodes: [AssignedNode]

    /// Builds color assignments from a hierarchy tree.
    public static func build(from hierarchy: [AccessibilityHierarchy]) -> HierarchyColorAssignment {
        var containerCounter = 0

        // Map each element's traversal index to its position in the sorted
        // markers array. This ensures legend colors match overlay colors.
        var traversalIndexToPosition: [Int: Int] = [:]
        var allTraversalIndices: [Int] = []
        func collectTraversalIndices(_ nodes: [AccessibilityHierarchy]) {
            for node in nodes {
                switch node {
                case let .element(_, traversalIndex):
                    allTraversalIndices.append(traversalIndex)
                case let .container(_, children):
                    collectTraversalIndices(children)
                }
            }
        }
        collectTraversalIndices(hierarchy)
        for (position, traversalIndex) in allTraversalIndices.sorted().enumerated() {
            traversalIndexToPosition[traversalIndex] = position
        }

        func assign(_ nodes: [AccessibilityHierarchy]) -> [AssignedNode] {
            nodes.map { node in
                switch node {
                case let .container(container, children):
                    let index = containerCounter
                    containerCounter += 1
                    let assignedChildren = assign(children)
                    return .container(container, colorIndex: index, children: assignedChildren)

                case let .element(element, traversalIndex):
                    let index = traversalIndexToPosition[traversalIndex] ?? 0
                    return .element(element, colorIndex: index)
                }
            }
        }

        let assignedNodes = assign(hierarchy)
        return HierarchyColorAssignment(nodes: assignedNodes)
    }
}

import AccessibilitySnapshotCore
import AccessibilitySnapshotParser

/// Assigns sequential color indices to containers and elements as they appear in hierarchy traversal order.
/// This ensures containers and elements share the same color palette without overlapping.
@available(iOS 16.0, *)
public struct HierarchyColorAssignment {
    /// A node with its assigned color index.
    public enum AssignedNode {
        case element(AccessibilityElement, colorIndex: Int)
        case container(AccessibilityContainer, colorIndex: Int, children: [AssignedNode])
    }

    /// The assigned nodes in hierarchy order.
    public let nodes: [AssignedNode]

    /// All containers with their color indices, in depth-first order.
    public let containers: [(container: AccessibilityContainer, colorIndex: Int)]

    /// All elements with their color indices, in traversal order.
    public let elements: [(element: AccessibilityElement, colorIndex: Int)]

    /// Builds color assignments from a hierarchy tree.
    /// Walks depth-first, assigning each container and element the next sequential color index.
    public static func build(from hierarchy: [AccessibilityHierarchy]) -> HierarchyColorAssignment {
        var colorCounter = 0
        var allContainers: [(container: AccessibilityContainer, colorIndex: Int)] = []
        var allElements: [(element: AccessibilityElement, colorIndex: Int)] = []

        func assign(_ nodes: [AccessibilityHierarchy]) -> [AssignedNode] {
            nodes.map { node in
                switch node {
                case let .container(container, children):
                    let index = colorCounter
                    colorCounter += 1
                    allContainers.append((container, index))
                    let assignedChildren = assign(children)
                    return .container(container, colorIndex: index, children: assignedChildren)

                case let .element(element, _):
                    let index = colorCounter
                    colorCounter += 1
                    allElements.append((element, index))
                    return .element(element, colorIndex: index)
                }
            }
        }

        let assignedNodes = assign(hierarchy)
        return HierarchyColorAssignment(
            nodes: assignedNodes,
            containers: allContainers,
            elements: allElements
        )
    }
}

import AccessibilitySnapshotCore
import AccessibilitySnapshotParser

/// Assigns color indices to containers and elements in the hierarchy.
///
/// Elements use their flat traversal index (matching the `markers` array), so element
/// overlays render identically whether or not container mode is enabled.
/// Containers get a separate sequential index starting after all elements.
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
        var elementCounter = 0
        var containerCounter = 0

        let totalElements = hierarchy.flattenToElements().count

        func assign(_ nodes: [AccessibilityHierarchy]) -> [AssignedNode] {
            nodes.map { node in
                switch node {
                case let .container(container, children):
                    let index = totalElements + containerCounter
                    containerCounter += 1
                    let assignedChildren = assign(children)
                    return .container(container, colorIndex: index, children: assignedChildren)

                case let .element(element, _):
                    let index = elementCounter
                    elementCounter += 1
                    return .element(element, colorIndex: index)
                }
            }
        }

        let assignedNodes = assign(hierarchy)
        return HierarchyColorAssignment(nodes: assignedNodes)
    }
}

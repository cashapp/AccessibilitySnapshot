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

    /// All containers with their color indices, in depth-first order.
    public let containers: [(container: AccessibilityContainer, colorIndex: Int)]

    /// Builds color assignments from a hierarchy tree.
    ///
    /// Elements are assigned their flat traversal index (0, 1, 2, ...) so they match
    /// the `markers` array used by the non-container overlay path.
    /// Containers are assigned indices starting after the last element index, so they
    /// get distinct colors from the same palette.
    public static func build(from hierarchy: [AccessibilityHierarchy]) -> HierarchyColorAssignment {
        var elementCounter = 0
        var containerCounter = 0
        var allContainers: [(container: AccessibilityContainer, colorIndex: Int)] = []

        // First pass: count elements so we know where container indices start
        let totalElements = hierarchy.flattenToElements().count

        func assign(_ nodes: [AccessibilityHierarchy]) -> [AssignedNode] {
            nodes.map { node in
                switch node {
                case let .container(container, children):
                    let index = totalElements + containerCounter
                    containerCounter += 1
                    allContainers.append((container, index))
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
        return HierarchyColorAssignment(
            nodes: assignedNodes,
            containers: allContainers
        )
    }
}

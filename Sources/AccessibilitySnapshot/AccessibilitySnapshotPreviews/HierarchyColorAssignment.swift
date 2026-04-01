import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import CoreGraphics

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

    /// A container with its color index and computed bounds (union of child element frames).
    public struct ContainerEntry {
        public let container: AccessibilityContainer
        public let colorIndex: Int
        /// Bounding rect computed from child element frames, not the container UIView's frame.
        public let bounds: CGRect
    }

    /// The assigned nodes in hierarchy order.
    public let nodes: [AssignedNode]

    /// All containers with their color indices and computed bounds, in depth-first order.
    public let containers: [ContainerEntry]

    /// Builds color assignments from a hierarchy tree.
    public static func build(from hierarchy: [AccessibilityHierarchy]) -> HierarchyColorAssignment {
        var elementCounter = 0
        var containerCounter = 0
        var allContainers: [ContainerEntry] = []

        let totalElements = hierarchy.flattenToElements().count

        func assign(_ nodes: [AccessibilityHierarchy]) -> [AssignedNode] {
            nodes.map { node in
                switch node {
                case let .container(container, children):
                    let index = totalElements + containerCounter
                    containerCounter += 1
                    let assignedChildren = assign(children)
                    let bounds = computeBounds(of: assignedChildren)
                    allContainers.append(ContainerEntry(
                        container: container,
                        colorIndex: index,
                        bounds: bounds
                    ))
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

    /// Computes the bounding rect that encloses all descendant element frames.
    private static func computeBounds(of nodes: [AssignedNode]) -> CGRect {
        var rects: [CGRect] = []
        collectElementFrames(from: nodes, into: &rects)
        guard let first = rects.first else { return .zero }
        return rects.dropFirst().reduce(first) { $0.union($1) }
    }

    private static func collectElementFrames(from nodes: [AssignedNode], into rects: inout [CGRect]) {
        for node in nodes {
            switch node {
            case let .element(element, _):
                switch element.shape {
                case let .frame(rect):
                    rects.append(rect)
                case let .path(path):
                    rects.append(path.bounds)
                }
            case let .container(_, _, children):
                collectElementFrames(from: children, into: &rects)
            }
        }
    }
}

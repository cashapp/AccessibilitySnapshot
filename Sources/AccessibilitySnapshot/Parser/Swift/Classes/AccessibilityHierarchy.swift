// MARK: - Hierarchy Node

/// A node in the accessibility hierarchy tree
public enum AccessibilityHierarchy: Equatable, Codable {
    /// A leaf node representing an accessibility element
    /// - Parameters:
    ///   - AccessibilityElement: The accessibility element data
    ///   - traversalIndex: Position in VoiceOver traversal order
    case element(AccessibilityElement, traversalIndex: Int)

    /// A container node that groups child elements
    /// - Parameters:
    ///   - AccessibilityContainer: Container metadata (type, label, value, identifier, frame)
    ///   - children: Child nodes within this container
    case container(AccessibilityContainer, children: [AccessibilityHierarchy])

    /// Child nodes (empty for leaf elements, contains children for containers)
    public var children: [AccessibilityHierarchy] {
        switch self {
        case .element:
            return []
        case let .container(_, children):
            return children
        }
    }

    /// Sort index for ordering in legend display.
    /// For elements: returns the traversal index.
    /// For containers: returns the minimum sort index of its children (recursively).
    public var sortIndex: Int {
        reduced(Int.max) { accumulator, node in
            guard case let .element(_, index) = node else { return accumulator }
            return min(accumulator, index)
        }
    }
}

// MARK: - Hierarchy Utilities

public extension AccessibilityHierarchy {
    /// Recursively visits each node in the hierarchy tree
    func forEach(_ apply: (AccessibilityHierarchy) -> Void) {
        reduced(()) { _, node in apply(node) }
    }
}

public extension Array where Element == AccessibilityHierarchy {
    /// Flattens an array of hierarchy nodes into a single array of elements in VoiceOver traversal order
    func flattenToElements() -> [AccessibilityElement] {
        reducedHierarchy([(index: Int, element: AccessibilityElement)]()) { accumulator, node in
            guard case let .element(element, index) = node else { return accumulator }
            return accumulator + [(index, element)]
        }
        .sorted { $0.index < $1.index }
        .map { $0.element }
    }

    /// Flattens an array of hierarchy nodes into a single array of containers in depth-first order
    func flattenToContainers() -> [AccessibilityContainer] {
        reducedHierarchy([]) { accumulator, node in
            guard case let .container(container, _) = node else { return accumulator }
            return accumulator + [container]
        }
    }
}

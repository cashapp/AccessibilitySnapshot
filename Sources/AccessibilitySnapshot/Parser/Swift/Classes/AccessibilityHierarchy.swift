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
        switch self {
        case let .element(_, index):
            return index
        case let .container(_, children):
            // Return minimum sort index of children, or Int.max if no children
            return children.map { $0.sortIndex }.min() ?? Int.max
        }
    }
}

// MARK: - Hierarchy Utilities

public extension AccessibilityHierarchy {
    /// Recursively visits each node in the hierarchy tree
    func forEach(_ apply: (AccessibilityHierarchy) -> Void) {
        apply(self)
        for child in children {
            child.forEach(apply)
        }
    }
}

public extension Array where Element == AccessibilityHierarchy {
    /// Flattens an array of hierarchy nodes into a single array of elements in VoiceOver traversal order
    func flattenToElements() -> [AccessibilityElement] {
        var elementPairs: [(index: Int, element: AccessibilityElement)] = []

        func collectElements(from node: AccessibilityHierarchy) {
            switch node {
            case let .element(element, index):
                elementPairs.append((index, element))
            case let .container(_, children):
                for child in children {
                    collectElements(from: child)
                }
            }
        }

        for node in self {
            collectElements(from: node)
        }

        return elementPairs
            .sorted { $0.index < $1.index }
            .map { $0.element }
    }

    /// Flattens an array of hierarchy nodes into a single array of containers in depth-first order
    func flattenToContainers() -> [AccessibilityContainer] {
        var containers: [AccessibilityContainer] = []

        func collectContainers(from node: AccessibilityHierarchy) {
            switch node {
            case .element:
                break
            case let .container(container, children):
                containers.append(container)
                for child in children {
                    collectContainers(from: child)
                }
            }
        }

        for node in self {
            collectContainers(from: node)
        }

        return containers
    }
}

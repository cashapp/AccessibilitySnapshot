public enum AccessibilityHierarchy: Hashable, Codable, Sendable {
    case element(AccessibilityElement, traversalIndex: Int)
    case container(AccessibilityContainer, children: [AccessibilityHierarchy])

    public var children: [AccessibilityHierarchy] {
        switch self {
        case .element:
            return []
        case let .container(_, children):
            return children
        }
    }

    public var sortIndex: Int {
        switch self {
        case let .element(_, index):
            return index
        case let .container(_, children):
            return children.map { $0.sortIndex }.min() ?? Int.max
        }
    }
}

public extension AccessibilityHierarchy {
    func forEach(_ apply: (AccessibilityHierarchy) -> Void) {
        apply(self)
        for child in children {
            child.forEach(apply)
        }
    }
}

public extension Array where Element == AccessibilityHierarchy {
    func flattenToElements() -> [AccessibilityElement] {
        var pairs: [(index: Int, element: AccessibilityElement)] = []

        func collect(from node: AccessibilityHierarchy) {
            switch node {
            case let .element(element, index):
                pairs.append((index, element))
            case let .container(_, children):
                children.forEach { collect(from: $0) }
            }
        }

        forEach { collect(from: $0) }
        return pairs.sorted { $0.index < $1.index }.map { $0.element }
    }

    func flattenToContainers() -> [AccessibilityContainer] {
        var containers: [AccessibilityContainer] = []

        func collect(from node: AccessibilityHierarchy) {
            switch node {
            case .element: break
            case let .container(container, children):
                containers.append(container)
                children.forEach { collect(from: $0) }
            }
        }

        forEach { collect(from: $0) }
        return containers
    }
}

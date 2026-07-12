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
    /// THE contextualize step: the single walk that projects a canonical facts tree into markers.
    /// Returns the same tree shape with every element replaced by a copy whose `description` and
    /// `hint` are composed from its graph position (list/landmark boundaries, "X of N", data-table
    /// coordinates) at the given verbosity.
    ///
    /// The composition reads only the element's stored facts (label/value/traits/raw hint) plus the
    /// context derived from its position under the nearest enclosing container — never a previously
    /// composed string — so the returned tree is a terminal, render-ready projection: markers are
    /// rendered, never re-fed through this walk.
    ///
    /// Call this on the full (unpruned) tree so "X of N" counts and data-table header text derive
    /// from the complete child set; prune by `visibility` afterwards.
    func contextualized(verbosity: VerbosityConfiguration = .verbose) -> [AccessibilityHierarchy] {
        func contextualize(_ node: AccessibilityHierarchy, context: DerivedContext?) -> AccessibilityHierarchy {
            switch node {
            case let .element(element, index):
                let (description, hint) = element.description(context: context, verbosity: verbosity)
                return .element(element.withDescription(description, hint: hint), traversalIndex: index)
            case let .container(container, children):
                let contextualizedChildren = children.enumerated().map { childIndex, child in
                    contextualize(child, context: container.derivedContext(forChildAt: childIndex, in: children))
                }
                return .container(container, children: contextualizedChildren)
            }
        }

        return map { contextualize($0, context: nil) }
    }

    /// Collapses the tree into its contextualized elements in traversal order: flattening is the
    /// moment the container structure is dropped, so it is also the moment each element's
    /// graph-derived context is folded into its final rendered string (via `contextualized(verbosity:)`).
    func flattenToElements(verbosity: VerbosityConfiguration = .verbose) -> [AccessibilityElement] {
        var pairs: [(index: Int, element: AccessibilityElement)] = []

        func collect(from node: AccessibilityHierarchy) {
            switch node {
            case let .element(element, index):
                pairs.append((index, element))
            case let .container(_, children):
                children.forEach { collect(from: $0) }
            }
        }

        contextualized(verbosity: verbosity).forEach { collect(from: $0) }
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

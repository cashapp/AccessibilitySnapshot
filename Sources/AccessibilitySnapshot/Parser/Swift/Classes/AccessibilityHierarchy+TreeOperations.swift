// MARK: - Filter

public extension AccessibilityHierarchy {
    /// Returns a pruned copy of the tree containing only nodes where
    /// `isIncluded` returns true.
    ///
    /// For `.element` nodes: kept when the predicate matches, removed otherwise.
    /// For `.container` nodes: children are filtered recursively first.
    ///   - Kept when it has surviving children, even if the container itself
    ///     doesn't match the predicate (structure preservation).
    ///   - Kept with empty children when the container itself matches
    ///     (useful for finding specific container types like `.scrollable`).
    ///   - Removed when no children survive AND the container doesn't match.
    ///
    /// Returns nil when nothing in the subtree matches.
    func filter(
        _ isIncluded: (AccessibilityHierarchy) -> Bool
    ) -> AccessibilityHierarchy? {
        switch self {
        case .element:
            return isIncluded(self) ? self : nil
        case let .container(container, children):
            let surviving = children.compactMap { $0.filter(isIncluded) }
            if !surviving.isEmpty {
                return .container(container, children: surviving)
            }
            if isIncluded(self) {
                return .container(container, children: [])
            }
            return nil
        }
    }
}

// MARK: - Map

public extension AccessibilityHierarchy {
    /// Returns a new tree with `transform` applied to every node, bottom-up.
    ///
    /// Children are mapped before their parent, so the closure receives
    /// each container with its already-transformed children. This makes it
    /// safe to inspect or reshape subtrees during the transform.
    func map(
        _ transform: (AccessibilityHierarchy) -> AccessibilityHierarchy
    ) -> AccessibilityHierarchy {
        switch self {
        case .element:
            return transform(self)
        case let .container(container, children):
            let mappedChildren = children.map { $0.map(transform) }
            return transform(.container(container, children: mappedChildren))
        }
    }
}

// MARK: - Reduce

public extension AccessibilityHierarchy {
    /// Folds the tree into a single value via pre-order depth-first traversal.
    ///
    /// Each node is combined into the accumulator before its children,
    /// left to right. This mirrors `forEach` order — parent first, then
    /// children in traversal order.
    func reduced<Result>(
        _ initialResult: Result,
        _ combine: (Result, AccessibilityHierarchy) -> Result
    ) -> Result {
        var result = combine(initialResult, self)
        for child in children {
            result = child.reduced(result, combine)
        }
        return result
    }
}

// MARK: - Array Conveniences

public extension Array where Element == AccessibilityHierarchy {
    /// Filters each root, removing subtrees with no matches.
    func filteredHierarchy(
        _ isIncluded: (AccessibilityHierarchy) -> Bool
    ) -> [AccessibilityHierarchy] {
        compactMap { $0.filter(isIncluded) }
    }

    /// Maps every node in every root, bottom-up.
    func mappedHierarchy(
        _ transform: (AccessibilityHierarchy) -> AccessibilityHierarchy
    ) -> [AccessibilityHierarchy] {
        map { $0.map(transform) }
    }

    /// Reduces all roots into a single value, left-to-right pre-order.
    func reducedHierarchy<Result>(
        _ initialResult: Result,
        _ combine: (Result, AccessibilityHierarchy) -> Result
    ) -> Result {
        var result = initialResult
        for root in self {
            result = root.reduced(result, combine)
        }
        return result
    }
}

/// Counts of off-screen elements below a single scrollable container, bucketed by where they sit
/// relative to the container's visible viewport.
public struct ScrollContainerSummary: Hashable, Codable, Sendable {
    /// The `.scrollable` container the off-screen elements belong to.
    public let container: AccessibilityContainer
    /// Off-screen elements above the visible viewport (or, for zero-frame elements, ordered before
    /// the first on-screen sibling).
    public let trimmedAbove: Int
    /// Off-screen elements below the visible viewport (or ordered after the last on-screen sibling).
    public let trimmedBelow: Int
    /// Off-screen elements that are neither clearly above nor below (e.g. horizontal overflow, or
    /// indeterminate order).
    public let trimmedElsewhere: Int

    public init(container: AccessibilityContainer, trimmedAbove: Int, trimmedBelow: Int, trimmedElsewhere: Int) {
        self.container = container
        self.trimmedAbove = trimmedAbove
        self.trimmedBelow = trimmedBelow
        self.trimmedElsewhere = trimmedElsewhere
    }

    /// Whether this summary carries any nonzero count worth surfacing.
    public var isEmpty: Bool {
        trimmedAbove == 0 && trimmedBelow == 0 && trimmedElsewhere == 0
    }
}

public extension Array where Element == AccessibilityHierarchy {
    /// The on-screen accessibility hierarchy: the same tree with every `.offscreen` element removed
    /// and any container left with no surviving children dropped (an empty container is not an
    /// accessibility element — VoiceOver never stops on it — so it must not remain in the tree).
    ///
    /// This is a tree-to-tree transform. Flatten the result to get the rendered element list:
    ///
    ///     hierarchy.onscreen().flattenToElements()
    ///
    /// The full tree (`self`) still carries the off-screen elements; read `scrollContainerSummaries()`
    /// off it — not off the pruned result — to tally what was dropped.
    ///
    /// - Note: Context derivation (list/landmark boundaries, "X of N", data-table coordinates) is
    ///   composed separately from graph position; this transform preserves the ordered structure
    ///   that derivation reads.
    func onscreen() -> [AccessibilityHierarchy] {
        filter { $0.isOnscreen }.map { $0.filteredToOnscreen() }
    }

    /// Per-scroll-container tallies of the off-screen elements the on-screen filter drops, bucketed
    /// above/below/elsewhere relative to each `.scrollable` container's viewport.
    ///
    /// Computed over the full tree (`self`) — the off-screen elements only exist here, before
    /// `onscreen()` prunes them. Returns one summary per `.scrollable` container that has anything
    /// off-screen; containers with everything on-screen are omitted.
    func scrollContainerSummaries() -> [ScrollContainerSummary] {
        var summaries: [ScrollContainerSummary] = []

        // Walk containers depth-first; at each `.scrollable` node classify its off-screen descendants
        // relative to that container's frame and tally a summary.
        func visit(_ node: AccessibilityHierarchy) {
            switch node {
            case .element:
                break
            case let .container(container, children):
                if case .scrollable = container.type {
                    let (above, below, elsewhere) = Self.classifyOffscreen(in: children, container: container)
                    if above + below + elsewhere > 0 {
                        summaries.append(
                            ScrollContainerSummary(
                                container: container,
                                trimmedAbove: above,
                                trimmedBelow: below,
                                trimmedElsewhere: elsewhere
                            )
                        )
                    }
                }
                for child in children {
                    visit(child)
                }
            }
        }
        for node in self {
            visit(node)
        }
        return summaries
    }

    /// Classifies the off-screen leaf elements directly beneath a scrollable container into
    /// above/below/elsewhere buckets. Framed elements compare against the container's viewport;
    /// zero-frame elements fall back to enumeration order relative to on-screen siblings.
    private static func classifyOffscreen(
        in children: [AccessibilityHierarchy],
        container: AccessibilityContainer
    ) -> (above: Int, below: Int, elsewhere: Int) {
        // Collect this container's leaf elements in order, stopping at nested scrollables (those
        // own their own summaries).
        var leaves: [AccessibilityElement] = []
        func collect(_ node: AccessibilityHierarchy) {
            switch node {
            case let .element(element, _):
                leaves.append(element)
            case let .container(inner, innerChildren):
                if case .scrollable = inner.type { return }
                for child in innerChildren {
                    collect(child)
                }
            }
        }
        for child in children {
            collect(child)
        }

        let firstOnscreen = leaves.firstIndex { $0.visibility == .onscreen }
        let lastOnscreen = leaves.lastIndex { $0.visibility == .onscreen }

        var above = 0, below = 0, elsewhere = 0
        for (index, leaf) in leaves.enumerated() where leaf.visibility == .offscreen {
            let rect = leaf.shape.boundingRect
            if rect.width > 0, rect.height > 0 {
                if rect.maxY <= container.frame.minY {
                    above += 1
                } else if rect.minY >= container.frame.maxY {
                    below += 1
                } else {
                    elsewhere += 1
                }
            } else if let first = firstOnscreen, index < first {
                above += 1
            } else if let last = lastOnscreen, index > last {
                below += 1
            } else {
                elsewhere += 1
            }
        }
        return (above, below, elsewhere)
    }
}

private extension AccessibilityHierarchy {
    /// Whether this node has any on-screen content. An element is on-screen when its `visibility`
    /// is `.onscreen`; a container is on-screen when at least one descendant is (an empty container
    /// is not an accessibility element). This is the predicate `onscreen()` filters on.
    var isOnscreen: Bool {
        switch self {
        case let .element(element, _):
            return element.visibility == .onscreen
        case let .container(_, children):
            return children.contains { $0.isOnscreen }
        }
    }

    /// This node with its off-screen descendants filtered out. Only meaningful for containers (an
    /// element has no children to filter); recursively keeps the on-screen subtree.
    func filteredToOnscreen() -> AccessibilityHierarchy {
        switch self {
        case .element:
            return self
        case let .container(container, children):
            return .container(container, children: children.filter { $0.isOnscreen }.map { $0.filteredToOnscreen() })
        }
    }
}

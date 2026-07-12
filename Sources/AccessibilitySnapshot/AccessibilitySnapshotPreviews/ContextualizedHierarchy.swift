import AccessibilitySnapshotCore
import AccessibilitySnapshotParser

/// The snapshot's hierarchical view model: markers in their container structure.
///
/// The hierarchy types (`AccessibilityHierarchy`, `AccessibilityElement`, `AccessibilityContainer`)
/// are canonical — the parser's product, pure facts. Markers are view models for a snapshot:
/// elements whose spoken description and hint have been composed from graph-derived container
/// context, final and render-ready. This walk is the canonical→marker projection for the
/// container-aware legend, just as the materializing flatten is for the flat legend. The composer
/// (`description(context:verbosity:)`) only ever accepts canonical elements, so re-contextualizing
/// a contextualized hierarchy is a category error: markers are rendered, never re-composed.
///
/// Marker numbering and colors are also snapshot properties, assigned by the view layer
/// (see `HierarchyLegendView`).
///
/// Like the materializing flatten, the walk derives context from the FULL child set (so "X of N"
/// counts and data-table headers are complete) while emitting only on-screen elements unless
/// `includesOffscreen` is set; a container whose children are all filtered out is dropped (an empty
/// container is not an accessibility element).
@available(iOS 16.0, *)
public struct ContextualizedHierarchy {
    /// A marker (or container of markers) in hierarchy order.
    public enum Node {
        case element(AccessibilityMarker)
        case container(AccessibilityContainer, children: [Node])
    }

    /// The contextualized nodes in hierarchy order. Markers appear in the same traversal order as
    /// the materializing flatten, so a flat walk of this tree aligns with the `markers` array.
    public let nodes: [Node]

    /// Applies context to a hierarchy tree, composing each element's description and hint from its
    /// graph position via the model's single contextualize walk — the same walk the materializing
    /// flatten uses, so both legend modes speak identically.
    public static func build(
        from hierarchy: [AccessibilityHierarchy],
        verbosity: VerbosityConfiguration = .verbose,
        includesOffscreen: Bool = false
    ) -> ContextualizedHierarchy {
        func node(from marker: AccessibilityHierarchy) -> Node? {
            switch marker {
            case let .element(element, _):
                guard includesOffscreen || element.visibility == .onscreen else { return nil }
                return .element(element)
            case let .container(container, children):
                let filteredChildren = children.compactMap { node(from: $0) }
                guard !filteredChildren.isEmpty else { return nil }
                return .container(container, children: filteredChildren)
            }
        }

        return ContextualizedHierarchy(nodes: hierarchy.contextualized(verbosity: verbosity).compactMap { node(from: $0) })
    }
}

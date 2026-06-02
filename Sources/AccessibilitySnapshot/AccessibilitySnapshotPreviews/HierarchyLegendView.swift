import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import SwiftUI

/// Renders a hierarchical legend from a parsed accessibility hierarchy.
///
/// Element color indices come straight from `traversalIndex` (the parser already assigns
/// these as 0..<N in VoiceOver order — same as `markers.flattenToElements()`), so the
/// legend's element badges share their palette slot with the overlays drawn on the snapshot.
/// Container color indices are assigned by depth-first walk order, starting at 0.
///
/// When `availableHeight` is set, top-level entries are flowed across multiple columns via
/// `ColumnWrapLayout` so tall hierarchies don't exceed the snapshot height. Containers stay
/// intact within a single column — they aren't split.
@available(iOS 16.0, *)
struct HierarchyLegendView: View {
    let hierarchy: [AccessibilityHierarchy]
    let palette: ColorPalette
    let showUserInputLabels: Bool
    let showUnspokenTraits: Bool
    var availableHeight: CGFloat? = nil

    var body: some View {
        if let availableHeight {
            ColumnWrapLayout(
                availableHeight: availableHeight,
                columnWidth: LegendLayoutMetrics.minimumLegendWidth,
                horizontalSpacing: LegendLayoutMetrics.legendHorizontalSpacing,
                verticalSpacing: LegendLayoutMetrics.legendVerticalSpacing
            ) {
                nodeViews(hierarchy)
            }
        } else {
            VStack(alignment: .leading, spacing: LegendLayoutMetrics.legendVerticalSpacing) {
                nodeViews(hierarchy)
            }
        }
    }

    /// Assign each container in depth-first order an index 0, 1, 2, … then render.
    private func nodeViews(_ nodes: [AccessibilityHierarchy]) -> some View {
        var counter = 0
        let indexed = Self.assignContainerIndices(nodes, counter: &counter)
        return ForEach(indexed.indices, id: \.self) { i in
            nodeView(for: indexed[i])
        }
    }

    @ViewBuilder
    private func nodeView(for node: IndexedNode) -> some View {
        switch node {
        case let .element(element, traversalIndex):
            LegendEntryView(
                index: traversalIndex,
                marker: element,
                palette: palette,
                showUserInputLabels: showUserInputLabels,
                showUnspokenTraits: showUnspokenTraits
            )

        case let .container(container, colorIndex, children):
            ContainerLegendEntryView(
                index: colorIndex,
                container: container,
                palette: palette,
                childViews: AnyView(
                    VStack(alignment: .leading, spacing: LegendLayoutMetrics.legendVerticalSpacing) {
                        ForEach(children.indices, id: \.self) { i in
                            nodeView(for: children[i])
                        }
                    }
                )
            )
        }
    }

    // MARK: - Container index assignment

    /// Element nodes carry their parser-assigned `traversalIndex` directly. Container nodes
    /// get an index from a depth-first counter — kept inline rather than as a public type
    /// because the only consumer is this view.
    private enum IndexedNode {
        case element(AccessibilityElement, traversalIndex: Int)
        case container(AccessibilityContainer, colorIndex: Int, children: [IndexedNode])
    }

    private static func assignContainerIndices(
        _ nodes: [AccessibilityHierarchy],
        counter: inout Int
    ) -> [IndexedNode] {
        nodes.map { node in
            switch node {
            case let .element(element, traversalIndex):
                return .element(element, traversalIndex: traversalIndex)
            case let .container(container, children):
                let index = counter
                counter += 1
                let mappedChildren = assignContainerIndices(children, counter: &counter)
                return .container(container, colorIndex: index, children: mappedChildren)
            }
        }
    }
}

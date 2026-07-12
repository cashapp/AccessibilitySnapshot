import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import SwiftUI

/// Renders a hierarchical legend from contextualized nodes, with containers wrapping their children.
///
/// Marker numbering (and the color each number selects from the palette) is a property of the
/// snapshot rendering, not the hierarchy, so it is assigned here: elements get their flat
/// traversal-order index (matching the `markers` array, so element overlays render identically
/// whether or not container mode is enabled), and containers get a separate pre-order sequence
/// starting after all elements.
@available(iOS 16.0, *)
struct HierarchyLegendView: View {
    let palette: ColorPalette
    let showUserInputLabels: Bool
    let showUnspokenTraits: Bool

    private let numberedNodes: [NumberedNode]

    init(
        nodes: [ContextualizedHierarchy.Node],
        palette: ColorPalette,
        showUserInputLabels: Bool,
        showUnspokenTraits: Bool
    ) {
        numberedNodes = Self.number(nodes)
        self.palette = palette
        self.showUserInputLabels = showUserInputLabels
        self.showUnspokenTraits = showUnspokenTraits
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LegendLayoutMetrics.legendVerticalSpacing) {
            ForEach(numberedNodes.indices, id: \.self) { i in
                nodeView(for: numberedNodes[i])
            }
        }
    }

    // MARK: - Numbering

    private indirect enum NumberedNode {
        case element(AccessibilityMarker, index: Int)
        case container(AccessibilityContainer, index: Int, children: [NumberedNode])
    }

    private static func number(_ nodes: [ContextualizedHierarchy.Node]) -> [NumberedNode] {
        func countElements(in nodes: [ContextualizedHierarchy.Node]) -> Int {
            nodes.reduce(0) { count, node in
                switch node {
                case .element:
                    return count + 1
                case let .container(_, children):
                    return count + countElements(in: children)
                }
            }
        }

        let totalElements = countElements(in: nodes)
        var elementCounter = 0
        var containerCounter = 0

        func number(_ node: ContextualizedHierarchy.Node) -> NumberedNode {
            switch node {
            case let .element(element):
                let index = elementCounter
                elementCounter += 1
                return .element(element, index: index)

            case let .container(container, children):
                // Pre-order: a container is numbered before any containers nested inside it.
                let index = totalElements + containerCounter
                containerCounter += 1
                return .container(container, index: index, children: children.map { number($0) })
            }
        }

        return nodes.map { number($0) }
    }

    // MARK: - Rendering

    @ViewBuilder
    private func nodeView(for node: NumberedNode) -> some View {
        switch node {
        case let .element(marker, index):
            LegendEntryView(
                index: index,
                marker: marker,
                palette: palette,
                showUserInputLabels: showUserInputLabels,
                showUnspokenTraits: showUnspokenTraits
            )

        case let .container(container, index, children):
            ContainerLegendEntryView(
                index: index,
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
}

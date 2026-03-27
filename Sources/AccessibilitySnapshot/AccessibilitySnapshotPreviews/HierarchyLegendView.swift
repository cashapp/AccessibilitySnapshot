import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import SwiftUI

/// Renders a hierarchical legend from assigned nodes, with containers wrapping their children.
@available(iOS 16.0, *)
struct HierarchyLegendView: View {
    let nodes: [HierarchyColorAssignment.AssignedNode]
    let palette: ColorPalette
    let showUserInputLabels: Bool
    let showUnspokenTraits: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: LegendLayoutMetrics.legendVerticalSpacing) {
            ForEach(nodes.indices, id: \.self) { i in
                nodeView(for: nodes[i])
            }
        }
        .padding(LegendLayoutMetrics.legendInset)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func nodeView(for node: HierarchyColorAssignment.AssignedNode) -> some View {
        switch node {
        case let .element(element, colorIndex):
            LegendEntryView(
                index: colorIndex,
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
}

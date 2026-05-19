import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import SwiftUI

/// Renders a hierarchical legend from assigned nodes, with containers wrapping their children.
///
/// When `availableHeight` is set, top-level entries are flowed across multiple columns via
/// `ColumnWrapLayout` so tall hierarchies don't exceed the snapshot height. Containers stay
/// intact within a single column — they aren't split.
@available(iOS 16.0, *)
struct HierarchyLegendView: View {
    let nodes: [HierarchyColorAssignment.AssignedNode]
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
                ForEach(nodes.indices, id: \.self) { i in
                    nodeView(for: nodes[i])
                }
            }
        } else {
            VStack(alignment: .leading, spacing: LegendLayoutMetrics.legendVerticalSpacing) {
                ForEach(nodes.indices, id: \.self) { i in
                    nodeView(for: nodes[i])
                }
            }
        }
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

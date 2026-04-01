import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import SwiftUI

/// A legend entry for an accessibility container, with its children indented underneath.
@available(iOS 16.0, *)
struct ContainerLegendEntryView: View {
    let index: Int
    let container: AccessibilityContainer
    let palette: ColorPalette
    let childViews: AnyView

    var body: some View {
        VStack(alignment: .leading, spacing: LegendLayoutMetrics.interItemSpacing) {
            // Container header
            HStack(alignment: .top, spacing: LegendLayoutMetrics.markerToLabelSpacing) {
                NumberBadge(index: index, palette: palette)

                VStack(alignment: .leading, spacing: 2) {
                    if let label = containerLabel {
                        Text(label)
                            .font(DesignTokens.Typography.description)
                            .foregroundColor(DesignTokens.Colors.primaryText)
                    }
                    Text(containerTypeName)
                        .font(DesignTokens.Typography.hint)
                        .foregroundColor(DesignTokens.Colors.secondaryText)
                    if let value = containerValue {
                        Text(value)
                            .font(DesignTokens.Typography.hint)
                            .foregroundColor(DesignTokens.Colors.secondaryText)
                    }
                }
            }

            // Child elements, indented
            childViews
                .padding(.leading, LegendLayoutMetrics.markerToLabelSpacing + DesignTokens.Badge.size)
        }
        .padding(LegendLayoutMetrics.interItemSpacing)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Element.legendCornerRadius)
                .stroke(
                    palette.strokeColor(at: index),
                    style: StrokeStyle(lineWidth: DesignTokens.Element.strokeWidth, dash: [4, 4])
                )
        )
    }

    private var containerTypeName: String {
        switch container.type {
        case .semanticGroup:
            return "Semantic Group"
        case .list:
            return "List"
        case .landmark:
            return "Landmark"
        case let .dataTable(rowCount, columnCount):
            return "Data Table (\(rowCount) \u{00d7} \(columnCount))"
        case .tabBar:
            return "Tab Bar"
        }
    }

    private var containerLabel: String? {
        switch container.type {
        case let .semanticGroup(label, _, _):
            return label
        default:
            return nil
        }
    }

    private var containerValue: String? {
        switch container.type {
        case let .semanticGroup(_, value, _):
            return value
        default:
            return nil
        }
    }
}

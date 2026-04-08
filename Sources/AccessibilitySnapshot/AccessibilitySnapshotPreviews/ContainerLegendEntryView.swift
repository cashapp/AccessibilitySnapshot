import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import SwiftUI

/// A legend entry for an accessibility container, with its children inside a dashed border.
@available(iOS 16.0, *)
struct ContainerLegendEntryView: View {
    let index: Int
    let container: AccessibilityContainer
    let palette: ColorPalette
    let childViews: AnyView

    private static let containerInset: CGFloat = 10
    private let badgeHeight: CGFloat = DesignTokens.Badge.minSize

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .frame(height: badgeHeight / 2)

            VStack(alignment: .leading, spacing: LegendLayoutMetrics.legendVerticalSpacing) {
                childViews
            }
            .padding(Self.containerInset)
            .padding(.top, badgeHeight / 2)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Element.legendCornerRadius)
                    .stroke(
                        palette.strokeColor(at: index),
                        style: StrokeStyle(lineWidth: DesignTokens.Element.strokeWidth, dash: [4, 4])
                    )
            )
            .overlay(alignment: .topLeading) {
                ContainerBadge(index: index, container: container, palette: palette)
                    .offset(
                        x: Self.containerInset,
                        y: -badgeHeight / 2
                    )
            }
        }
    }
}

/// A badge for container entries that includes a layer icon, number, and container label.
@available(iOS 16.0, *)
struct ContainerBadge: View {
    let index: Int
    let container: AccessibilityContainer
    let palette: ColorPalette

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "square.on.square")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)

            Text(displayName)
                .font(DesignTokens.Typography.badgeNumber)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 4)
        .frame(minHeight: DesignTokens.Badge.minSize)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Badge.cornerRadius)
                .fill(palette.color(at: index))
        )
    }

    private var displayName: String {
        switch container.type {
        case let .semanticGroup(label, value, identifier):
            let parts = [label, value].compactMap { $0?.isEmpty == false ? $0 : nil }
            if !parts.isEmpty {
                return parts.joined(separator: ": ")
            } else if let identifier, !identifier.isEmpty {
                return identifier
            }
            return "Semantic Group"
        case .list:
            return "List"
        case .landmark:
            return "Landmark"
        case let .dataTable(rowCount, columnCount):
            return "Data Table (\(rowCount) × \(columnCount))"
        case .tabBar:
            return "Tab Bar"
        }
    }
}

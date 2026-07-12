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
                ContainerBadge(index: index, palette: palette)
                    .offset(
                        x: Self.containerInset,
                        y: -badgeHeight / 2
                    )
            }
        }
    }
}

/// A badge for container entries that includes a layer icon alongside the number.
@available(iOS 16.0, *)
struct ContainerBadge: View {
    let index: Int
    let palette: ColorPalette

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "square.on.square")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)

            Text("\(index + 1)")
                .font(DesignTokens.Typography.badgeNumber)
                .tracking(-1)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 4)
        .frame(minHeight: DesignTokens.Badge.minSize)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Badge.cornerRadius)
                .fill(palette.color(at: index))
        )
    }
}

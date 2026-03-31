import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import SwiftUI

/// Renders a dashed border overlay for an accessibility container on the snapshot.
@available(iOS 16.0, *)
struct ContainerOverlayView: View {
    let container: AccessibilityContainer
    let index: Int
    let palette: ColorPalette

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: DesignTokens.Element.overlayCornerRadius)
                .stroke(
                    palette.strokeColor(at: index),
                    style: StrokeStyle(lineWidth: DesignTokens.Element.strokeWidth, dash: [4, 4])
                )
                .frame(width: frame.width, height: frame.height)

            // Badge: left-aligned, centered vertically on the top border line
            ContainerBadge(index: index, palette: palette)
                .offset(
                    x: DesignTokens.Badge.size / 2,
                    y: -DesignTokens.Badge.minSize / 2
                )
        }
        .frame(width: frame.width, height: frame.height)
        .position(x: frame.midX, y: frame.midY)
    }

    private var frame: CGRect {
        container.frame.insetBy(
            dx: -DesignTokens.Element.overlayOutset,
            dy: -DesignTokens.Element.overlayOutset
        )
    }
}

/// A badge for container overlays that includes a layer icon alongside the number.
@available(iOS 16.0, *)
struct ContainerBadge: View {
    let index: Int
    let palette: ColorPalette

    var body: some View {
        HStack(spacing: 2) {
            // Layer icon (stacked squares)
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

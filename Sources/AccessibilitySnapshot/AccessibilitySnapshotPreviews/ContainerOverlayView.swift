import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import SwiftUI

/// Renders a dashed border overlay for an accessibility container on the snapshot.
/// The border wraps around the child element frames, not the container UIView's geometry.
@available(iOS 16.0, *)
struct ContainerOverlayView: View {
    let entry: HierarchyColorAssignment.ContainerEntry
    let palette: ColorPalette

    /// Padding between the dashed border and the outermost child element overlays.
    private static let containerPadding: CGFloat = 6

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: DesignTokens.Element.overlayCornerRadius)
                .stroke(
                    palette.strokeColor(at: entry.colorIndex),
                    style: StrokeStyle(lineWidth: DesignTokens.Element.strokeWidth, dash: [4, 4])
                )
                .frame(width: frame.width, height: frame.height)

            // Badge: left-aligned, centered vertically on the top border line
            ContainerBadge(index: entry.colorIndex, palette: palette)
                .offset(
                    x: DesignTokens.Badge.size / 2,
                    y: -DesignTokens.Badge.minSize / 2
                )
        }
        .frame(width: frame.width, height: frame.height)
        .position(x: frame.midX, y: frame.midY)
    }

    private var frame: CGRect {
        // Expand outward from the child-element bounding rect
        let outset = DesignTokens.Element.overlayOutset + Self.containerPadding
        return entry.bounds.insetBy(dx: -outset, dy: -outset)
    }
}

/// A badge for container overlays that includes a layer icon alongside the number.
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

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

            NumberBadge(index: index, palette: palette)
                .position(BadgePlacement.badgeCenter(in: frame))
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

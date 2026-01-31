import AccessibilitySnapshotParser
import SwiftUI

/// Renders an accessibility element's visual representation.
/// Works at both overlay scale (large, on snapshot) and legend scale (small marker).
struct ElementView: View {
    enum DisplayMode {
        case overlay(shape: AccessibilityMarker.Shape)
        case legend
    }

    let index: Int
    let palette: AccessibilityColorPalette
    let mode: DisplayMode

    private enum Metrics {
        static let strokeWidth: CGFloat = 1
        static let overlayCornerRadius: CGFloat = 8
        static let legendSize: CGFloat = LegendLayoutMetrics.markerSize
        static let legendCornerRadius: CGFloat = 3
        static let overlayFontSize: CGFloat = 12
        static let legendFontSize: CGFloat = 8
        static let badgePadding: CGFloat = 4
    }

    private var numberText: String {
        String(format: "%02d", index + 1)
    }

    private var fillColor: Color {
        palette.fillColor(at: index)
    }

    private var strokeColor: Color {
        palette.strokeColor(at: index)
    }

    private var solidColor: Color {
        palette.solidColor(at: index)
    }

    var body: some View {
        switch mode {
        case let .overlay(shape):
            overlayElement(shape: shape)
        case .legend:
            legendElement
        }
    }

    // MARK: - Overlay Mode

    @ViewBuilder
    private func overlayElement(shape: AccessibilityMarker.Shape) -> some View {
        ZStack(alignment: .topLeading) {
            shapeView(shape: shape)
            numberBadge(for: shape)
        }
    }

    @ViewBuilder
    private func shapeView(shape: AccessibilityMarker.Shape) -> some View {
        switch shape {
        case let .frame(rect):
            RoundedRectangle(cornerRadius: Metrics.overlayCornerRadius)
                .fill(fillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: Metrics.overlayCornerRadius)
                        .stroke(strokeColor, lineWidth: Metrics.strokeWidth)
                )
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)

        case let .path(path):
            Path(path.cgPath)
                .fill(fillColor)
            Path(path.cgPath)
                .stroke(strokeColor, lineWidth: Metrics.strokeWidth)
        }
    }

    @ViewBuilder
    private func numberBadge(for shape: AccessibilityMarker.Shape) -> some View {
        let bounds = shapeBounds(shape)

        Text(numberText)
            .font(.system(size: Metrics.overlayFontSize, weight: .semibold))
            .foregroundColor(solidColor)
            .position(x: bounds.minX + Metrics.badgePadding + 6, y: bounds.minY + Metrics.badgePadding + 6)
    }

    private func shapeBounds(_ shape: AccessibilityMarker.Shape) -> CGRect {
        switch shape {
        case let .frame(rect):
            return rect
        case let .path(path):
            return path.cgPath.boundingBox
        }
    }

    // MARK: - Legend Mode

    private var legendElement: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Metrics.legendCornerRadius)
                .fill(fillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: Metrics.legendCornerRadius)
                        .stroke(strokeColor, lineWidth: Metrics.strokeWidth)
                )

            Text(numberText)
                .font(.system(size: Metrics.legendFontSize, weight: .semibold))
                .foregroundColor(solidColor)
        }
        .frame(width: Metrics.legendSize, height: Metrics.legendSize)
    }
}

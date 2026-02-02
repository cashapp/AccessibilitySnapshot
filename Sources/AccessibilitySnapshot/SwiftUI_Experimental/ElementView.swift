import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import SwiftUI

/// Renders an accessibility element's visual representation.
/// Works at both overlay scale (large, on snapshot) and legend scale (small marker).
@available(iOS 18.0, *)
public struct ElementView: View {
    public enum DisplayMode {
        case overlay(shape: AccessibilityMarker.Shape)
        case legend
    }

    public let index: Int
    public let palette: ColorPalette
    public let mode: DisplayMode

    public init(index: Int, palette: ColorPalette, mode: DisplayMode) {
        self.index = index
        self.palette = palette
        self.mode = mode
    }

    private typealias Tokens = DesignTokens.Element

    private var numberText: String {
        "\(index + 1)"
    }

    private var fillColor: Color {
        palette.fillColor(at: index)
    }

    private var strokeColor: Color {
        palette.strokeColor(at: index)
    }

    public var body: some View {
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
            ZStack {
                RoundedRectangle(cornerRadius: Tokens.overlayCornerRadius)
                    .fill(fillColor)
                RoundedRectangle(cornerRadius: Tokens.overlayCornerRadius)
                    .stroke(strokeColor, lineWidth: Tokens.strokeWidth)
            }
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)

        case let .path(path):
            Path(path.cgPath)
                .fill(fillColor)
            Path(path.cgPath)
                .stroke(strokeColor, lineWidth: Tokens.strokeWidth)
        }
    }

    @ViewBuilder
    private func numberBadge(for shape: AccessibilityMarker.Shape) -> some View {
        let bounds = shapeBounds(shape)

        Text(numberText)
            .font(DesignTokens.Typography.overlayNumber)
            .foregroundColor(strokeColor)
            .position(x: bounds.minX + Tokens.badgePadding + Tokens.badgeOffset, y: bounds.minY + Tokens.badgePadding + Tokens.badgeOffset)
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
            RoundedRectangle(cornerRadius: Tokens.legendCornerRadius)
                .fill(fillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: Tokens.legendCornerRadius)
                        .stroke(strokeColor, lineWidth: Tokens.strokeWidth)
                )

            Text(numberText)
                .font(DesignTokens.Typography.legendNumber)
                .foregroundColor(strokeColor)
        }
        .frame(width: LegendLayoutMetrics.markerSize, height: LegendLayoutMetrics.markerSize)
    }
}

// MARK: - Preview

@available(iOS 18.0, *)
#Preview("Legend Mode") {
    HStack(spacing: 8) {
        ForEach(0 ..< 8, id: \.self) { index in
            ElementView(index: index, palette: .default, mode: .legend)
        }
    }
    .padding()
}

@available(iOS 18.0, *)
#Preview("Overlay Mode") {
    ZStack {
        Color.gray.opacity(0.2)
        ElementView(
            index: 0,
            palette: .default,
            mode: .overlay(shape: .frame(CGRect(x: 50, y: 50, width: 200, height: 60)))
        )
    }
    .frame(width: 300, height: 160)
}

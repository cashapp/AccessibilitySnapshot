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

    /// Fully opaque color for badge backgrounds.
    private var badgeColor: Color {
        palette.color(at: index)
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
            // Frame-based elements use rounded rectangle with 2pt outset
            roundedRectOverlay(rect: rect.insetBy(dx: -Tokens.overlayOutset, dy: -Tokens.overlayOutset))
        case let .path(path):
            // Path-based elements render the actual path shape
            pathOverlay(path: path.cgPath)
        }
    }

    /// Renders a path-based overlay following the actual accessibility path.
    @ViewBuilder
    private func pathOverlay(path: CGPath) -> some View {
        let bounds = path.boundingBox
        CGPathShape(path: path)
            .fill(fillColor)
            .overlay(
                CGPathShape(path: path)
                    .stroke(strokeColor, lineWidth: Tokens.strokeWidth)
            )
            .frame(width: bounds.width, height: bounds.height)
            .position(x: bounds.midX, y: bounds.midY)
    }

    /// Renders a rounded rectangle overlay at the given rect.
    @ViewBuilder
    private func roundedRectOverlay(rect: CGRect) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: Tokens.overlayCornerRadius)
                .fill(fillColor)
            RoundedRectangle(cornerRadius: Tokens.overlayCornerRadius)
                .stroke(strokeColor, lineWidth: Tokens.strokeWidth)
        }
        .frame(width: rect.width, height: rect.height)
        .position(x: rect.midX, y: rect.midY)
    }

    private func badgeCenter(for shape: AccessibilityMarker.Shape) -> CGPoint {
        // Always use bounding box for consistent, predictable badge placement
        let bounds: CGRect
        switch shape {
        case let .frame(rect):
            bounds = rect.insetBy(dx: -Tokens.overlayOutset, dy: -Tokens.overlayOutset)
        case let .path(path):
            bounds = path.cgPath.boundingBox
        }
        return BadgePlacement.badgeCenter(in: bounds)
    }

    @ViewBuilder
    private func numberBadge(for shape: AccessibilityMarker.Shape) -> some View {
        Text(numberText)
            .font(DesignTokens.Typography.badgeNumber)
            .tracking(-1)
            .foregroundColor(.white)
            .frame(minWidth: DesignTokens.Badge.minSize, minHeight: DesignTokens.Badge.minSize)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Badge.cornerRadius)
                    .fill(badgeColor)
            )
            .position(badgeCenter(for: shape))
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

// MARK: - CGPath Shape Wrapper

/// A SwiftUI Shape that wraps a CGPath for rendering.
@available(iOS 18.0, *)
private struct CGPathShape: Shape {
    let path: CGPath

    func path(in rect: CGRect) -> Path {
        // The path is already in the correct coordinate space
        // We just need to translate it so it's positioned relative to rect.origin
        let bounds = path.boundingBox
        var transform = CGAffineTransform(translationX: -bounds.minX, y: -bounds.minY)
        if let transformed = path.copy(using: &transform) {
            return Path(transformed)
        }
        return Path(path)
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
            mode: .overlay(shape: .frame(CGRect(x: 50, y: 30, width: 200, height: 50)))
        )
        ElementView(
            index: 1,
            palette: .default,
            mode: .overlay(shape: .frame(CGRect(x: 50, y: 100, width: 200, height: 80)))
        )
        ElementView(
            index: 2,
            palette: .default,
            mode: .overlay(shape: .frame(CGRect(x: 50, y: 200, width: 200, height: 50)))
        )
        ElementView(
            index: 3,
            palette: .default,
            mode: .overlay(shape: .frame(CGRect(x: 50, y: 270, width: 200, height: 50)))
        )
    }
    .frame(width: 300, height: 350)
}


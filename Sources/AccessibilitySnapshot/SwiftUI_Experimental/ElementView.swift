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
            // Expand rect by 2pt on all edges (like VoiceOver highlight)
            let expanded = rect.insetBy(dx: -Tokens.overlayOutset, dy: -Tokens.overlayOutset)
            ZStack {
                RoundedRectangle(cornerRadius: Tokens.overlayCornerRadius)
                    .fill(fillColor)
                RoundedRectangle(cornerRadius: Tokens.overlayCornerRadius)
                    .stroke(strokeColor, lineWidth: Tokens.strokeWidth)
            }
            .frame(width: expanded.width, height: expanded.height)
            .position(x: expanded.midX, y: expanded.midY)

        case let .path(path):
            if path.cgPath.isRectangular {
                // Rectangular paths get rounded corners like frames
                // Expand rect by 2pt on all edges (like VoiceOver highlight)
                let rect = path.cgPath.boundingBox
                let expanded = rect.insetBy(dx: -Tokens.overlayOutset, dy: -Tokens.overlayOutset)
                ZStack {
                    RoundedRectangle(cornerRadius: Tokens.overlayCornerRadius)
                        .fill(fillColor)
                    RoundedRectangle(cornerRadius: Tokens.overlayCornerRadius)
                        .stroke(strokeColor, lineWidth: Tokens.strokeWidth)
                }
                .frame(width: expanded.width, height: expanded.height)
                .position(x: expanded.midX, y: expanded.midY)
            } else {
                // Non-rectangular paths render as-is
                Path(path.cgPath)
                    .fill(fillColor)
                Path(path.cgPath)
                    .stroke(strokeColor, lineWidth: Tokens.strokeWidth)
            }
        }
    }

    @ViewBuilder
    private func numberBadge(for shape: AccessibilityMarker.Shape) -> some View {
        let center = badgeCenter(for: shape)

        Text(numberText)
            .font(DesignTokens.Typography.badgeNumber)
            .tracking(-1)
            .foregroundColor(.white)
            .frame(minWidth: DesignTokens.Badge.minSize, minHeight: DesignTokens.Badge.minSize)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Badge.cornerRadius)
                    .fill(badgeColor)
            )
            .position(center)
    }

    private func badgeCenter(for shape: AccessibilityMarker.Shape) -> CGPoint {
        switch shape {
        case let .frame(rect):
            // Use the expanded frame (matches the visible overlay)
            let expanded = rect.insetBy(dx: -Tokens.overlayOutset, dy: -Tokens.overlayOutset)
            return BadgePlacement.badgeCenter(in: expanded)
        case let .path(path):
            // Use the expanded bounding box (matches the visible overlay)
            let rect = path.cgPath.boundingBox
            let expanded = rect.insetBy(dx: -Tokens.overlayOutset, dy: -Tokens.overlayOutset)
            return BadgePlacement.badgeCenter(in: expanded)
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

// MARK: - CGPath Rectangle Detection

extension CGPath {
    /// Returns true if this path is a rectangle (4 corners with 90° angles).
    var isRectangular: Bool {
        var points: [CGPoint] = []
        var hasCurves = false

        applyWithBlock { element in
            switch element.pointee.type {
            case .moveToPoint:
                points.append(element.pointee.points[0])
            case .addLineToPoint:
                points.append(element.pointee.points[0])
            case .closeSubpath:
                break
            case .addQuadCurveToPoint, .addCurveToPoint:
                hasCurves = true
            @unknown default:
                break
            }
        }

        // Must have no curves and exactly 4 or 5 points (4 corners, possibly repeated start)
        guard !hasCurves, points.count >= 4, points.count <= 5 else {
            return false
        }

        // Take first 4 points
        let corners = Array(points.prefix(4))

        // Check all angles are 90°
        for i in 0 ..< 4 {
            let p0 = corners[i]
            let p1 = corners[(i + 1) % 4]
            let p2 = corners[(i + 2) % 4]

            // Vector from p1 to p0
            let v1 = CGVector(dx: p0.x - p1.x, dy: p0.y - p1.y)
            // Vector from p1 to p2
            let v2 = CGVector(dx: p2.x - p1.x, dy: p2.y - p1.y)

            // Dot product should be ~0 for perpendicular vectors
            let dot = v1.dx * v2.dx + v1.dy * v2.dy
            if abs(dot) > 0.01 {
                return false
            }
        }

        return true
    }
}

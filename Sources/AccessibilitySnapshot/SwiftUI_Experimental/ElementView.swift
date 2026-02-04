import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import SwiftUI

// MARK: - Number Badge

/// A numbered badge for accessibility element markers.
/// Used in both overlay (positioned on snapshot) and legend (standalone marker).
@available(iOS 18.0, *)
public struct NumberBadge: View {
    public let index: Int
    public let palette: ColorPalette

    public init(index: Int, palette: ColorPalette) {
        self.index = index
        self.palette = palette
    }

    public var body: some View {
        Text("\(index + 1)")
            .font(DesignTokens.Typography.badgeNumber)
            .tracking(-1)
            .foregroundColor(.white)
            .frame(minWidth: DesignTokens.Badge.minSize, minHeight: DesignTokens.Badge.minSize)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Badge.cornerRadius)
                    .fill(palette.color(at: index))
            )
    }
}

// MARK: - Element Overlay

/// Renders an accessibility element overlay on the snapshot.
/// Combines the shape highlight with a positioned number badge.
@available(iOS 18.0, *)
public struct ElementOverlay: View {
    public let index: Int
    public let shape: AccessibilityMarker.Shape
    public let palette: ColorPalette

    public init(index: Int, shape: AccessibilityMarker.Shape, palette: ColorPalette) {
        self.index = index
        self.shape = shape
        self.palette = palette
    }

    private typealias Tokens = DesignTokens.Element

    private var fillColor: Color { palette.fillColor(at: index) }
    private var strokeColor: Color { palette.strokeColor(at: index) }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            shapeView
            NumberBadge(index: index, palette: palette)
                .position(badgeCenter)
        }
    }

    // MARK: - Shape Rendering

    @ViewBuilder
    private var shapeView: some View {
        if let bounds = frameBounds {
            roundedRectOverlay(rect: bounds)
        } else if case let .path(path) = shape {
            pathOverlay(path: path.cgPath)
        }
    }

    /// Returns bounds for frame-like shapes (frames and rectangle paths).
    private var frameBounds: CGRect? {
        switch shape {
        case let .frame(rect):
            return rect.insetBy(dx: -Tokens.overlayOutset, dy: -Tokens.overlayOutset)
        case let .path(path):
            let cgPath = path.cgPath
            if BadgePlacement.isRectangle(cgPath) {
                return cgPath.boundingBox.insetBy(dx: -Tokens.overlayOutset, dy: -Tokens.overlayOutset)
            }
            return nil
        }
    }

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

    // MARK: - Badge Placement

    private var badgeCenter: CGPoint {
        if let bounds = frameBounds {
            return BadgePlacement.badgeCenter(in: bounds)
        } else if case let .path(path) = shape {
            return BadgePlacement.badgeCenter(for: path.cgPath)
        }
        return .zero
    }
}

// MARK: - CGPath Shape Wrapper

/// A SwiftUI Shape that wraps a CGPath for rendering.
@available(iOS 18.0, *)
private struct CGPathShape: Shape {
    let path: CGPath

    func path(in rect: CGRect) -> Path {
        let bounds = path.boundingBox
        var transform = CGAffineTransform(translationX: -bounds.minX, y: -bounds.minY)
        if let transformed = path.copy(using: &transform) {
            return Path(transformed)
        }
        return Path(path)
    }
}

// MARK: - Previews

@available(iOS 18.0, *)
#Preview("Number Badges") {
    HStack(spacing: 8) {
        ForEach(0 ..< 8, id: \.self) { index in
            NumberBadge(index: index, palette: .default)
        }
    }
    .padding()
}

@available(iOS 18.0, *)
#Preview("Element Overlays") {
    ZStack {
        Color.gray.opacity(0.2)
        ElementOverlay(
            index: 0,
            shape: .frame(CGRect(x: 50, y: 30, width: 200, height: 50)),
            palette: .default
        )
        ElementOverlay(
            index: 1,
            shape: .frame(CGRect(x: 50, y: 100, width: 200, height: 80)),
            palette: .default
        )
        ElementOverlay(
            index: 2,
            shape: .frame(CGRect(x: 50, y: 200, width: 200, height: 50)),
            palette: .default
        )
        ElementOverlay(
            index: 3,
            shape: .frame(CGRect(x: 50, y: 270, width: 200, height: 50)),
            palette: .default
        )
    }
    .frame(width: 300, height: 350)
}

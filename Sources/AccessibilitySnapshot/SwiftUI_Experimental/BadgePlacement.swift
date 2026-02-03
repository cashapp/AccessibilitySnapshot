import CoreGraphics
import UIKit

/// Calculates optimal badge placement positions within accessibility element shapes.
/// Handles both rectangular frames and arbitrary CGPath shapes with intelligent positioning.
@available(iOS 18.0, *)
enum BadgePlacement {

    /// Returns the best center point for a badge inside an accessibility path.
    /// For arbitrary paths, finds a position near the top-leading corner where the badge fits.
    /// - Parameters:
    ///   - path: The CGPath defining the element's shape
    ///   - badgeSize: The width/height of the badge (assumed square)
    ///   - layoutDirection: The user interface layout direction for leading/trailing resolution
    /// - Returns: The optimal center point, or nil if no placement is feasible
    static func badgeCenter(
        in path: CGPath,
        badgeSize: CGFloat = DesignTokens.Badge.size,
        layoutDirection: UIUserInterfaceLayoutDirection = .leftToRight
    ) -> CGPoint? {
        // Safe effective radius (circumscribed circle of the square badge)
        let halfDiagonal = 0.5 * sqrt(2 * badgeSize * badgeSize)
        let radius = halfDiagonal

        let bounds = path.boundingBoxOfPath
        guard bounds.width >= 2 * radius, bounds.height >= 2 * radius else {
            return nil
        }

        // Try fast path first on top-leading corner
        let primary = resolveCorner(.topLeading, layoutDirection)
        if let point = fastCornerRay(path: path, radius: radius, corner: primary) {
            return point
        }

        // Full comparison across all corners
        var best: (point: CGPoint, score: CGFloat)?

        for logical in Corner.allCases {
            let corner = resolveCorner(logical, layoutDirection)

            let point = fastCornerRay(path: path, radius: radius, corner: corner)
                ?? robustCornerWedge(path: path, radius: radius, corner: corner)

            guard let center = point else { continue }

            let proximity = -normalizedCornerDistance(center, corner, bounds)
            let clearance: CGFloat = circleFits(path: path, center: center, radius: radius * 1.25) ? 1 : 0
            let score = proximity + 0.15 * clearance

            if best == nil || score > best!.score {
                best = (center, score)
            }
        }

        return best?.point
    }

    /// Returns the badge center for a rectangular frame.
    /// Badge is fully inside with its top-leading edge aligned to the element's top-leading edge.
    static func badgeCenter(
        in rect: CGRect,
        layoutDirection: UIUserInterfaceLayoutDirection = .leftToRight
    ) -> CGPoint {
        // Position badge center so top-leading edge aligns with element's top-leading edge
        let halfBadge = DesignTokens.Badge.size / 2

        switch layoutDirection {
        case .rightToLeft:
            return CGPoint(x: rect.maxX - halfBadge, y: rect.minY + halfBadge)
        default:
            return CGPoint(x: rect.minX + halfBadge, y: rect.minY + halfBadge)
        }
    }
}

// MARK: - Corner Logic

private enum Corner: CaseIterable {
    case topLeading, topTrailing, bottomLeading, bottomTrailing
}

private func resolveCorner(
    _ corner: Corner,
    _ direction: UIUserInterfaceLayoutDirection
) -> Corner {
    guard direction == .rightToLeft else { return corner }
    switch corner {
    case .topLeading: return .topTrailing
    case .topTrailing: return .topLeading
    case .bottomLeading: return .bottomTrailing
    case .bottomTrailing: return .bottomLeading
    }
}

private func cornerPoint(_ corner: Corner, _ bounds: CGRect) -> CGPoint {
    switch corner {
    case .topLeading: return CGPoint(x: bounds.minX, y: bounds.minY)
    case .topTrailing: return CGPoint(x: bounds.maxX, y: bounds.minY)
    case .bottomLeading: return CGPoint(x: bounds.minX, y: bounds.maxY)
    case .bottomTrailing: return CGPoint(x: bounds.maxX, y: bounds.maxY)
    }
}

private func insetDirection(_ corner: Corner) -> CGVector {
    switch corner {
    case .topLeading: return CGVector(dx: 1, dy: 1)
    case .topTrailing: return CGVector(dx: -1, dy: 1)
    case .bottomLeading: return CGVector(dx: 1, dy: -1)
    case .bottomTrailing: return CGVector(dx: -1, dy: -1)
    }
}

private func normalizedCornerDistance(_ point: CGPoint, _ corner: Corner, _ bounds: CGRect) -> CGFloat {
    let target = cornerPoint(corner, bounds)
    let dx = point.x - target.x
    let dy = point.y - target.y
    let distance = sqrt(dx * dx + dy * dy)
    return distance / max(1, hypot(bounds.width, bounds.height))
}

// MARK: - Fast Path: Corner Ray + Binary Search

private func fastCornerRay(
    path: CGPath,
    radius: CGFloat,
    corner: Corner
) -> CGPoint? {
    let bounds = path.boundingBoxOfPath
    let origin = cornerPoint(corner, bounds)
    let direction = insetDirection(corner)

    func point(_ t: CGFloat) -> CGPoint {
        CGPoint(
            x: origin.x + direction.dx * t,
            y: origin.y + direction.dy * t
        )
    }

    // Initial inset attempt
    let start = point(radius)
    if circleFits(path: path, center: start, radius: radius) {
        return start
    }

    // Expand a few times to find a valid position
    var lo: CGFloat = radius
    var hi: CGFloat = radius * 2
    let maxT = hypot(bounds.width, bounds.height)

    for _ in 0..<3 {
        if hi > maxT { return nil }
        if circleFits(path: path, center: point(hi), radius: radius) {
            break
        }
        lo = hi
        hi *= 2
    }

    if hi > maxT { return nil }

    // Binary search back toward corner for optimal position
    for _ in 0..<6 {
        let mid = (lo + hi) * 0.5
        if circleFits(path: path, center: point(mid), radius: radius) {
            hi = mid
        } else {
            lo = mid
        }
    }

    return point(hi)
}

// MARK: - Robust Path: Small Wedge Sampling

private func robustCornerWedge(
    path: CGPath,
    radius: CGFloat,
    corner: Corner
) -> CGPoint? {
    let bounds = path.boundingBoxOfPath
    let fx: CGFloat = 0.45
    let fy: CGFloat = 0.45

    let w = bounds.width * fx
    let h = bounds.height * fy

    let region: CGRect
    switch corner {
    case .topLeading:
        region = CGRect(x: bounds.minX, y: bounds.minY, width: w, height: h)
    case .topTrailing:
        region = CGRect(x: bounds.maxX - w, y: bounds.minY, width: w, height: h)
    case .bottomLeading:
        region = CGRect(x: bounds.minX, y: bounds.maxY - h, width: w, height: h)
    case .bottomTrailing:
        region = CGRect(x: bounds.maxX - w, y: bounds.maxY - h, width: w, height: h)
    }

    let grid = 4
    for iy in 0..<grid {
        for ix in 0..<grid {
            let x = region.minX + CGFloat(ix) / CGFloat(grid - 1) * region.width
            let y = region.minY + CGFloat(iy) / CGFloat(grid - 1) * region.height
            let p = CGPoint(x: x, y: y)

            if circleFits(path: path, center: p, radius: radius) {
                return p
            }
        }
    }
    return nil
}

// MARK: - Circle Fit Test

private func circleFits(
    path: CGPath,
    center: CGPoint,
    radius: CGFloat
) -> Bool {
    let bounds = path.boundingBoxOfPath

    // Quick bounds rejection
    if center.x - radius < bounds.minX ||
       center.x + radius > bounds.maxX ||
       center.y - radius < bounds.minY ||
       center.y + radius > bounds.maxY {
        return false
    }

    // Center must be inside path
    if !path.contains(center, using: .winding, transform: .identity) {
        return false
    }

    // Sample 6 points on the circle (every 60°)
    for i in 0..<6 {
        let angle = CGFloat(i) * (.pi / 3)
        let point = CGPoint(
            x: center.x + radius * cos(angle),
            y: center.y + radius * sin(angle)
        )
        if !path.contains(point, using: .winding, transform: .identity) {
            return false
        }
    }

    return true
}

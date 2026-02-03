import CoreGraphics
import UIKit

// MARK: - Public API

/// Returns the best center point for a 16x16 badge inside an accessibility path.
/// Returns nil if no placement is feasible.
public func placeBadge16x16(
    in path: CGPath,
    padding: CGFloat = 2,
    layoutDirection: UIUserInterfaceLayoutDirection = .leftToRight
) -> CGPoint? {
    let badgeSize: CGFloat = 16

    // Safe effective radius (circumscribed circle)
    let halfDiagonal = 0.5 * sqrt(2 * badgeSize * badgeSize) // ≈ 11.314
    let R = halfDiagonal + padding

    let bounds = path.boundingBoxOfPath
    guard bounds.width >= 2 * R, bounds.height >= 2 * R else {
        return nil
    }

    // Try fast path first on top-leading
    let primary = resolveCorner(.topLeading, layoutDirection)
    if let p = fastCornerRay(path: path, radius: R, corner: primary) {
        return p
    }

    // Full comparison across corners
    var best: (point: CGPoint, score: CGFloat)?

    for logical in Corner.allCases {
        let corner = resolveCorner(logical, layoutDirection)

        let point =
            fastCornerRay(path: path, radius: R, corner: corner) ??
            robustCornerWedge(path: path, radius: R, corner: corner)

        guard let center = point else { continue }

        let proximity = -normalizedCornerDistance(center, corner, bounds)
        let clearance: CGFloat =
            circleFits(path: path, center: center, radius: R * 1.25) ? 1 : 0

        let score = proximity + 0.15 * clearance

        if best == nil || score > best!.score {
            best = (center, score)
        }
    }

    return best?.point
}

// MARK: - Corner logic

private enum Corner: CaseIterable {
    case topLeading, topTrailing, bottomLeading, bottomTrailing
}

private func resolveCorner(
    _ c: Corner,
    _ dir: UIUserInterfaceLayoutDirection
) -> Corner {
    guard dir == .rightToLeft else { return c }
    switch c {
    case .topLeading: return .topTrailing
    case .topTrailing: return .topLeading
    case .bottomLeading: return .bottomTrailing
    case .bottomTrailing: return .bottomLeading
    }
}

private func cornerPoint(_ c: Corner, _ b: CGRect) -> CGPoint {
    switch c {
    case .topLeading: return CGPoint(x: b.minX, y: b.minY)
    case .topTrailing: return CGPoint(x: b.maxX, y: b.minY)
    case .bottomLeading: return CGPoint(x: b.minX, y: b.maxY)
    case .bottomTrailing: return CGPoint(x: b.maxX, y: b.maxY)
    }
}

private func insetDirection(_ c: Corner) -> CGVector {
    switch c {
    case .topLeading: return CGVector(dx: 1, dy: 1)
    case .topTrailing: return CGVector(dx: -1, dy: 1)
    case .bottomLeading: return CGVector(dx: 1, dy: -1)
    case .bottomTrailing: return CGVector(dx: -1, dy: -1)
    }
}

private func normalizedCornerDistance(_ p: CGPoint, _ c: Corner, _ b: CGRect) -> CGFloat {
    let t = cornerPoint(c, b)
    let dx = p.x - t.x
    let dy = p.y - t.y
    let d = sqrt(dx * dx + dy * dy)
    return d / max(1, hypot(b.width, b.height))
}

// MARK: - Fast path: corner ray + binary search

private func fastCornerRay(
    path: CGPath,
    radius: CGFloat,
    corner: Corner
) -> CGPoint? {
    let b = path.boundingBoxOfPath
    let origin = cornerPoint(corner, b)
    let dir = insetDirection(corner)

    func point(_ t: CGFloat) -> CGPoint {
        CGPoint(x: origin.x + dir.dx * t,
                y: origin.y + dir.dy * t)
    }

    // Initial inset
    let start = point(radius)
    if circleFits(path: path, center: start, radius: radius) {
        return start
    }

    // Expand a few times only
    var lo: CGFloat = radius
    var hi: CGFloat = radius * 2
    let maxT = hypot(b.width, b.height)

    for _ in 0 ..< 3 {
        if hi > maxT { return nil }
        if circleFits(path: path, center: point(hi), radius: radius) {
            break
        }
        lo = hi
        hi *= 2
    }

    if hi > maxT { return nil }

    // Binary search back toward corner
    for _ in 0 ..< 6 {
        let mid = (lo + hi) * 0.5
        if circleFits(path: path, center: point(mid), radius: radius) {
            hi = mid
        } else {
            lo = mid
        }
    }

    return point(hi)
}

// MARK: - Robust path: small wedge sampling

private func robustCornerWedge(
    path: CGPath,
    radius: CGFloat,
    corner: Corner
) -> CGPoint? {
    let b = path.boundingBoxOfPath
    let fx: CGFloat = 0.45
    let fy: CGFloat = 0.45

    let w = b.width * fx
    let h = b.height * fy

    let region: CGRect
    switch corner {
    case .topLeading:
        region = CGRect(x: b.minX, y: b.minY, width: w, height: h)
    case .topTrailing:
        region = CGRect(x: b.maxX - w, y: b.minY, width: w, height: h)
    case .bottomLeading:
        region = CGRect(x: b.minX, y: b.maxY - h, width: w, height: h)
    case .bottomTrailing:
        region = CGRect(x: b.maxX - w, y: b.maxY - h, width: w, height: h)
    }

    let grid = 4
    for iy in 0 ..< grid {
        for ix in 0 ..< grid {
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

// MARK: - Circle fit test (tight + fast)

private func circleFits(
    path: CGPath,
    center: CGPoint,
    radius: CGFloat
) -> Bool {
    let b = path.boundingBoxOfPath

    // Cheap bounds reject
    if center.x - radius < b.minX ||
        center.x + radius > b.maxX ||
        center.y - radius < b.minY ||
        center.y + radius > b.maxY
    {
        return false
    }

    // Center test
    if !path.contains(center, using: .winding, transform: .identity) {
        return false
    }

    // 6 ring samples (every 60°)
    for i in 0 ..< 6 {
        let a = CGFloat(i) * (.pi / 3)
        let p = CGPoint(
            x: center.x + radius * cos(a),
            y: center.y + radius * sin(a)
        )
        if !path.contains(p, using: .winding, transform: .identity) {
            return false
        }
    }
    return true
}

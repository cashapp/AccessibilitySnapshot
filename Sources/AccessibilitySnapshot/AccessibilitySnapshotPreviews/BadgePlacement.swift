import CoreGraphics

/// Calculates badge placement positions for accessibility element overlays.
/// Uses tiered checking for paths: corners first, then edge scanning, with early returns.
@available(iOS 16.0, *)
enum BadgePlacement {
    /// Corner positions for badge placement, in priority order.
    private enum Corner {
        case topLeading
        case topTrailing
        case bottomLeading
        case bottomTrailing
    }

    /// Returns the badge center for a rectangular bounds (frame-based shapes).
    /// Badge is positioned at the top-leading corner, fully inside the bounds.
    /// Time complexity: O(1)
    static func badgeCenter(in rect: CGRect) -> CGPoint {
        let halfBadge = DesignTokens.Badge.size / 2
        return cornerPoint(in: rect, corner: .topLeading, halfBadge: halfBadge)
    }

    /// Returns the badge center for a path-based shape.
    /// Uses tiered checking with early returns for performance.
    /// Time complexity: O(1) for rectangles, O(n) best case, O(n*k) worst case
    static func badgeCenter(for path: CGPath) -> CGPoint {
        let bounds = path.boundingBox

        // Tier 0: Detect pure rectangles and use O(1) placement
        if isRectangle(path) {
            return badgeCenter(in: bounds)
        }

        let halfBadge = DesignTokens.Badge.size / 2

        // Tier 1: Check top-leading corner (most paths pass here)
        let topLeading = cornerPoint(in: bounds, corner: .topLeading, halfBadge: halfBadge)
        if path.contains(topLeading) {
            return topLeading
        }

        // Tier 2: Check top-trailing corner
        let topTrailing = cornerPoint(in: bounds, corner: .topTrailing, halfBadge: halfBadge)
        if path.contains(topTrailing) {
            return topTrailing
        }

        // Tier 3: Scan top edge to find first interior point
        if let edgePoint = scanTopEdge(of: path, bounds: bounds, halfBadge: halfBadge) {
            return edgePoint
        }

        // Tier 4: Fallback to bounding box top-leading (original behavior)
        return topLeading
    }

    /// Maximum corner radius to treat a rounded rect as a simple rectangle.
    private static let maxCornerRadius: CGFloat = 8.0

    /// Detects if a path is a rectangle or rounded rectangle with small corners.
    /// This allows us to skip containment checks and use O(1) placement.
    static func isRectangle(_ path: CGPath) -> Bool {
        let bounds = path.boundingBox
        var linePoints: [CGPoint] = []
        var curveCount = 0
        var maxCurveDeviation: CGFloat = 0

        path.applyWithBlock { element in
            let type = element.pointee.type
            let points = element.pointee.points

            switch type {
            case .moveToPoint, .addLineToPoint:
                linePoints.append(points[0])

            case .addQuadCurveToPoint:
                // Quad curve: points[0] = control, points[1] = end
                curveCount += 1
                // Measure how far control point deviates (approximates corner radius)
                let control = points[0]
                let end = points[1]
                let deviation = max(
                    abs(control.x - end.x),
                    abs(control.y - end.y)
                )
                maxCurveDeviation = max(maxCurveDeviation, deviation)

            case .addCurveToPoint:
                // Cubic curve: points[0..1] = controls, points[2] = end
                curveCount += 1
                let control1 = points[0]
                let control2 = points[1]
                let end = points[2]
                let deviation = max(
                    abs(control1.x - end.x),
                    abs(control1.y - end.y),
                    abs(control2.x - end.x),
                    abs(control2.y - end.y)
                )
                maxCurveDeviation = max(maxCurveDeviation, deviation)

            case .closeSubpath:
                break

            @unknown default:
                break
            }
        }

        // Pure rectangle: 4 vertices, no curves
        if curveCount == 0 && linePoints.count == 4 {
            return allPointsAtCorners(linePoints, bounds: bounds)
        }

        // Rounded rectangle: has curves but corners are small (< 8pt)
        if curveCount > 0 && maxCurveDeviation <= maxCornerRadius {
            // Verify points are near bounding box edges
            return allPointsNearEdges(linePoints, bounds: bounds, tolerance: maxCornerRadius)
        }

        return false
    }

    /// Checks if all points are at the bounding box corners.
    private static func allPointsAtCorners(_ points: [CGPoint], bounds: CGRect) -> Bool {
        let corners: [CGPoint] = [
            CGPoint(x: bounds.minX, y: bounds.minY),
            CGPoint(x: bounds.maxX, y: bounds.minY),
            CGPoint(x: bounds.maxX, y: bounds.maxY),
            CGPoint(x: bounds.minX, y: bounds.maxY),
        ]

        for point in points {
            var matchesCorner = false
            let px = Int(point.x)
            let py = Int(point.y)
            for corner in corners {
                if px == Int(corner.x) && py == Int(corner.y) {
                    matchesCorner = true
                    break
                }
            }
            if !matchesCorner {
                return false
            }
        }
        return true
    }

    /// Checks if all points are near the bounding box edges (within tolerance).
    private static func allPointsNearEdges(_ points: [CGPoint], bounds: CGRect, tolerance: CGFloat) -> Bool {
        for point in points {
            let nearLeft = abs(point.x - bounds.minX) <= tolerance
            let nearRight = abs(point.x - bounds.maxX) <= tolerance
            let nearTop = abs(point.y - bounds.minY) <= tolerance
            let nearBottom = abs(point.y - bounds.maxY) <= tolerance

            // Point should be near at least one edge on each axis
            let nearVerticalEdge = nearLeft || nearRight
            let nearHorizontalEdge = nearTop || nearBottom

            if !nearVerticalEdge && !nearHorizontalEdge {
                return false
            }
        }
        return true
    }

    // MARK: - Private Helpers

    /// Returns the badge center point for a specific corner of the bounds.
    private static func cornerPoint(
        in rect: CGRect,
        corner: Corner,
        halfBadge: CGFloat
    ) -> CGPoint {
        let nudge: CGFloat = 0.5

        switch corner {
        case .topLeading:
            return CGPoint(x: rect.minX + halfBadge - nudge, y: rect.minY + halfBadge - nudge)
        case .topTrailing:
            return CGPoint(x: rect.maxX - halfBadge + nudge, y: rect.minY + halfBadge - nudge)
        case .bottomLeading:
            return CGPoint(x: rect.minX + halfBadge - nudge, y: rect.maxY - halfBadge + nudge)
        case .bottomTrailing:
            return CGPoint(x: rect.maxX - halfBadge + nudge, y: rect.maxY - halfBadge + nudge)
        }
    }

    /// Scans the top edge of the bounding box to find the first point inside the path.
    /// Uses sparse sampling for performance (5 sample points).
    /// Returns nil if no interior point found on top edge.
    private static func scanTopEdge(
        of path: CGPath,
        bounds: CGRect,
        halfBadge: CGFloat
    ) -> CGPoint? {
        let sampleCount = 5
        let y = bounds.minY + halfBadge
        let startX = bounds.minX + halfBadge
        let endX = bounds.maxX - halfBadge
        let step = (endX - startX) / CGFloat(sampleCount - 1)

        for i in 0 ..< sampleCount {
            let x = startX + (step * CGFloat(i))
            let point = CGPoint(x: x, y: y)
            if path.contains(point) {
                return point
            }
        }

        return nil
    }
}


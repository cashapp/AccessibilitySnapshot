import CoreGraphics
import UIKit

/// Calculates badge placement positions for accessibility element overlays.
/// Uses bounding box positioning for consistent, predictable results.
@available(iOS 18.0, *)
enum BadgePlacement {
    /// Returns the badge center for a rectangular bounds.
    /// Badge is positioned at the top-leading corner, fully inside the bounds.
    static func badgeCenter(
        in rect: CGRect,
        layoutDirection: UIUserInterfaceLayoutDirection = .leftToRight
    ) -> CGPoint {
        let halfBadge = DesignTokens.Badge.size / 2

        switch layoutDirection {
        case .rightToLeft:
            return CGPoint(x: rect.maxX - halfBadge, y: rect.minY + halfBadge)
        default:
            return CGPoint(x: rect.minX + halfBadge, y: rect.minY + halfBadge)
        }
    }
}

import AccessibilitySnapshotModel
import UIKit

// MARK: - UIAccessibilityTraits Codable

#if compiler(>=6.0)
    extension UIAccessibilityTraits: @retroactive Codable {}
#else
    extension UIAccessibilityTraits: Codable {}
#endif

public extension UIAccessibilityTraits {
    init(from decoder: Decoder) throws {
        self = try AccessibilityTraits(from: decoder).uiAccessibilityTraits
    }

    func encode(to encoder: Encoder) throws {
        try AccessibilityTraits(self).encode(to: encoder)
    }
}

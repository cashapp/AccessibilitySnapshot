import Foundation

/// The rendering engine used to generate accessibility snapshots.
public enum AccessibilityRenderer {
    /// Uses the original UIKit-based renderer.
    case uikit

    /// Uses the new SwiftUI-based renderer.
    case swiftui

    /// The subdirectory name for reference images, if any.
    /// UIKit uses the root directory (no subdirectory) for backwards compatibility.
    /// SwiftUI uses a "SwiftUI" subdirectory.
    var referenceImageSubdirectory: String? {
        switch self {
        case .uikit:
            return nil
        case .swiftui:
            return "SwiftUI"
        }
    }
}

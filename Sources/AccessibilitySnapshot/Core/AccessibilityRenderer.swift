import Foundation

/// The rendering engine used to generate accessibility snapshots.
public enum AccessibilityRenderer {
    /// Uses the original UIKit-based renderer.
    case uikit

    /// Uses the new SwiftUI-based renderer.
    case swiftui

    /// The default renderer used when none is specified.
    /// Change this to switch all tests between UIKit and SwiftUI rendering.
    public static let `default`: AccessibilityRenderer = .uikit
}

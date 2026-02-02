import Foundation

/// The layout engine used to render accessibility snapshot overlays and legends.
public enum LayoutEngine {
    /// Uses the original UIKit-based layout engine.
    case uikit

    /// Uses the new SwiftUI-based layout engine.
    case swiftui

    /// The default layout engine used when none is specified.
    public static let `default`: LayoutEngine = .uikit
}

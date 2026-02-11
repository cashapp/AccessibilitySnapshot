import AccessibilitySnapshotCore
import SwiftUI

/// Adds accessibility preview functionality for Xcode Previews.
@available(iOS 16.0, *)
public extension View {
    /// Wraps the view in an accessibility preview with scrollable legend for Xcode Previews.
    ///
    /// - Parameters:
    ///   - configuration: The configuration for snapshot rendering. Defaults to monochrome.
    ///   - palette: The color palette for accessibility markers. Defaults to the standard palette.
    ///   - size: The size to render the view. Defaults to screen size.
    func accessibilityPreview(
        configuration: AccessibilitySnapshotConfiguration = .init(viewRenderingMode: .drawHierarchyInRect),
        palette: AccessibilityColorPalette = .default,
        size: CGSize? = nil
    ) -> some View {
        ScrollView {
            SwiftUIAccessibilitySnapshotView(
                content: { self },
                configuration: configuration,
                palette: palette,
                renderSize: size
            )
        }
        .background(Color(UIColor.systemGray6))
    }
}

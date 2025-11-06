import UIKit

/// Configuration struct that centralizes all accessibility snapshot settings.
/// 
/// This struct organizes configuration options into logical groups:
/// - `snapshot`: Controls how the view is rendered to an image
/// - `overlay`: Controls the visual markers and indicators overlaid on the snapshot
/// - `legend`: Controls the accessibility information displayed alongside the snapshot
public struct AccessibilitySnapshotConfiguration {
    
    /// Configuration for how the view snapshot is rendered.
    public struct Snapshot {
        
        /// The preferred strategy for converting a view to an image.
        public let viewRenderingMode: ViewRenderingMode
        
        /// Whether or not the snapshot of the `view` should be monochrome or full color. Using a
        /// monochrome snapshot makes it more clear where the highlighted elements are, but may make it difficult to
        /// read certain views. Defaults to `.monochrome`.
        public let colorMode: ColorRenderingMode
        
        init(viewRenderingMode: ViewRenderingMode, colorMode: ColorRenderingMode = .monochrome) {
            self.viewRenderingMode = viewRenderingMode
            self.colorMode = colorMode
        }
    }
    
    /// Configuration for visual markers and indicators overlaid on the snapshot.
    public struct Overlay {
        /// An array of colors to use for the highlighted regions. These colors will be used in
        /// order, repeating through the array as necessary.
        ///  Defaults to `MarkerColors.defaultColors`.
        public let colors: [UIColor]
        
        /// Controls when to show indicators for elements' accessibility activation points.
        ///  Defaults to `.whenOverridden`.
        public let activationPointDisplay: AccessibilityContentDisplayMode
        
        init(colors: [UIColor] = MarkerColors.defaultColors,
             activationPointDisplay: AccessibilityContentDisplayMode = .whenOverridden
        )  {
            self.colors = colors.isEmpty ? MarkerColors.defaultColors : colors
            self.activationPointDisplay = activationPointDisplay
        }
    }
    
    /// Configuration for the accessibility information displayed alongside the snapshot.
    public struct Legend {
        /// Controls when to show elements' accessibility user input labels (used by Voice Control).
        ///  Defaults to `.whenOverridden`.
        public let includesUserInputLabels: AccessibilityContentDisplayMode

        /// Controls when to show elements' accessibility rotors and their contents.
        ///  Defaults to `.whenOverridden`.
        public let includesCustomRotors: AccessibilityContentDisplayMode

        init(includesUserInputLabels: AccessibilityContentDisplayMode = .whenOverridden, includesCustomRotors: AccessibilityContentDisplayMode = .whenOverridden) {
            self.includesUserInputLabels = includesUserInputLabels
            self.includesCustomRotors = includesCustomRotors
        }
    }
    
    public let snapshot: Snapshot
    public let overlay: Overlay
    public let legend: Legend
    
    /// Creates a new accessibility snapshot configuration.
    ///
    /// - Parameters:
    ///   - viewRenderingMode: The preferred strategy for converting a view to an image.
    ///   - colorRenderingMode: Whether the snapshot should be monochrome or full color. Defaults to `.monochrome`.
    ///   - overlayColors: Colors to use for highlighted regions. Defaults to `MarkerColors.defaultColors`.
    ///   - activationPointDisplay: When to show accessibility activation point indicators. Defaults to `.whenOverridden`.
    ///   - includesInputLabels: When to show accessibility user input labels. Defaults to `.whenOverridden`.
    ///   - includesCustomRotors: When to show accessibility custom rotors and their contents. Defaults to `.whenOverridden`.

    public init(viewRenderingMode: ViewRenderingMode,
                colorRenderingMode: ColorRenderingMode = .monochrome,
                overlayColors: [UIColor] = MarkerColors.defaultColors,
                activationPointDisplay: AccessibilityContentDisplayMode = .whenOverridden,
                includesInputLabels: AccessibilityContentDisplayMode = .whenOverridden,
                includesCustomRotors: AccessibilityContentDisplayMode = .whenOverridden
                ) {
        
        self.snapshot = Snapshot(viewRenderingMode:viewRenderingMode, colorMode: colorRenderingMode)
        self.overlay = Overlay(colors: overlayColors.isEmpty ? MarkerColors.defaultColors : overlayColors, activationPointDisplay: activationPointDisplay)
        self.legend = Legend(includesUserInputLabels: includesInputLabels, includesCustomRotors: includesCustomRotors)
    }
}

public enum ViewRenderingMode {

    /// Render the view's layer in a `CGContext` using the `render(in:)` method.
    case renderLayerInContext

    /// Draw the view's hierarchy after screen updates using the `drawHierarchy(in:afterScreenUpdates:)` method.
    case drawHierarchyInRect

}

public enum ColorRenderingMode {
    /// Render the test view as monochrome.
    case monochrome

    /// Render the test view in full color.
    case fullColor
}

public enum AccessibilityContentDisplayMode {
    /// Always show the accessibility content.
    case always

    /// Only include the accessibility content for an element when it
    /// differs from the default content for that element.
    case whenOverridden

    /// Never show the accessibility content.
    case never
}

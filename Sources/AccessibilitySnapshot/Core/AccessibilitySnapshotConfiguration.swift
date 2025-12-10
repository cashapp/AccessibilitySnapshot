import UIKit
#if SWIFT_PACKAGE
import AccessibilitySnapshotParser
#endif

/// Configuration struct that centralizes all accessibility snapshot settings.
///
/// Settings are organized by feature:
/// - `rendering`: Controls how the view is rendered to an image
/// - `rotors`: Controls custom rotor display
/// - `markerColors`: Colors for highlighted regions
/// - `activationPointDisplayMode`: Controls activation point indicator display
/// - `inputLabelDisplayMode`: Controls user input label display (for Voice Control)
public struct AccessibilitySnapshotConfiguration {

    // MARK: - Nested Configuration Types

    /// Configuration for how the view snapshot is rendered.
    public struct Rendering {
        /// The preferred strategy for converting a view to an image.
        public let renderMode: ViewRenderingMode

        /// Whether the snapshot should be monochrome or full color. Defaults to `.monochrome`.
        public let colorMode: ColorRenderingMode

        public init(renderMode: ViewRenderingMode, colorMode: ColorRenderingMode = .monochrome) {
            self.renderMode = renderMode
            self.colorMode = colorMode
        }
    }

    /// Configuration for custom rotor display.
    public struct Rotors {
        /// Controls when to show elements' accessibility rotors and their contents. Defaults to `.whenOverridden`.
        public let displayMode: AccessibilityContentDisplayMode

        /// The maximum number of rotor results to collect in each direction (forward and backward). Defaults to `10`.
        public let resultLimit: Int

        public init(
            displayMode: AccessibilityContentDisplayMode = .whenOverridden,
            resultLimit: Int = AccessibilityMarker.defaultRotorResultLimit
        ) {
            self.displayMode = displayMode
            self.resultLimit = resultLimit
        }
    }

    // MARK: - Properties

    /// Configuration for how the view is rendered to an image.
    public let rendering: Rendering

    /// Configuration for custom rotor display.
    public let rotors: Rotors

    /// Colors to use for highlighted regions. These colors will be used in order,
    /// repeating through the array as necessary. Defaults to `MarkerColors.defaultColors`.
    public let markerColors: [UIColor]

    /// Controls when to show indicators for elements' accessibility activation points. Defaults to `.whenOverridden`.
    public let activationPointDisplayMode: AccessibilityContentDisplayMode

    /// Controls when to show elements' accessibility user input labels (used by Voice Control). Defaults to `.whenOverridden`.
    public let inputLabelDisplayMode: AccessibilityContentDisplayMode

    // MARK: - Initialization

    /// Creates a new accessibility snapshot configuration.
    ///
    /// - Parameters:
    ///   - viewRenderingMode: The preferred strategy for converting a view to an image.
    ///   - colorRenderingMode: Whether the snapshot should be monochrome or full color. Defaults to `.monochrome`.
    ///   - overlayColors: Colors to use for highlighted regions. Defaults to `MarkerColors.defaultColors`.
    ///   - activationPointDisplay: When to show accessibility activation point indicators. Defaults to `.whenOverridden`.
    ///   - includesInputLabels: When to show accessibility user input labels. Defaults to `.whenOverridden`.
    ///   - includesCustomRotors: When to show accessibility custom rotors and their contents. Defaults to `.whenOverridden`.
    ///   - rotorResultLimit: Maximum number of rotor results to collect in each direction. Defaults to `10`.
    public init(
        viewRenderingMode: ViewRenderingMode,
        colorRenderingMode: ColorRenderingMode = .monochrome,
        overlayColors: [UIColor] = MarkerColors.defaultColors,
        activationPointDisplay: AccessibilityContentDisplayMode = .whenOverridden,
        includesInputLabels: AccessibilityContentDisplayMode = .whenOverridden,
        includesCustomRotors: AccessibilityContentDisplayMode = .whenOverridden,
        rotorResultLimit: Int = AccessibilityMarker.defaultRotorResultLimit
    ) {
        self.rendering = Rendering(renderMode: viewRenderingMode, colorMode: colorRenderingMode)
        self.rotors = Rotors(displayMode: includesCustomRotors, resultLimit: rotorResultLimit)
        self.markerColors = overlayColors.isEmpty ? MarkerColors.defaultColors : overlayColors
        self.activationPointDisplayMode = activationPointDisplay
        self.inputLabelDisplayMode = includesInputLabels
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

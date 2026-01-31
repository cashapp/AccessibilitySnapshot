import CoreGraphics

/// Shared layout metrics for legend rendering.
/// These values are used by both UIKit and SwiftUI implementations to ensure consistent layouts.
public enum LegendLayoutMetrics {
    // MARK: - Legend Container Layout

    /// Inset from all edges of the legend container area.
    public static let legendInset: CGFloat = 16

    /// Horizontal spacing between legend columns.
    public static let legendHorizontalSpacing: CGFloat = 16

    /// Vertical spacing between legend items within a column.
    public static let legendVerticalSpacing: CGFloat = 16

    // MARK: - Legend Item Layout

    /// Minimum width for a legend column.
    public static let minimumLegendWidth: CGFloat = 284

    /// Size of the colored marker square (width and height).
    public static let markerSize: CGFloat = 14

    /// Horizontal spacing between the marker and the label content.
    public static let markerToLabelSpacing: CGFloat = 16

    /// Vertical spacing between sections within a legend item (description, hint, actions, etc.).
    public static let interSectionSpacing: CGFloat = 4

    // MARK: - Typography

    /// Font size for description text.
    public static let descriptionFontSize: CGFloat = 12

    /// Font size for hint text.
    public static let hintFontSize: CGFloat = 12

    // MARK: - Derived Values

    /// Minimum total width needed to display legend (column width + left/right insets).
    public static var minimumWidth: CGFloat {
        minimumLegendWidth + legendInset * 2
    }

    /// Available width for text content within a legend item.
    public static var textContentWidth: CGFloat {
        minimumLegendWidth - markerSize - markerToLabelSpacing
    }
}

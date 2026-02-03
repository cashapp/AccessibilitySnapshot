import AccessibilitySnapshotCore
import SwiftUI

/// Consolidated design tokens for SwiftUI accessibility snapshot rendering.
/// These values ensure consistent visual styling across all SwiftUI views.
@available(iOS 18.0, *)
enum DesignTokens {
    // MARK: - Colors

    public enum Colors {
        /// Standard text color for descriptions and labels.
        public static let primaryText = Color.black

        /// Secondary text color for hints and less prominent content.
        public static let secondaryText = Color(white: 0.4)

        /// Text color used in pill-shaped labels.
        public static let pillText = Color(white: 0.15)

        /// Background color for pill-shaped labels.
        public static let pillBackground = Color(white: 0.85)
    }

    // MARK: - Typography

    public enum Typography {
        /// Font for element descriptions.
        public static let description = Font.system(size: LegendLayoutMetrics.descriptionFontSize)

        /// Font for hint text.
        public static let hint = Font.system(size: LegendLayoutMetrics.hintFontSize).italic()

        /// Font for custom actions, content, and rotors.
        public static let secondary = Font.system(size: 12)

        /// Bold variant for important content.
        public static let secondaryBold = Font.system(size: 12, weight: .bold)

        /// Font for user input label pills.
        public static let pill = Font.system(size: 12)

        /// Font for trait pills (smaller).
        public static let traitPill = Font.system(size: 10)

        /// Font for overlay element numbers.
        public static let overlayNumber = Font.system(size: 12, weight: .semibold)

        /// Font for legend element numbers.
        public static let legendNumber = Font.system(size: 8, weight: .semibold)

        /// Font for badge numbers (overlay badges with background).
        public static let badgeNumber = Font.system(size: 10, weight: .bold)
    }

    // MARK: - Element View

    public enum Element {
        /// Stroke width for element outlines.
        public static let strokeWidth: CGFloat = 1

        /// Corner radius for overlay elements.
        public static let overlayCornerRadius: CGFloat = 8

        /// Corner radius for legend markers.
        public static let legendCornerRadius: CGFloat = 3

        /// Padding around the number badge in overlays.
        public static let badgePadding: CGFloat = 4

        /// Offset to center the badge number visually within the padding area.
        public static let badgeOffset: CGFloat = 6
    }

    // MARK: - Badge Placement

    public enum Badge {
        /// Size of the badge (width and height) for placement calculations.
        public static let size: CGFloat = 16

        /// Corner radius for the badge background.
        public static let cornerRadius: CGFloat = 4

        /// Minimum width/height for the badge.
        public static let minSize: CGFloat = 16
    }

    // MARK: - Activation Point

    public enum ActivationPoint {
        /// Size of the crosshairs indicator.
        public static let size: CGFloat = 16
    }

    // MARK: - Pills (User Input Labels)

    public enum Pill {
        /// Horizontal padding inside pills.
        public static let horizontalPadding: CGFloat = 6

        /// Vertical padding inside pills.
        public static let verticalPadding: CGFloat = 2

        /// Corner radius for pills.
        public static let cornerRadius: CGFloat = 6

        /// Horizontal spacing between pills.
        public static let horizontalSpacing: CGFloat = 4

        /// Vertical spacing between pill rows.
        public static let verticalSpacing: CGFloat = 4
    }

    // MARK: - Trait Pills

    public enum TraitPill {
        /// Horizontal padding inside trait pills.
        public static let horizontalPadding: CGFloat = 4

        /// Vertical padding inside trait pills.
        public static let verticalPadding: CGFloat = 1

        /// Corner radius for trait pills.
        public static let cornerRadius: CGFloat = 4

        /// Spacing between icon and text in trait pills.
        public static let iconTextSpacing: CGFloat = 2

        /// Horizontal spacing between trait pills.
        public static let horizontalSpacing: CGFloat = 4

        /// Vertical spacing between trait pill rows.
        public static let verticalSpacing: CGFloat = 4
    }

    // MARK: - Custom Content (Actions, Content, Rotors)

    public enum CustomContent {
        /// Vertical spacing between items in custom content sections.
        public static let verticalSpacing: CGFloat = 2

        /// Indentation for nested items.
        public static let indent: CGFloat = 12
    }
}

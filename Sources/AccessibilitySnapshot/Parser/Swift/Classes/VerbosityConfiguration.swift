import Foundation

/// Configuration for controlling what information is included in VoiceOver descriptions.
///
/// This mirrors the verbosity settings available in iOS at:
/// Settings > Accessibility > VoiceOver > Verbosity
///
/// ## Usage
///
/// Use the built-in presets for common configurations:
/// ```swift
/// element.voiceOverDescription(verbosity: .minimal)  // Just the label
/// element.voiceOverDescription(verbosity: .verbose)  // Everything (default)
/// ```
///
/// Or customize individual settings:
/// ```swift
/// var config = VerbosityConfiguration.verbose
/// config.includesHints = false
/// element.voiceOverDescription(verbosity: config)
/// ```
public struct VerbosityConfiguration: Equatable {
    // MARK: - Trait Position

    /// Controls where trait announcements (Button, Link, etc.) appear relative to the description.
    ///
    /// This mirrors iOS 18.4's Settings > Accessibility > VoiceOver > Verbosity > Controls setting.
    public enum TraitPosition: Equatable {
        /// Announce trait before the label: "Button. Submit"
        case before

        /// Announce trait after the label: "Submit. Button." (default VoiceOver behavior)
        case after

        /// Don't announce traits at all: "Submit"
        case none
    }

    // MARK: - Properties

    /// Include trait announcements (Button, Link, Heading, Image, etc.).
    ///
    /// When `false`, trait specifiers are omitted regardless of `traitPosition`.
    /// Corresponds to iOS trait-related verbosity settings.
    public var includesTraits: Bool

    /// Controls where trait announcements appear relative to the description.
    ///
    /// Only applies when `includesTraits` is `true`.
    /// - `.before`: "Button. Submit"
    /// - `.after`: "Submit. Button." (default)
    /// - `.none`: Equivalent to `includesTraits = false`
    public var traitPosition: TraitPosition

    /// Include usage hints (e.g., "Double tap to activate", "Swipe up or down to adjust").
    ///
    /// Corresponds to iOS Settings > Accessibility > VoiceOver > Verbosity > Speak Hints.
    public var includesHints: Bool

    /// Include container context announcements (e.g., "1 of 5", "List Start", "Landmark").
    ///
    /// This includes:
    /// - Series position: "1 of 5"
    /// - Tab position: "Tab. 2 of 4"
    /// - List boundaries: "List Start", "List End"
    /// - Landmark boundaries: "Landmark", "End"
    public var includesContainerContext: Bool

    /// Include data table context (row/column headers, position, spans).
    ///
    /// Corresponds to iOS Settings > Accessibility > VoiceOver > Verbosity > Table Headers
    /// and Row & Column Numbers.
    ///
    /// This includes:
    /// - Row and column headers
    /// - Row and column position: "Row 2. Column 3."
    /// - Span information: "Spans 2 rows."
    public var includesTableContext: Bool

    /// Include the accessibility value after the label.
    ///
    /// When `true`, values are announced: "Volume: 50%"
    /// When `false`, only the label is announced: "Volume"
    public var includesValue: Bool

    /// Include high-importance custom content in the description.
    ///
    /// Per WWDC21, high-importance `AXCustomContent` values appear in the main
    /// VoiceOver announcement. For example: "Bailey, beagle, three years. Image."
    ///
    /// When `false`, custom content is only available via the More Content rotor.
    public var includesCustomContent: Bool

    // MARK: - Initialization

    /// Creates a verbosity configuration with the specified settings.
    public init(
        includesTraits: Bool = true,
        traitPosition: TraitPosition = .after,
        includesHints: Bool = true,
        includesContainerContext: Bool = true,
        includesTableContext: Bool = true,
        includesValue: Bool = true,
        includesCustomContent: Bool = true
    ) {
        self.includesTraits = includesTraits
        self.traitPosition = traitPosition
        self.includesHints = includesHints
        self.includesContainerContext = includesContainerContext
        self.includesTableContext = includesTableContext
        self.includesValue = includesValue
        self.includesCustomContent = includesCustomContent
    }

    // MARK: - Presets

    /// Minimal verbosity: only the label is announced.
    ///
    /// All additional context, traits, hints, and values are omitted.
    /// Use this to test the most basic VoiceOver experience.
    public static let minimal = VerbosityConfiguration(
        includesTraits: false,
        traitPosition: .none,
        includesHints: false,
        includesContainerContext: false,
        includesTableContext: false,
        includesValue: false,
        includesCustomContent: false
    )

    /// Verbose: all information is included (default).
    ///
    /// This matches the default VoiceOver behavior where all context,
    /// traits, hints, and values are announced.
    public static let verbose = VerbosityConfiguration(
        includesTraits: true,
        traitPosition: .after,
        includesHints: true,
        includesContainerContext: true,
        includesTableContext: true,
        includesValue: true,
        includesCustomContent: true
    )
}

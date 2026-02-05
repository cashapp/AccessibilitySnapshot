import UIKit

/// A type alias for backwards compatibility.
public typealias AccessibilityMarker = AccessibilityElement

public struct AccessibilityElement: Equatable, Codable {
    /// Default number of rotor results to collect in each direction.
    public static let defaultRotorResultLimit: Int = 10

    // MARK: - Public Types

    /// Represents the container context in which an accessibility element is contained.
    ///
    /// This enum captures all the information VoiceOver needs to announce container-specific
    /// context, such as position in a series, table cell location, or list boundaries.
    ///
    /// `ContainerContext` is designed to be:
    /// - **Codable**: Can be serialized to JSON for storage/transmission
    /// - **Equatable**: Can be compared for equality
    /// - **Reference-free**: Contains only primitive data, no object references
    public enum ContainerContext: Equatable, Codable {
        /// Element is part of a series. Reads as "`index` of `count`."
        case series(index: Int, count: Int)

        /// Element is a tab bar item. Reads as "Tab. `index` of `count`."
        ///
        /// Used for items in a `UITabBar`.
        case tabBarItem(index: Int, count: Int)

        /// Element is in a tab bar container. Reads as "Tab. `index` of `count`."
        ///
        /// Used for containers with the `.tabBar` accessibility trait.
        case tab(index: Int, count: Int)

        /// Element is a cell in a data table.
        ///
        /// - `row`: Row index (0-based), or `NSNotFound` if not applicable
        /// - `column`: Column index (0-based), or `NSNotFound` if not applicable
        /// - `rowSpan`: Number of rows the cell spans
        /// - `columnSpan`: Number of columns the cell spans
        /// - `isFirstInRow`: Whether this is the first cell VoiceOver reads in its row
        /// - `rowHeaders`: Pre-formatted header strings for the row
        /// - `columnHeaders`: Pre-formatted header strings for the column
        case dataTableCell(
            row: Int,
            column: Int,
            rowSpan: Int,
            columnSpan: Int,
            isFirstInRow: Bool,
            rowHeaders: [String],
            columnHeaders: [String]
        )

        /// Element is the first element in a list.
        case listStart

        /// Element is the last element in a list.
        case listEnd

        /// Element is the first element in a landmark container.
        case landmarkStart

        /// Element is the last element in a landmark container.
        case landmarkEnd
    }

    public enum Shape: Equatable {
        /// Accessibility frame, in the coordinate space of the view being snapshotted.
        case frame(CGRect)

        /// Accessibility path, in the coordinate space of the view being snapshotted.
        case path(UIBezierPath)
    }

    public struct CustomRotor: Equatable, CustomStringConvertible, Codable {
        public struct ResultMarker: Equatable, CustomStringConvertible, Codable {
            public let elementDescription: String
            public let rangeDescription: String?
            public let shape: Shape?

            public var description: String {
                guard let rangeDescription else {
                    return elementDescription
                }
                return "\(elementDescription) \(rangeDescription)"
            }
        }

        public var name: String
        public var resultMarkers: [AccessibilityElement.CustomRotor.ResultMarker] = []
        public let limit: UIAccessibilityCustomRotor.CollectedRotorResults.Limit

        init?(from: UIAccessibilityCustomRotor, parentElement: NSObject, root: UIView, resultLimit: Int) {
            guard from.isKnownRotorType else { return nil }
            name = from.displayName(locale: parentElement.accessibilityLanguage)
            let collected = from.collectAllResults(nextLimit: resultLimit, previousLimit: resultLimit)
            limit = collected.limit
            resultMarkers = collected.results.compactMap { result in
                guard let element = result.targetElement as? NSObject else { return nil }
                // Rotor results can point to any element in the hierarchy, so we don't know
                // their actual container context. Pass nil to avoid using the wrong context.
                var description = element.buildAccessibilityDescription(context: nil).description
                var shape: Shape? = AccessibilityHierarchyParser.accessibilityShape(for: element, in: root)

                if let range = result.targetRange,
                   let input = element as? UITextInput
                {
                    if let path = input.accessibilityPath(for: range) {
                        let converted = root.convert(path, from: input as? UIView)
                        shape = .path(converted)
                    }
                    if let substring = input.text(in: range) {
                        description = substring
                    }
                    return ResultMarker(elementDescription: description, rangeDescription: range.formatted(in: input), shape: shape)
                }
                return ResultMarker(elementDescription: description, rangeDescription: nil, shape: shape)
            }
        }

        public var description: String {
            return name + ": " + resultMarkers.map { $0.description }.joined(separator: "\n")
        }
    }

    public struct CustomContent: Codable, Equatable {
        public var label: String
        public var value: String
        public var isImportant: Bool

        public init(label: String, value: String, isImportant: Bool) {
            self.label = label
            self.value = value
            self.isImportant = isImportant
        }

        @available(iOS 14.0, *)
        init(from: AXCustomContent) {
            label = from.label
            value = from.value
            isImportant = from.importance == .high
        }
    }

    public struct CustomAction: Equatable, Codable {
        public var name: String
        public var image: UIImage?

        init(name: String, image: UIImage?) {
            self.name = name
            self.image = image
        }

        @available(iOS 14.0, *)
        init(from: UIAccessibilityCustomAction) {
            name = from.name
            image = from.image
        }

        private enum CodingKeys: String, CodingKey {
            case name
            case imageData
            case imageScale
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)

            if let imageData = try container.decodeIfPresent(Data.self, forKey: .imageData) {
                let scale = try container.decodeIfPresent(CGFloat.self, forKey: .imageScale) ?? 1.0
                image = UIImage(data: imageData, scale: scale)
            } else {
                image = nil
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)

            if let image = image, let pngData = image.pngData() {
                try container.encode(pngData, forKey: .imageData)
                try container.encode(image.scale, forKey: .imageScale)
            }
        }
    }

    // MARK: - Public Properties

    /// The description of the accessibility element that will be read by VoiceOver when the element is brought into
    /// focus.
    public let description: String

    public let label: String?

    public let value: String?

    public let traits: UIAccessibilityTraits

    /// A unique identifier for the element, primarily used in UI tests for locating and interacting with elements.
    /// This identifier is not visible to users.
    public let identifier: String?

    /// A hint that will be read by VoiceOver if focus remains on the element after the `description` is read.
    public let hint: String?

    /// The labels that will be used by Voice Control for user input.
    /// These labels are displayed based on the `AccessibilityContentDisplayMode` configuration:
    /// - `.always`: Always shows user input labels
    /// - `.whenOverridden`: Shows labels only when they differ from default values (future enhancement)
    /// - `.never`: Never shows user input labels
    public let userInputLabels: [String]?

    /// The shape that will be highlighted on screen while the element is in focus.
    public let shape: Shape

    /// The accessibility activation point, in the coordinate space of the view being snapshotted.
    public let activationPoint: CGPoint

    /// Whether or not the `activationPoint` is the default activation point for the object.
    ///
    /// For most elements, the default activation point is the midpoint of the element's accessibility frame. Certain
    /// elements have distinct defaults - for example, a `UISlider` puts its activation point at the center of its thumb
    /// by default.
    public let usesDefaultActivationPoint: Bool

    /// The custom actions supported by the element.
    public let customActions: [CustomAction]

    /// Any custom content included by the element.
    public let customContent: [CustomContent]

    /// Any custom rotors included by the element.
    public let customRotors: [CustomRotor]

    /// The language code of the language used to localize strings in the description.
    public let accessibilityLanguage: String?

    /// Whether the element performs an action based on user interaction.
    public let respondsToUserInteraction: Bool

    /// The container context in which this element was parsed.
    public let containerContext: ContainerContext?

    // MARK: - Initialization

    init(
        description: String,
        label: String?,
        value: String?,
        traits: UIAccessibilityTraits,
        identifier: String?,
        hint: String?,
        userInputLabels: [String]?,
        shape: Shape,
        activationPoint: CGPoint,
        usesDefaultActivationPoint: Bool,
        customActions: [CustomAction],
        customContent: [CustomContent],
        customRotors: [CustomRotor],
        accessibilityLanguage: String?,
        respondsToUserInteraction: Bool,
        containerContext: ContainerContext?
    ) {
        self.description = description
        self.label = label
        self.value = value
        self.traits = traits
        self.identifier = identifier
        self.hint = hint
        self.userInputLabels = userInputLabels
        self.shape = shape
        self.activationPoint = activationPoint
        self.usesDefaultActivationPoint = usesDefaultActivationPoint
        self.customActions = customActions
        self.customContent = customContent
        self.customRotors = customRotors
        self.accessibilityLanguage = accessibilityLanguage
        self.respondsToUserInteraction = respondsToUserInteraction
        self.containerContext = containerContext
    }
}

// MARK: - Computed Description

public extension AccessibilityElement {
    /// Computes the VoiceOver description using the element's stored properties and container context.
    ///
    /// This is useful when you need to regenerate the description, such as when
    /// testing different verbosity settings.
    var voiceOverDescription: (description: String, hint: String?) {
        // Uses the protocol's default implementation from AccessibilityDescribable
        buildAccessibilityDescription(context: containerContext)
    }
}

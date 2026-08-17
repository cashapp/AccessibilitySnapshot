public typealias AccessibilityMarker = AccessibilityElement

public struct AccessibilityElement: Hashable, Codable, Sendable {
    public static let defaultRotorResultLimit: Int = 10

    // MARK: - Public Types

    public struct CustomRotor: Hashable, Codable, Sendable, CustomStringConvertible {
        public struct ResultMarker: Hashable, Codable, Sendable, CustomStringConvertible {
            public let elementDescription: String
            public let rangeDescription: String?
            public let shape: AccessibilityShape?

            public init(elementDescription: String, rangeDescription: String? = nil, shape: AccessibilityShape? = nil) {
                self.elementDescription = elementDescription
                self.rangeDescription = rangeDescription
                self.shape = shape
            }

            public var description: String {
                guard let rangeDescription else {
                    return elementDescription
                }
                return "\(elementDescription) \(rangeDescription)"
            }
        }

        public var name: String
        public var resultMarkers: [ResultMarker] = []
        public let limit: AccessibilityRotorResultLimit

        public init(name: String, resultMarkers: [ResultMarker] = [], limit: AccessibilityRotorResultLimit = .none) {
            self.name = name
            self.resultMarkers = resultMarkers
            self.limit = limit
        }

        public var description: String {
            name + ": " + resultMarkers.map(\.description).joined(separator: "\n")
        }
    }

    public struct CustomContent: Hashable, Codable, Sendable {
        public var label: String
        public var value: String
        public var isImportant: Bool

        public init(label: String, value: String, isImportant: Bool = false) {
            self.label = label
            self.value = value
            self.isImportant = isImportant
        }
    }

    public typealias CustomAction = String

    // MARK: - Public Properties

    public let description: String
    public let label: String?
    public let value: String?
    public let traits: AccessibilityTraits
    public let identifier: String?
    public let hint: String?
    public let userInputLabels: [String]?
    public let shape: AccessibilityShape
    public let activationPoint: AccessibilityPoint
    public let usesDefaultActivationPoint: Bool
    public let customActions: [CustomAction]
    public let customContent: [CustomContent]
    public let customRotors: [CustomRotor]
    public let accessibilityLanguage: String?
    public let respondsToUserInteraction: Bool

    /// Whether the element was on screen at parse time. Defaults to `.onscreen`, which is also the
    /// value used when decoding payloads written before this field existed.
    public let visibility: AccessibilityVisibility

    // MARK: - Initialization

    public init(
        description: String,
        label: String?,
        value: String?,
        traits: AccessibilityTraits,
        identifier: String?,
        hint: String?,
        userInputLabels: [String]?,
        shape: AccessibilityShape,
        activationPoint: AccessibilityPoint,
        usesDefaultActivationPoint: Bool,
        customActions: [CustomAction],
        customContent: [CustomContent],
        customRotors: [CustomRotor],
        accessibilityLanguage: String?,
        respondsToUserInteraction: Bool,
        visibility: AccessibilityVisibility = .onscreen
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
        self.visibility = visibility
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case description
        case label
        case value
        case traits
        case identifier
        case hint
        case userInputLabels
        case shape
        case activationPoint
        case usesDefaultActivationPoint
        case customActions
        case customContent
        case customRotors
        case accessibilityLanguage
        case respondsToUserInteraction
        case visibility
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        description = try container.decode(String.self, forKey: .description)
        label = try container.decodeIfPresent(String.self, forKey: .label)
        value = try container.decodeIfPresent(String.self, forKey: .value)
        traits = try container.decode(AccessibilityTraits.self, forKey: .traits)
        identifier = try container.decodeIfPresent(String.self, forKey: .identifier)
        hint = try container.decodeIfPresent(String.self, forKey: .hint)
        userInputLabels = try container.decodeIfPresent([String].self, forKey: .userInputLabels)
        shape = try container.decode(AccessibilityShape.self, forKey: .shape)
        activationPoint = try container.decode(AccessibilityPoint.self, forKey: .activationPoint)
        usesDefaultActivationPoint = try container.decode(Bool.self, forKey: .usesDefaultActivationPoint)
        customActions = try container.decode([CustomAction].self, forKey: .customActions)
        customContent = try container.decode([CustomContent].self, forKey: .customContent)
        customRotors = try container.decode([CustomRotor].self, forKey: .customRotors)
        accessibilityLanguage = try container.decodeIfPresent(String.self, forKey: .accessibilityLanguage)
        respondsToUserInteraction = try container.decode(Bool.self, forKey: .respondsToUserInteraction)
        // `visibility` is a field this fork adds. Decode leniently so payloads produced before it
        // existed don't crash — they simply default to `.onscreen`.
        visibility = try container.decodeIfPresent(AccessibilityVisibility.self, forKey: .visibility) ?? .onscreen
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(description, forKey: .description)
        try container.encodeIfPresent(label, forKey: .label)
        try container.encodeIfPresent(value, forKey: .value)
        try container.encode(traits, forKey: .traits)
        try container.encodeIfPresent(identifier, forKey: .identifier)
        try container.encodeIfPresent(hint, forKey: .hint)
        try container.encodeIfPresent(userInputLabels, forKey: .userInputLabels)
        try container.encode(shape, forKey: .shape)
        try container.encode(activationPoint, forKey: .activationPoint)
        try container.encode(usesDefaultActivationPoint, forKey: .usesDefaultActivationPoint)
        try container.encode(customActions, forKey: .customActions)
        try container.encode(customContent, forKey: .customContent)
        try container.encode(customRotors, forKey: .customRotors)
        try container.encodeIfPresent(accessibilityLanguage, forKey: .accessibilityLanguage)
        try container.encode(respondsToUserInteraction, forKey: .respondsToUserInteraction)
        try container.encode(visibility, forKey: .visibility)
    }

    // MARK: - Copying

    /// Returns a copy with `description` and `hint` replaced. Used at delivery to write the
    /// materialized spoken string (composed from context + verbosity) onto an element the parser
    /// captured with only raw facts.
    ///
    /// The result is a terminal, render-ready projection: its `hint` holds the COMPOSED hint, so it
    /// must never be fed back through `description(context:verbosity:)` (which reads `hint` as a raw
    /// fact) — always re-compose from the original element instead.
    public func withDescription(_ description: String, hint: String?) -> AccessibilityElement {
        AccessibilityElement(
            description: description,
            label: label,
            value: value,
            traits: traits,
            identifier: identifier,
            hint: hint,
            userInputLabels: userInputLabels,
            shape: shape,
            activationPoint: activationPoint,
            usesDefaultActivationPoint: usesDefaultActivationPoint,
            customActions: customActions,
            customContent: customContent,
            customRotors: customRotors,
            accessibilityLanguage: accessibilityLanguage,
            respondsToUserInteraction: respondsToUserInteraction,
            visibility: visibility
        )
    }
}

public typealias AccessibilityMarker = AccessibilityElement

public struct AccessibilityElement: Hashable, Codable, Sendable {
    public static let defaultRotorResultLimit: Int = 10

    // MARK: - Public Types

    public struct CustomRotor: Hashable, Codable, Sendable, CustomStringConvertible {
        public struct Result: Hashable, Codable, Sendable, CustomStringConvertible {
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

        public let name: String
        public let results: [Result]
        public let limit: AccessibilityRotorResultLimit

        public init(name: String, results: [Result] = [], limit: AccessibilityRotorResultLimit = .none) {
            self.name = name
            self.results = results
            self.limit = limit
        }

        public var description: String {
            name + ": " + results.map { $0.description }.joined(separator: "\n")
        }

        private enum CodingKeys: String, CodingKey {
            case name
            case results = "resultMarkers"
            case limit
        }
    }

    public struct CustomContent: Hashable, Codable, Sendable {
        public let label: String
        public let value: String
        public let isImportant: Bool

        public init(label: String, value: String, isImportant: Bool = false) {
            self.label = label
            self.value = value
            self.isImportant = isImportant
        }
    }

    public typealias CustomAction = String

    // MARK: - Public Properties

    public var description: String { formattedDescription.description }
    public let label: String?
    public let value: String?
    public let traits: AccessibilityTraits
    public let identifier: String?
    public var hint: String? { formattedDescription.hint }
    public let userInputLabels: [String]?
    public let shape: AccessibilityShape
    public let activationPoint: AccessibilityPoint
    public let usesDefaultActivationPoint: Bool
    public let customActions: [CustomAction]
    public let customContent: [CustomContent]
    public private(set) var customRotors: [CustomRotor]
    public let accessibilityLanguage: String?
    public let respondsToUserInteraction: Bool
    public private(set) var context: AccessibilityContext?

    /// Whether the element was on screen at parse time. Defaults to `.onscreen`, which is also the
    /// value used when decoding payloads written before this field existed.
    public let visibility: ScreenVisibility

    // MARK: - Initialization

    /// - Parameter hint: The captured accessibility hint before speech instructions are added.
    public init(
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
        visibility: ScreenVisibility = .onscreen,
        context: AccessibilityContext? = nil
    ) {
        self.label = label
        self.value = value
        self.traits = traits
        self.identifier = identifier
        authoredHint = hint
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
        self.context = context
    }

    /// Attaches context derived by the parser to the captured element.
    @_spi(Parsing)
    public mutating func addContext(_ context: AccessibilityContext?) {
        self.context = context
    }

    /// Attaches rotor results formatted with context derived by the parser.
    @_spi(Parsing)
    public mutating func addCustomRotors(_ customRotors: [CustomRotor]) {
        self.customRotors = customRotors
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case label
        case value
        case traits
        case identifier
        case authoredHint
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
        case context
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        label = try container.decodeIfPresent(String.self, forKey: .label)
        value = try container.decodeIfPresent(String.self, forKey: .value)
        traits = try container.decode(AccessibilityTraits.self, forKey: .traits)
        identifier = try container.decodeIfPresent(String.self, forKey: .identifier)
        // Legacy payloads stored the formatted hint; use it as best-effort raw input.
        authoredHint = try container.decodeIfPresent(String.self, forKey: container.contains(.authoredHint) ? .authoredHint : .hint)
        userInputLabels = try container.decodeIfPresent([String].self, forKey: .userInputLabels)
        shape = try container.decode(AccessibilityShape.self, forKey: .shape)
        activationPoint = try container.decode(AccessibilityPoint.self, forKey: .activationPoint)
        usesDefaultActivationPoint = try container.decode(Bool.self, forKey: .usesDefaultActivationPoint)
        customActions = try container.decode([CustomAction].self, forKey: .customActions)
        customContent = try container.decode([CustomContent].self, forKey: .customContent)
        customRotors = try container.decode([CustomRotor].self, forKey: .customRotors)
        accessibilityLanguage = try container.decodeIfPresent(String.self, forKey: .accessibilityLanguage)
        respondsToUserInteraction = try container.decode(Bool.self, forKey: .respondsToUserInteraction)
        // Payloads written before visibility was recorded default to `.onscreen`.
        visibility = try container.decodeIfPresent(ScreenVisibility.self, forKey: .visibility) ?? .onscreen
        context = try container.decodeIfPresent(AccessibilityContext.self, forKey: .context)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(label, forKey: .label)
        try container.encodeIfPresent(value, forKey: .value)
        try container.encode(traits, forKey: .traits)
        try container.encodeIfPresent(identifier, forKey: .identifier)
        try container.encode(authoredHint, forKey: .authoredHint)
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
        try container.encodeIfPresent(context, forKey: .context)
    }

    // MARK: - Speech Formatting

    private let authoredHint: String?

    private var formattedDescription: (description: String, hint: String?) {
        Self.accessibilityDescription(
            label: label,
            value: value,
            traits: traits,
            authoredHint: authoredHint,
            accessibilityLanguage: accessibilityLanguage,
            context: context
        )
    }
}

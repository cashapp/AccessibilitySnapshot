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

    public struct CustomAction: Hashable, Codable, Sendable {
        public var name: String

        public init(name: String) {
            self.name = name
        }
    }

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
        respondsToUserInteraction: Bool
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
    }
}

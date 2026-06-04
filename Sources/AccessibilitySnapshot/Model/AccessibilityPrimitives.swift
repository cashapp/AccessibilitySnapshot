// MARK: - Portable Geometry

public struct AccessibilityPoint: Hashable, Codable, Sendable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public static let zero = AccessibilityPoint(x: 0, y: 0)

    public var isFinite: Bool {
        x.isFinite && y.isFinite
    }
}

public struct AccessibilitySize: Hashable, Codable, Sendable {
    public let width: Double
    public let height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }

    public static let zero = AccessibilitySize(width: 0, height: 0)

    public var isFinite: Bool {
        width.isFinite && height.isFinite
    }
}

public struct AccessibilityRect: Hashable, Codable, Sendable {
    public let origin: AccessibilityPoint
    public let size: AccessibilitySize

    public init(origin: AccessibilityPoint, size: AccessibilitySize) {
        self.origin = origin
        self.size = size
    }

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.init(
            origin: AccessibilityPoint(x: x, y: y),
            size: AccessibilitySize(width: width, height: height)
        )
    }

    public static let zero = AccessibilityRect(origin: .zero, size: .zero)

    public var minX: Double { origin.x }
    public var minY: Double { origin.y }
    public var maxX: Double { origin.x + size.width }
    public var maxY: Double { origin.y + size.height }
    public var midX: Double { origin.x + size.width / 2 }
    public var midY: Double { origin.y + size.height / 2 }
    public var width: Double { size.width }
    public var height: Double { size.height }

    public var isFinite: Bool {
        origin.isFinite && size.isFinite
    }
}

// MARK: - Path Element

public enum AccessibilityPathElement: Hashable, Codable, Sendable {
    case move(to: AccessibilityPoint)
    case line(to: AccessibilityPoint)
    case quadCurve(to: AccessibilityPoint, control: AccessibilityPoint)
    case curve(to: AccessibilityPoint, control1: AccessibilityPoint, control2: AccessibilityPoint)
    case closeSubpath
}

// MARK: - Portable Shape

public enum AccessibilityShape: Hashable, Codable, Sendable {
    case frame(AccessibilityRect)
    case path([AccessibilityPathElement])
}

// MARK: - Wire-Compatible Codable

// The geometry types previously used CoreGraphics (`CGPoint`/`CGSize`/`CGRect`) whose
// synthesized `Codable` conformances encode as unkeyed arrays (`[x, y]`,
// `[width, height]`, `[[x, y], [width, height]]`). The portable replacements below
// reproduce that exact wire format so already-persisted JSON keeps decoding and
// re-encoding identically.

public extension AccessibilityPoint {
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let x = try container.decode(Double.self)
        let y = try container.decode(Double.self)
        self.init(x: x, y: y)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(x)
        try container.encode(y)
    }
}

public extension AccessibilitySize {
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let width = try container.decode(Double.self)
        let height = try container.decode(Double.self)
        self.init(width: width, height: height)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(width)
        try container.encode(height)
    }
}

public extension AccessibilityRect {
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let origin = try container.decode(AccessibilityPoint.self)
        let size = try container.decode(AccessibilitySize.self)
        self.init(origin: origin, size: size)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(origin)
        try container.encode(size)
    }
}

// `AccessibilityShape` reproduces the legacy `AccessibilityElement.Shape` wire format:
// a `type` discriminator alongside a `frame` or `pathElements` payload.
extension AccessibilityShape {
    private enum CodingKeys: String, CodingKey {
        case type
        case frame
        case pathElements
    }

    private enum ShapeType: String, Codable {
        case frame
        case path
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(ShapeType.self, forKey: .type) {
        case .frame:
            self = try .frame(container.decode(AccessibilityRect.self, forKey: .frame))
        case .path:
            self = try .path(container.decode([AccessibilityPathElement].self, forKey: .pathElements))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .frame(rect):
            try container.encode(ShapeType.frame, forKey: .type)
            try container.encode(rect, forKey: .frame)
        case let .path(elements):
            try container.encode(ShapeType.path, forKey: .type)
            try container.encode(elements, forKey: .pathElements)
        }
    }
}

// MARK: - Portable Traits

public struct AccessibilityTraits: OptionSet, Hashable, Codable, Sendable {
    public let rawValue: UInt64
    public init(rawValue: UInt64) { self.rawValue = rawValue }

    // Public UIAccessibilityTraits (bits 0–14, 16)
    public static let button = AccessibilityTraits(rawValue: 1 << 0)
    public static let link = AccessibilityTraits(rawValue: 1 << 1)
    public static let image = AccessibilityTraits(rawValue: 1 << 2)
    public static let selected = AccessibilityTraits(rawValue: 1 << 3)
    public static let playsSound = AccessibilityTraits(rawValue: 1 << 4)
    public static let keyboardKey = AccessibilityTraits(rawValue: 1 << 5)
    public static let staticText = AccessibilityTraits(rawValue: 1 << 6)
    public static let summaryElement = AccessibilityTraits(rawValue: 1 << 7)
    public static let notEnabled = AccessibilityTraits(rawValue: 1 << 8)
    public static let updatesFrequently = AccessibilityTraits(rawValue: 1 << 9)
    public static let searchField = AccessibilityTraits(rawValue: 1 << 10)
    public static let startsMediaSession = AccessibilityTraits(rawValue: 1 << 11)
    public static let adjustable = AccessibilityTraits(rawValue: 1 << 12)
    public static let allowsDirectInteraction = AccessibilityTraits(rawValue: 1 << 13)
    public static let causesPageTurn = AccessibilityTraits(rawValue: 1 << 14)
    public static let header = AccessibilityTraits(rawValue: 1 << 16)

    // Private AXRuntime traits used by the parser
    public static let tabBar = AccessibilityTraits(rawValue: 1 << 15)
    public static let textEntry = AccessibilityTraits(rawValue: 1 << 18)
    public static let isEditing = AccessibilityTraits(rawValue: 1 << 21)
    public static let secureTextField = AccessibilityTraits(rawValue: 1 << 24)
    public static let backButton = AccessibilityTraits(rawValue: 1 << 27)
    public static let tabBarItem = AccessibilityTraits(rawValue: 1 << 28)
    public static let textArea = AccessibilityTraits(rawValue: 1 << 47)
    public static let switchButton = AccessibilityTraits(rawValue: 1 << 53)

    public static let knownTraits: [(trait: AccessibilityTraits, name: String)] = [
        (.button, "button"),
        (.link, "link"),
        (.image, "image"),
        (.selected, "selected"),
        (.playsSound, "playsSound"),
        (.keyboardKey, "keyboardKey"),
        (.staticText, "staticText"),
        (.summaryElement, "summaryElement"),
        (.notEnabled, "notEnabled"),
        (.updatesFrequently, "updatesFrequently"),
        (.searchField, "searchField"),
        (.startsMediaSession, "startsMediaSession"),
        (.adjustable, "adjustable"),
        (.allowsDirectInteraction, "allowsDirectInteraction"),
        (.causesPageTurn, "causesPageTurn"),
        (.header, "header"),
        (.tabBar, "tabBar"),
        (.textEntry, "textEntry"),
        (.isEditing, "isEditing"),
        (.secureTextField, "secureTextField"),
        (.backButton, "backButton"),
        (.tabBarItem, "tabBarItem"),
        (.textArea, "textArea"),
        (.switchButton, "switchButton"),
    ]

    public var traitNames: [String] {
        var names: [String] = []
        var remaining = rawValue
        for (trait, name) in Self.knownTraits where contains(trait) {
            names.append(name)
            remaining &= ~trait.rawValue
        }
        if remaining != 0 {
            names.append("unknown(\(remaining))")
        }
        return names
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let names = try container.decode([String].self)

        var value: UInt64 = 0
        for name in names {
            if let known = Self.knownTraits.first(where: { $0.name == name }) {
                value |= known.trait.rawValue
            } else if name.hasPrefix("unknown("), name.hasSuffix(")") {
                let start = name.index(name.startIndex, offsetBy: 8)
                let end = name.index(name.endIndex, offsetBy: -1)
                if let raw = UInt64(name[start ..< end]) {
                    value |= raw
                }
            }
        }
        self.init(rawValue: value)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(traitNames)
    }
}

// MARK: - Rotor Result Limit

public enum AccessibilityRotorResultLimit: Hashable, Codable, Sendable {
    case none
    case underMaxCount(Int)
    case greaterThanMaxCount
}

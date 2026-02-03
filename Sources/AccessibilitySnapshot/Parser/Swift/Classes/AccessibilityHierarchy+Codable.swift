import UIKit

// MARK: - UIKit Type Codable Extensions

#if compiler(>=6.0)
    extension UIAccessibilityTraits: @retroactive Codable {}
#else
    extension UIAccessibilityTraits: Codable {}
#endif

// MARK: - UIAccessibilityTraits Codable

public extension UIAccessibilityTraits {
    /// Known trait names for human-readable encoding
    private static let knownTraits: [(trait: UIAccessibilityTraits, name: String)] = [
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
        // Private traits (defined in UIAccessibility+SnapshotAdditions.swift)
        (.textEntry, "textEntry"),
        (.isEditing, "isEditing"),
        (.backButton, "backButton"),
        (.tabBarItem, "tabBarItem"),
        (.scrollable, "scrollable"),
        (.switchButton, "switchButton"),
    ]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let traitNames = try container.decode([String].self)

        var traits = UIAccessibilityTraits()
        var unknownValues: UInt64 = 0

        for name in traitNames {
            if let known = Self.knownTraits.first(where: { $0.name == name }) {
                traits.insert(known.trait)
            } else if name.hasPrefix("unknown("), name.hasSuffix(")") {
                // Parse unknown raw values: "unknown(12345)"
                let startIndex = name.index(name.startIndex, offsetBy: 8)
                let endIndex = name.index(name.endIndex, offsetBy: -1)
                if let rawValue = UInt64(name[startIndex ..< endIndex]) {
                    unknownValues |= rawValue
                }
            }
        }

        self = UIAccessibilityTraits(rawValue: traits.rawValue | unknownValues)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        var traitNames: [String] = []
        var remainingRawValue = rawValue

        for (trait, name) in Self.knownTraits {
            if contains(trait) {
                traitNames.append(name)
                remainingRawValue &= ~trait.rawValue
            }
        }

        // Encode any unknown traits as raw values for forward compatibility
        if remainingRawValue != 0 {
            traitNames.append("unknown(\(remainingRawValue))")
        }

        try container.encode(traitNames)
    }
}

// MARK: - Shape Codable

extension AccessibilityElement.Shape: Codable {
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
        let type = try container.decode(ShapeType.self, forKey: .type)

        switch type {
        case .frame:
            let frame = try container.decode(CGRect.self, forKey: .frame)
            self = .frame(frame)

        case .path:
            let elements = try container.decode([PathElement].self, forKey: .pathElements)
            let path = UIBezierPath()
            for element in elements {
                element.apply(to: path)
            }
            self = .path(path)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .frame(frame):
            try container.encode(ShapeType.frame, forKey: .type)
            try container.encode(frame, forKey: .frame)

        case let .path(path):
            try container.encode(ShapeType.path, forKey: .type)
            let elements = PathElement.elements(from: path.cgPath)
            try container.encode(elements, forKey: .pathElements)
        }
    }
}

// MARK: - PathElement for Path Encoding

/// Represents a single element of a CGPath for Codable serialization
private enum PathElement: Codable, Equatable {
    case move(to: CGPoint)
    case line(to: CGPoint)
    case quadCurve(to: CGPoint, control: CGPoint)
    case curve(to: CGPoint, control1: CGPoint, control2: CGPoint)
    case closeSubpath

    func apply(to path: UIBezierPath) {
        switch self {
        case let .move(to):
            path.move(to: to)
        case let .line(to):
            path.addLine(to: to)
        case let .quadCurve(to, control):
            path.addQuadCurve(to: to, controlPoint: control)
        case let .curve(to, control1, control2):
            path.addCurve(to: to, controlPoint1: control1, controlPoint2: control2)
        case .closeSubpath:
            path.close()
        }
    }

    static func elements(from cgPath: CGPath) -> [PathElement] {
        var elements: [PathElement] = []

        cgPath.applyWithBlock { elementPointer in
            let element = elementPointer.pointee
            switch element.type {
            case .moveToPoint:
                elements.append(.move(to: element.points[0]))
            case .addLineToPoint:
                elements.append(.line(to: element.points[0]))
            case .addQuadCurveToPoint:
                elements.append(.quadCurve(to: element.points[1], control: element.points[0]))
            case .addCurveToPoint:
                elements.append(.curve(to: element.points[2], control1: element.points[0], control2: element.points[1]))
            case .closeSubpath:
                elements.append(.closeSubpath)
            @unknown default:
                break
            }
        }

        return elements
    }
}

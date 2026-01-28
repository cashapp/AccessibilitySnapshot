//
//  Copyright 2025 Block Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit

// MARK: - UIKit Type Codable Extensions

#if swift(>=6.0)
extension UIAccessibilityTraits: @retroactive Codable {}
extension UIAccessibilityContainerType: @retroactive Codable {}
#else
extension UIAccessibilityTraits: Codable {}
extension UIAccessibilityContainerType: Codable {}
#endif

// MARK: - UIAccessibilityTraits Codable

extension UIAccessibilityTraits {

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

    public init(from decoder: Decoder) throws {
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
                if let rawValue = UInt64(name[startIndex..<endIndex]) {
                    unknownValues |= rawValue
                }
            }
        }

        self = UIAccessibilityTraits(rawValue: traits.rawValue | unknownValues)
    }

    public func encode(to encoder: Encoder) throws {
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

// MARK: - UIAccessibilityContainerType Codable

extension UIAccessibilityContainerType {

    private static let typeNames: [UIAccessibilityContainerType: String] = [
        .none: "none",
        .dataTable: "dataTable",
        .list: "list",
        .landmark: "landmark",
        .semanticGroup: "semanticGroup",
    ]

    private static let nameToType: [String: UIAccessibilityContainerType] = {
        Dictionary(uniqueKeysWithValues: typeNames.map { ($1, $0) })
    }()

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let name = try container.decode(String.self)

        if let type = Self.nameToType[name] {
            self = type
        } else if name.hasPrefix("unknown("), name.hasSuffix(")") {
            // Parse unknown raw values: "unknown(5)"
            let startIndex = name.index(name.startIndex, offsetBy: 8)
            let endIndex = name.index(name.endIndex, offsetBy: -1)
            if let rawValue = Int(name[startIndex..<endIndex]) {
                self = UIAccessibilityContainerType(rawValue: rawValue) ?? .none
            } else {
                self = .none
            }
        } else {
            self = .none
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        if let name = Self.typeNames[self] {
            try container.encode(name)
        } else {
            // Forward compatibility for unknown types
            try container.encode("unknown(\(rawValue))")
        }
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
        case .frame(let frame):
            try container.encode(ShapeType.frame, forKey: .type)
            try container.encode(frame, forKey: .frame)

        case .path(let path):
            try container.encode(ShapeType.path, forKey: .type)
            let elements = PathElement.elements(from: path.cgPath)
            try container.encode(elements, forKey: .pathElements)
        }
    }
}

// MARK: - PathElement for Human-Readable Path Encoding

/// Represents a single element of a CGPath for Codable serialization
private enum PathElement: Codable, Equatable {
    case move(to: CGPoint)
    case line(to: CGPoint)
    case quadCurve(to: CGPoint, control: CGPoint)
    case curve(to: CGPoint, control1: CGPoint, control2: CGPoint)
    case closeSubpath

    private enum CodingKeys: String, CodingKey {
        case type
        case to
        case control
        case control1
        case control2
    }

    private enum ElementType: String, Codable {
        case move
        case line
        case quadCurve
        case curve
        case close
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ElementType.self, forKey: .type)

        switch type {
        case .move:
            let to = try container.decode(CGPoint.self, forKey: .to)
            self = .move(to: to)
        case .line:
            let to = try container.decode(CGPoint.self, forKey: .to)
            self = .line(to: to)
        case .quadCurve:
            let to = try container.decode(CGPoint.self, forKey: .to)
            let control = try container.decode(CGPoint.self, forKey: .control)
            self = .quadCurve(to: to, control: control)
        case .curve:
            let to = try container.decode(CGPoint.self, forKey: .to)
            let control1 = try container.decode(CGPoint.self, forKey: .control1)
            let control2 = try container.decode(CGPoint.self, forKey: .control2)
            self = .curve(to: to, control1: control1, control2: control2)
        case .close:
            self = .closeSubpath
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .move(let to):
            try container.encode(ElementType.move, forKey: .type)
            try container.encode(to, forKey: .to)
        case .line(let to):
            try container.encode(ElementType.line, forKey: .type)
            try container.encode(to, forKey: .to)
        case .quadCurve(let to, let control):
            try container.encode(ElementType.quadCurve, forKey: .type)
            try container.encode(to, forKey: .to)
            try container.encode(control, forKey: .control)
        case .curve(let to, let control1, let control2):
            try container.encode(ElementType.curve, forKey: .type)
            try container.encode(to, forKey: .to)
            try container.encode(control1, forKey: .control1)
            try container.encode(control2, forKey: .control2)
        case .closeSubpath:
            try container.encode(ElementType.close, forKey: .type)
        }
    }

    func apply(to path: UIBezierPath) {
        switch self {
        case .move(let to):
            path.move(to: to)
        case .line(let to):
            path.addLine(to: to)
        case .quadCurve(let to, let control):
            path.addQuadCurve(to: to, controlPoint: control)
        case .curve(let to, let control1, let control2):
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

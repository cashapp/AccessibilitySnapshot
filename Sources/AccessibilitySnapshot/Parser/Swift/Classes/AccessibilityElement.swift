//
//  Copyright 2019 Square Inc.
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

/// A type alias for backwards compatibility.
public typealias AccessibilityMarker = AccessibilityElement

public struct AccessibilityElement: Equatable, Codable {

    /// Default number of rotor results to collect in each direction.
    public static let defaultRotorResultLimit: Int = 10

    // MARK: - Public Types

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

        init?(from: UIAccessibilityCustomRotor, parentElement: NSObject, root: UIView, context: AccessibilityHierarchyParser.Context? = nil, resultLimit: Int) {
            guard from.isKnownRotorType else { return nil }
            name = from.displayName(locale: parentElement.accessibilityLanguage)
            let collected = from.collectAllResults(nextLimit: resultLimit, previousLimit: resultLimit)
            limit = collected.limit
            resultMarkers = collected.results.compactMap { result in
                guard let element = result.targetElement as? NSObject else { return nil }
                var description = element.accessibilityDescription(context: context).description
                var shape: Shape? = AccessibilityHierarchyParser.accessibilityShape(for: element, in: root)

                if let range = result.targetRange,
                   let input = element as? UITextInput {
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
            return name + ": " + resultMarkers.map({ $0.description }).joined(separator: "\n")
        }
    }

    public struct CustomContent: Codable, Equatable {
        public var label: String
        public var value: String
        public var isImportant: Bool

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

        // Custom Codable implementation that only encodes the name
        // (UIImage is not Codable)
        private enum CodingKeys: String, CodingKey {
            case name
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            image = nil
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
        }
    }

    // MARK: - Public Properties

    /// The description of the accessibility element that will be read by VoiceOver when the element is brought into
    /// focus.
    public var description: String

    public var label: String?

    public var value: String?

    public var traits: UIAccessibilityTraits

    /// A unique identifier for the element, primarily used in UI tests for locating and interacting with elements.
    /// This identifier is not visible to users.
    public var identifier: String?

    /// A hint that will be read by VoiceOver if focus remains on the element after the `description` is read.
    public var hint: String?

    /// The labels that will be used by Voice Control for user input.
    /// These labels are displayed based on the `AccessibilityContentDisplayMode` configuration:
    /// - `.always`: Always shows user input labels
    /// - `.whenOverridden`: Shows labels only when they differ from default values (future enhancement)
    /// - `.never`: Never shows user input labels
    public var userInputLabels: [String]?

    /// The shape that will be highlighted on screen while the element is in focus.
    public var shape: Shape

    /// The accessibility activation point, in the coordinate space of the view being snapshotted.
    public var activationPoint: CGPoint

    /// Whether or not the `activationPoint` is the default activation point for the object.
    ///
    /// For most elements, the default activation point is the midpoint of the element's accessibility frame. Certain
    /// elements have distinct defaults - for example, a `UISlider` puts its activation point at the center of its thumb
    /// by default.
    public var usesDefaultActivationPoint: Bool

    /// The custom actions supported by the element.
    public var customActions: [CustomAction]

    /// Any custom content included by the element.
    public var customContent: [CustomContent]

    /// Any custom rotors included by the element.
    public var customRotors: [CustomRotor]

    /// The language code of the language used to localize strings in the description.
    public var accessibilityLanguage: String?

    /// Whether the element performs an action based on user interaction.
    public var respondsToUserInteraction: Bool

}

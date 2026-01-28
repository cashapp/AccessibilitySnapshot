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

extension UIAccessibilityTraits {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(UInt64.self)
        self = UIAccessibilityTraits(rawValue: rawValue)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension UIAccessibilityContainerType {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)
        self = UIAccessibilityContainerType(rawValue: rawValue) ?? .none
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

// MARK: - Shape Codable

extension AccessibilityElement.Shape: Codable {

    private enum CodingKeys: String, CodingKey {
        case type
        case frame
        case pathData
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
            let pathData = try container.decode(Data.self, forKey: .pathData)
            if let path = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIBezierPath.self, from: pathData) {
                self = .path(path)
            } else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: container.codingPath,
                        debugDescription: "Failed to decode UIBezierPath from data"
                    )
                )
            }
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
            let pathData = try NSKeyedArchiver.archivedData(withRootObject: path, requiringSecureCoding: true)
            try container.encode(pathData, forKey: .pathData)
        }
    }
}

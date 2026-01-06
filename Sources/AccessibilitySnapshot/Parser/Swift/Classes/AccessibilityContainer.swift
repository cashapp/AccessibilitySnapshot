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

// MARK: - Container Visualization Types

public typealias ContainerType = UIAccessibilityContainerType

/// Information about a container node
public struct AccessibilityContainer: Equatable, Codable {
    /// The type of container
    public let type: ContainerType

    /// Container's accessibility label (if any)
    public let label: String?

    /// Container's accessibility value (if any)
    public let value: String?

    /// Container's accessibility identifier (if any)
    public let identifier: String?

    /// Container's frame in the root view's coordinate space (for visualization)
    public let frame: CGRect

    /// Container's accessibility traits (e.g., `.tabBar`)
    public let traits: UIAccessibilityTraits

    public init(type: ContainerType, label: String?, value: String?, identifier: String?, frame: CGRect, traits: UIAccessibilityTraits = []) {
        self.type = type
        self.label = label
        self.value = value
        self.identifier = identifier
        self.frame = frame
        self.traits = traits
    }
}

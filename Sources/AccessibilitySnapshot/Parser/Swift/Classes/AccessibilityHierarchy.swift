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

// MARK: - Hierarchy Node

/// A node in the accessibility hierarchy tree
public enum AccessibilityHierarchy: Equatable, Codable {
    /// A leaf node representing an accessibility element
    /// - Parameters:
    ///   - AccessibilityElement: The accessibility element data
    ///   - traversalIndex: Position in VoiceOver traversal order
    case element(AccessibilityElement, traversalIndex: Int)

    /// A container node that groups child elements
    /// - Parameters:
    ///   - AccessibilityContainer: Container metadata (type, label, value, identifier, frame)
    ///   - children: Child nodes within this container
    case container(AccessibilityContainer, children: [AccessibilityHierarchy])

    /// Child nodes (empty for leaf elements, contains children for containers)
    public var children: [AccessibilityHierarchy] {
        switch self {
        case .element:
            return []
        case .container(_, let children):
            return children
        }
    }

    /// Sort index for ordering in legend display.
    /// For elements: returns the traversal index.
    /// For containers: returns the minimum sort index of its children (recursively).
    public var sortIndex: Int {
        switch self {
        case .element(_, let index):
            return index
        case .container(_, let children):
            // Return minimum sort index of children, or Int.max if no children
            return children.map { $0.sortIndex }.min() ?? Int.max
        }
    }
}

// MARK: - Hierarchy Utilities

extension AccessibilityHierarchy {

    /// Recursively visits each node in the hierarchy tree
    public func forEach(_ apply: (AccessibilityHierarchy) -> Void) {
        apply(self)
        for child in children {
            child.forEach(apply)
        }
    }
}

extension Array where Element == AccessibilityHierarchy {

    /// Flattens an array of hierarchy nodes into a single array of elements in VoiceOver traversal order
    public func flattenToElements() -> [AccessibilityElement] {
        var elementPairs: [(index: Int, element: AccessibilityElement)] = []

        func collectElements(from node: AccessibilityHierarchy) {
            switch node {
            case .element(let element, let index):
                elementPairs.append((index, element))
            case .container(_, let children):
                for child in children {
                    collectElements(from: child)
                }
            }
        }

        for node in self {
            collectElements(from: node)
        }

        return elementPairs
            .sorted { $0.index < $1.index }
            .map { $0.element }
    }

    /// Flattens an array of hierarchy nodes into a single array of containers in depth-first order
    public func flattenToContainers() -> [AccessibilityContainer] {
        var containers: [AccessibilityContainer] = []

        func collectContainers(from node: AccessibilityHierarchy) {
            switch node {
            case .element:
                break
            case .container(let container, let children):
                containers.append(container)
                for child in children {
                    collectContainers(from: child)
                }
            }
        }

        for node in self {
            collectContainers(from: node)
        }

        return containers
    }
}

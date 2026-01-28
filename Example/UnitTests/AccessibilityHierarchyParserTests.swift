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

import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import UIKit
import XCTest

final class AccessibilityHierarchyParserTests: XCTestCase {

    func testUserInterfaceLayoutDirection() {
        let gridView = UIView(frame: .init(x: 0, y: 0, width: 20, height: 20))

        let elementA = UIView(frame: .init(x: 0, y: 0, width: 10, height: 10))
        elementA.isAccessibilityElement = true
        elementA.accessibilityLabel = "A"
        elementA.accessibilityFrame = elementA.frame
        gridView.addSubview(elementA)

        let elementB = UIView(frame: .init(x: 10, y: 0, width: 10, height: 10))
        elementB.isAccessibilityElement = true
        elementB.accessibilityLabel = "B"
        elementB.accessibilityFrame = elementB.frame
        gridView.addSubview(elementB)

        let elementC = UIView(frame: .init(x: 0, y: 10, width: 10, height: 10))
        elementC.isAccessibilityElement = true
        elementC.accessibilityLabel = "C"
        elementC.accessibilityFrame = elementC.frame
        gridView.addSubview(elementC)

        let elementD = UIView(frame: .init(x: 10, y: 10, width: 10, height: 10))
        elementD.isAccessibilityElement = true
        elementD.accessibilityLabel = "D"
        elementD.accessibilityFrame = elementD.frame
        gridView.addSubview(elementD)

        let parser = AccessibilityHierarchyParser()

        let ltrElements = parser.parseAccessibilityElements(
            in: gridView,
            userInterfaceLayoutDirectionProvider: TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .phone)
        ).map { $0.description }
        XCTAssertEqual(ltrElements, ["A", "B", "C", "D"])

        let rtlElements = parser.parseAccessibilityElements(
            in: gridView,
            userInterfaceLayoutDirectionProvider: TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .rightToLeft),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .phone)
        ).map { $0.description }
        XCTAssertEqual(rtlElements, ["B", "A", "D", "C"])

        // Validate parseAccessibilityHierarchy + flattenToElements matches deprecated parser
        let ltrHierarchyElements = parser.parseAccessibilityHierarchy(
            in: gridView,
            userInterfaceLayoutDirectionProvider: TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .phone)
        ).flattenToElements().map { $0.description }
        XCTAssertEqual(ltrHierarchyElements, ltrElements, "Hierarchy parser should match deprecated parser for LTR")

        let rtlHierarchyElements = parser.parseAccessibilityHierarchy(
            in: gridView,
            userInterfaceLayoutDirectionProvider: TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .rightToLeft),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .phone)
        ).flattenToElements().map { $0.description }
        XCTAssertEqual(rtlHierarchyElements, rtlElements, "Hierarchy parser should match deprecated parser for RTL")
    }

    func testVerticalSeperation() {
        let magicNumber = 8.0 // This is enough to trigger vertical separation for phone but not for pad

        let gridView = UIView(frame: .init(x: 0, y: 0, width: 100, height: 20))

        let elementA = UIView(frame: .init(x: 0, y: magicNumber, width: 10, height: 10))
        elementA.isAccessibilityElement = true
        elementA.accessibilityLabel = "A"
        elementA.accessibilityFrame = elementA.frame
        gridView.addSubview(elementA)

        let elementB = UIView(frame: .init(x: 10, y: 0, width: 0, height: 10))
        elementB.isAccessibilityElement = true
        elementB.accessibilityLabel = "B"
        elementB.accessibilityFrame = elementB.frame
        gridView.addSubview(elementB)

        let elementC = UIView(frame: .init(x: 20, y: -(magicNumber), width: 10, height: 10))
        elementC.isAccessibilityElement = true
        elementC.accessibilityLabel = "C"
        elementC.accessibilityFrame = elementC.frame
        gridView.addSubview(elementC)

        let elementD = UIView(frame: .init(x: 30, y: -(magicNumber), width: 10, height: 10))
        elementD.isAccessibilityElement = true
        elementD.accessibilityLabel = "D"
        elementD.accessibilityFrame = elementD.frame
        gridView.addSubview(elementD)

        let parser = AccessibilityHierarchyParser()

        let padElements = parser.parseAccessibilityElements(
            in: gridView,
            userInterfaceLayoutDirectionProvider:
                TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .pad)
        ).map { $0.description }
        // on pad elements are sorted horizontally
        XCTAssertEqual(padElements, ["A", "B", "C", "D"])

        let phoneElements = parser.parseAccessibilityElements(
            in: gridView,
            userInterfaceLayoutDirectionProvider:
                TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .phone)
        ).map { $0.description }
        // on phone elements are sorted vertically and then left to right
        XCTAssertEqual(phoneElements, ["C", "D", "B", "A"])

        // Validate parseAccessibilityHierarchy + flattenToElements matches deprecated parser
        let padHierarchyElements = parser.parseAccessibilityHierarchy(
            in: gridView,
            userInterfaceLayoutDirectionProvider:
                TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .pad)
        ).flattenToElements().map { $0.description }
        XCTAssertEqual(padHierarchyElements, padElements, "Hierarchy parser should match deprecated parser for pad")

        let phoneHierarchyElements = parser.parseAccessibilityHierarchy(
            in: gridView,
            userInterfaceLayoutDirectionProvider:
                TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .phone)
        ).flattenToElements().map { $0.description }
        XCTAssertEqual(phoneHierarchyElements, phoneElements, "Hierarchy parser should match deprecated parser for phone")

        let padMagicNumber = 25

        elementA.accessibilityFrame = .init(x: 0, y: padMagicNumber, width: 10, height: 10)
        elementB.accessibilityFrame = .init(x: 10, y: 0, width: 0, height: 10)
        elementC.accessibilityFrame = .init(x: 20, y: -(padMagicNumber), width: 10, height: 10)
        elementD.accessibilityFrame = .init(x: 30, y: -(padMagicNumber), width: 10, height: 10)

        let padAgain = parser.parseAccessibilityElements(
            in: gridView,
            userInterfaceLayoutDirectionProvider:
                TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .pad)
        ).map { $0.description }

        // Now pad elements are sorted vertically and then left to right
        XCTAssertEqual(padAgain, ["C", "D", "B", "A"])

        // Validate parseAccessibilityHierarchy + flattenToElements matches deprecated parser
        let padAgainHierarchyElements = parser.parseAccessibilityHierarchy(
            in: gridView,
            userInterfaceLayoutDirectionProvider:
                TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .pad)
        ).flattenToElements().map { $0.description }
        XCTAssertEqual(padAgainHierarchyElements, padAgain, "Hierarchy parser should match deprecated parser for pad with larger separation")
    }

    // MARK: - Container Hierarchy Tree Tests

    func testSemanticGroupWithLabelIsPreserved() {
        let rootView = UIView(frame: .init(x: 0, y: 0, width: 100, height: 100))

        let container = UIView(frame: .init(x: 0, y: 0, width: 100, height: 50))
        container.accessibilityContainerType = .semanticGroup
        container.accessibilityLabel = "Group Label"
        rootView.addSubview(container)

        let element = UIView(frame: .init(x: 10, y: 10, width: 30, height: 30))
        element.isAccessibilityElement = true
        element.accessibilityLabel = "Element"
        element.accessibilityFrame = CGRect(x: 10, y: 10, width: 30, height: 30)
        container.addSubview(element)

        let parser = AccessibilityHierarchyParser()
        let hierarchy = parser.parseAccessibilityHierarchy(in: rootView)

        // Should have one container at root level
        XCTAssertEqual(hierarchy.count, 1)

        // Verify it's a container with correct label
        if case .container(let containerInfo, let children) = hierarchy.first {
            XCTAssertEqual(containerInfo.label, "Group Label")
            XCTAssertEqual(containerInfo.type, .semanticGroup)
            XCTAssertEqual(children.count, 1)

            // Verify child element
            if case .element(let childElement, _) = children.first {
                XCTAssertEqual(childElement.description, "Element")
            } else {
                XCTFail("Expected element child")
            }
        } else {
            XCTFail("Expected container at root level")
        }
    }

    func testSemanticGroupWithoutLabelIsFlattened() {
        let rootView = UIView(frame: .init(x: 0, y: 0, width: 100, height: 100))

        let container = UIView(frame: .init(x: 0, y: 0, width: 100, height: 50))
        container.accessibilityContainerType = .semanticGroup
        // No label, value, or identifier
        rootView.addSubview(container)

        let element = UIView(frame: .init(x: 10, y: 10, width: 30, height: 30))
        element.isAccessibilityElement = true
        element.accessibilityLabel = "Element"
        element.accessibilityFrame = CGRect(x: 10, y: 10, width: 30, height: 30)
        container.addSubview(element)

        let parser = AccessibilityHierarchyParser()
        let hierarchy = parser.parseAccessibilityHierarchy(in: rootView)

        // Should have one element at root level (container flattened)
        XCTAssertEqual(hierarchy.count, 1)

        // Verify it's an element, not a container
        if case .element(let elementInfo, _) = hierarchy.first {
            XCTAssertEqual(elementInfo.description, "Element")
        } else {
            XCTFail("Expected element at root level (container should be flattened)")
        }
    }

    func testListContainerIsAlwaysPreserved() {
        let rootView = UIView(frame: .init(x: 0, y: 0, width: 100, height: 100))

        let listContainer = UIView(frame: .init(x: 0, y: 0, width: 100, height: 100))
        listContainer.accessibilityContainerType = .list
        // No label - but should still be preserved
        rootView.addSubview(listContainer)

        let item1 = UIView(frame: .init(x: 0, y: 0, width: 100, height: 30))
        item1.isAccessibilityElement = true
        item1.accessibilityLabel = "Item 1"
        item1.accessibilityFrame = CGRect(x: 0, y: 0, width: 100, height: 30)
        listContainer.addSubview(item1)

        let item2 = UIView(frame: .init(x: 0, y: 40, width: 100, height: 30))
        item2.isAccessibilityElement = true
        item2.accessibilityLabel = "Item 2"
        item2.accessibilityFrame = CGRect(x: 0, y: 40, width: 100, height: 30)
        listContainer.addSubview(item2)

        let parser = AccessibilityHierarchyParser()
        let hierarchy = parser.parseAccessibilityHierarchy(in: rootView)

        // Should have one list container at root level
        XCTAssertEqual(hierarchy.count, 1)

        if case .container(let containerInfo, let children) = hierarchy.first {
            XCTAssertEqual(containerInfo.type, .list)
            XCTAssertEqual(children.count, 2)
        } else {
            XCTFail("Expected list container at root level")
        }
    }

    func testLandmarkContainerIsAlwaysPreserved() {
        let rootView = UIView(frame: .init(x: 0, y: 0, width: 100, height: 100))

        let landmarkContainer = UIView(frame: .init(x: 0, y: 0, width: 100, height: 100))
        landmarkContainer.accessibilityContainerType = .landmark
        rootView.addSubview(landmarkContainer)

        let element = UIView(frame: .init(x: 10, y: 10, width: 30, height: 30))
        element.isAccessibilityElement = true
        element.accessibilityLabel = "Landmark Content"
        element.accessibilityFrame = CGRect(x: 10, y: 10, width: 30, height: 30)
        landmarkContainer.addSubview(element)

        let parser = AccessibilityHierarchyParser()
        let hierarchy = parser.parseAccessibilityHierarchy(in: rootView)

        XCTAssertEqual(hierarchy.count, 1)

        if case .container(let containerInfo, _) = hierarchy.first {
            XCTAssertEqual(containerInfo.type, .landmark)
        } else {
            XCTFail("Expected landmark container at root level")
        }
    }

    func testNestedContainersPreserveHierarchy() {
        // Use NestedContainersTestView which mirrors ContainerHierarchyViewController's NestedContainersDemoView
        let nestedView = NestedContainersTestView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))

        let parser = AccessibilityHierarchyParser()
        let hierarchy = parser.parseAccessibilityHierarchy(in: nestedView)

        // Should have outer container at root
        XCTAssertEqual(hierarchy.count, 1)

        if case .container(let outerInfo, let outerChildren) = hierarchy.first {
            XCTAssertEqual(outerInfo.label, "Outer Container")
            XCTAssertEqual(outerInfo.type, .semanticGroup)

            // Should have 2 children: "Outer Item" element and inner container
            XCTAssertEqual(outerChildren.count, 2)

            // Find the outer item element
            let outerElements = outerChildren.compactMap { node -> AccessibilityElement? in
                if case .element(let element, _) = node { return element }
                return nil
            }
            XCTAssertEqual(outerElements.count, 1)
            XCTAssertEqual(outerElements.first?.description, "Outer Item")

            // Find the inner container
            let innerContainers = outerChildren.compactMap { node -> (AccessibilityContainer, [AccessibilityHierarchy])? in
                if case .container(let info, let children) = node { return (info, children) }
                return nil
            }
            XCTAssertEqual(innerContainers.count, 1)
            XCTAssertEqual(innerContainers.first?.0.label, "Inner Container")
            XCTAssertEqual(innerContainers.first?.0.type, .semanticGroup)

            // Inner container should have 2 element children
            if let innerChildren = innerContainers.first?.1 {
                let innerElements = innerChildren.compactMap { node -> AccessibilityElement? in
                    if case .element(let element, _) = node { return element }
                    return nil
                }
                XCTAssertEqual(innerElements.count, 2)
                XCTAssertEqual(innerElements.map { $0.description }, ["Inner Item 1", "Inner Item 2"])
            }
        } else {
            XCTFail("Expected outer container")
        }

        // Verify flattening produces correct element order
        let flattenedElements = hierarchy.flattenToElements()
        XCTAssertEqual(flattenedElements.map { $0.description }, ["Outer Item", "Inner Item 1", "Inner Item 2"])

        // Verify flattenToContainers gets both containers
        let containers = hierarchy.flattenToContainers()
        XCTAssertEqual(containers.count, 2)
        XCTAssertEqual(Set(containers.map { $0.label }), ["Outer Container", "Inner Container"])
    }

    func testHierarchySortOrder() {
        let rootView = UIView(frame: .init(x: 0, y: 0, width: 100, height: 100))

        // Add elements in reverse order
        let elementC = UIView(frame: .init(x: 0, y: 60, width: 30, height: 30))
        elementC.isAccessibilityElement = true
        elementC.accessibilityLabel = "C"
        elementC.accessibilityFrame = CGRect(x: 0, y: 60, width: 30, height: 30)
        rootView.addSubview(elementC)

        let elementB = UIView(frame: .init(x: 0, y: 30, width: 30, height: 30))
        elementB.isAccessibilityElement = true
        elementB.accessibilityLabel = "B"
        elementB.accessibilityFrame = CGRect(x: 0, y: 30, width: 30, height: 30)
        rootView.addSubview(elementB)

        let elementA = UIView(frame: .init(x: 0, y: 0, width: 30, height: 30))
        elementA.isAccessibilityElement = true
        elementA.accessibilityLabel = "A"
        elementA.accessibilityFrame = CGRect(x: 0, y: 0, width: 30, height: 30)
        rootView.addSubview(elementA)

        let parser = AccessibilityHierarchyParser()
        let hierarchy = parser.parseAccessibilityHierarchy(in: rootView)
        let flattenedDescriptions = hierarchy.flattenToElements().map { $0.description }

        // Should be sorted by position (top to bottom)
        XCTAssertEqual(flattenedDescriptions, ["A", "B", "C"])
    }

    func testContainerChildrenSortOrder() {
        let rootView = UIView(frame: .init(x: 0, y: 0, width: 100, height: 200))

        let container = UIView(frame: .init(x: 0, y: 0, width: 100, height: 200))
        container.accessibilityContainerType = .list
        rootView.addSubview(container)

        // Add in reverse order
        let item3 = UIView(frame: .init(x: 0, y: 120, width: 100, height: 30))
        item3.isAccessibilityElement = true
        item3.accessibilityLabel = "Third"
        item3.accessibilityFrame = CGRect(x: 0, y: 120, width: 100, height: 30)
        container.addSubview(item3)

        let item1 = UIView(frame: .init(x: 0, y: 0, width: 100, height: 30))
        item1.isAccessibilityElement = true
        item1.accessibilityLabel = "First"
        item1.accessibilityFrame = CGRect(x: 0, y: 0, width: 100, height: 30)
        container.addSubview(item1)

        let item2 = UIView(frame: .init(x: 0, y: 60, width: 100, height: 30))
        item2.isAccessibilityElement = true
        item2.accessibilityLabel = "Second"
        item2.accessibilityFrame = CGRect(x: 0, y: 60, width: 100, height: 30)
        container.addSubview(item2)

        let parser = AccessibilityHierarchyParser()
        let hierarchy = parser.parseAccessibilityHierarchy(in: rootView)

        if case .container(_, let children) = hierarchy.first {
            let childDescriptions = children.compactMap { node -> String? in
                if case .element(let element, _) = node { return element.description }
                return nil
            }
            // Children should be sorted by position
            XCTAssertEqual(childDescriptions, ["First", "Second", "Third"])
        } else {
            XCTFail("Expected list container")
        }
    }

    func testFlattenToContainers() {
        let rootView = UIView(frame: .init(x: 0, y: 0, width: 200, height: 200))

        let list = UIView(frame: .init(x: 0, y: 0, width: 100, height: 100))
        list.accessibilityContainerType = .list
        list.accessibilityLabel = "My List"
        rootView.addSubview(list)

        let landmark = UIView(frame: .init(x: 100, y: 0, width: 100, height: 100))
        landmark.accessibilityContainerType = .landmark
        landmark.accessibilityLabel = "My Landmark"
        rootView.addSubview(landmark)

        let listItem = UIView(frame: .init(x: 10, y: 10, width: 30, height: 30))
        listItem.isAccessibilityElement = true
        listItem.accessibilityLabel = "List Item"
        listItem.accessibilityFrame = CGRect(x: 10, y: 10, width: 30, height: 30)
        list.addSubview(listItem)

        let landmarkContent = UIView(frame: .init(x: 110, y: 10, width: 30, height: 30))
        landmarkContent.isAccessibilityElement = true
        landmarkContent.accessibilityLabel = "Landmark Content"
        landmarkContent.accessibilityFrame = CGRect(x: 110, y: 10, width: 30, height: 30)
        landmark.addSubview(landmarkContent)

        let parser = AccessibilityHierarchyParser()
        let hierarchy = parser.parseAccessibilityHierarchy(in: rootView)
        let containers = hierarchy.flattenToContainers()

        XCTAssertEqual(containers.count, 2)

        let containerTypes = Set(containers.map { $0.type })
        XCTAssertTrue(containerTypes.contains(.list))
        XCTAssertTrue(containerTypes.contains(.landmark))

        let containerLabels = Set(containers.compactMap { $0.label })
        XCTAssertTrue(containerLabels.contains("My List"))
        XCTAssertTrue(containerLabels.contains("My Landmark"))
    }
}

// MARK: -

private struct TestUserInterfaceLayoutDirectionProvider: UserInterfaceLayoutDirectionProviding {

    var userInterfaceLayoutDirection: UIUserInterfaceLayoutDirection

}

private struct TestUserInterfaceIdiomProvider: UserInterfaceIdiomProviding {

    var userInterfaceIdiom: UIUserInterfaceIdiom

}

// MARK: - Nested Container Test Views

/// Reusable container view for testing container hierarchy parsing
private final class TestContainerView: UIView {

    let containerType: UIAccessibilityContainerType

    init(
        frame: CGRect,
        containerType: UIAccessibilityContainerType,
        label: String? = nil,
        value: String? = nil
    ) {
        self.containerType = containerType
        super.init(frame: frame)
        self.accessibilityLabel = label
        self.accessibilityValue = value
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var accessibilityContainerType: UIAccessibilityContainerType {
        get { containerType }
        set { }
    }
}

/// Creates a nested hierarchy similar to ContainerHierarchyViewController's NestedContainersDemoView:
/// - Outer semantic group container (with label)
///   - "Outer Item" element
///   - Inner semantic group container (with label)
///     - "Inner Item 1" element
///     - "Inner Item 2" element
private final class NestedContainersTestView: UIView {

    let outerContainer: TestContainerView
    let innerContainer: TestContainerView
    let outerItemLabel: UILabel
    let innerItem1Label: UILabel
    let innerItem2Label: UILabel

    override init(frame: CGRect) {
        // Create outer container
        outerContainer = TestContainerView(
            frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height),
            containerType: .semanticGroup,
            label: "Outer Container"
        )

        // Create outer item
        outerItemLabel = UILabel(frame: CGRect(x: 8, y: 8, width: 100, height: 20))
        outerItemLabel.text = "Outer Item"
        outerItemLabel.accessibilityFrame = CGRect(x: 8, y: 8, width: 100, height: 20)

        // Create inner container
        innerContainer = TestContainerView(
            frame: CGRect(x: 8, y: 36, width: frame.width - 16, height: 60),
            containerType: .semanticGroup,
            label: "Inner Container"
        )

        // Create inner items
        innerItem1Label = UILabel(frame: CGRect(x: 8, y: 8, width: 100, height: 20))
        innerItem1Label.text = "Inner Item 1"
        innerItem1Label.accessibilityFrame = CGRect(x: 16, y: 44, width: 100, height: 20)

        innerItem2Label = UILabel(frame: CGRect(x: 8, y: 32, width: 100, height: 20))
        innerItem2Label.text = "Inner Item 2"
        innerItem2Label.accessibilityFrame = CGRect(x: 16, y: 68, width: 100, height: 20)

        super.init(frame: frame)

        // Build hierarchy
        innerContainer.addSubview(innerItem1Label)
        innerContainer.addSubview(innerItem2Label)

        outerContainer.addSubview(outerItemLabel)
        outerContainer.addSubview(innerContainer)

        addSubview(outerContainer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

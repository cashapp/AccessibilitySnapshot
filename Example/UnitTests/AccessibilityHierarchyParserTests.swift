@testable import AccessibilitySnapshotCore
@testable import AccessibilitySnapshotParser
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

        let ltrElements = parser.parseAccessibilityHierarchy(
            in: gridView,
            userInterfaceLayoutDirectionProvider: TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .phone)
        ).flattenToElements().map { $0.description }
        XCTAssertEqual(ltrElements, ["A", "B", "C", "D"])

        let rtlElements = parser.parseAccessibilityHierarchy(
            in: gridView,
            userInterfaceLayoutDirectionProvider: TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .rightToLeft),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .phone)
        ).flattenToElements().map { $0.description }
        XCTAssertEqual(rtlElements, ["B", "A", "D", "C"])
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

        let elementC = UIView(frame: .init(x: 20, y: -magicNumber, width: 10, height: 10))
        elementC.isAccessibilityElement = true
        elementC.accessibilityLabel = "C"
        elementC.accessibilityFrame = elementC.frame
        gridView.addSubview(elementC)

        let elementD = UIView(frame: .init(x: 30, y: -magicNumber, width: 10, height: 10))
        elementD.isAccessibilityElement = true
        elementD.accessibilityLabel = "D"
        elementD.accessibilityFrame = elementD.frame
        gridView.addSubview(elementD)

        let parser = AccessibilityHierarchyParser()

        let padElements = parser.parseAccessibilityHierarchy(
            in: gridView,
            userInterfaceLayoutDirectionProvider:
            TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .pad)
        ).flattenToElements().map { $0.description }
        // on pad elements are sorted horizontally
        XCTAssertEqual(padElements, ["A", "B", "C", "D"])

        let phoneElements = parser.parseAccessibilityHierarchy(
            in: gridView,
            userInterfaceLayoutDirectionProvider:
            TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .phone)
        ).flattenToElements().map { $0.description }
        // on phone elements are sorted vertically and then left to right
        XCTAssertEqual(phoneElements, ["C", "D", "B", "A"])

        let padMagicNumber = 25

        elementA.accessibilityFrame = .init(x: 0, y: padMagicNumber, width: 10, height: 10)
        elementB.accessibilityFrame = .init(x: 10, y: 0, width: 0, height: 10)
        elementC.accessibilityFrame = .init(x: 20, y: -padMagicNumber, width: 10, height: 10)
        elementD.accessibilityFrame = .init(x: 30, y: -padMagicNumber, width: 10, height: 10)

        let padAgain = parser.parseAccessibilityHierarchy(
            in: gridView,
            userInterfaceLayoutDirectionProvider:
            TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .pad)
        ).flattenToElements().map { $0.description }

        // Now pad elements are sorted vertically and then left to right
        XCTAssertEqual(padAgain, ["C", "D", "B", "A"])
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
        if case let .container(containerInfo, children) = hierarchy.first {
            if case let .semanticGroup(label, _, _) = containerInfo.type {
                XCTAssertEqual(label, "Group Label")
            } else {
                XCTFail("Expected semanticGroup container type")
            }
            XCTAssertEqual(children.count, 1)

            // Verify child element
            if case let .element(childElement, _) = children.first {
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
        if case let .element(elementInfo, _) = hierarchy.first {
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

        if case let .container(containerInfo, children) = hierarchy.first {
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

        if case let .container(containerInfo, _) = hierarchy.first {
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

        if case let .container(outerInfo, outerChildren) = hierarchy.first {
            if case let .semanticGroup(label, _, _) = outerInfo.type {
                XCTAssertEqual(label, "Outer Container")
            } else {
                XCTFail("Expected semanticGroup container type for outer")
            }

            // Should have 2 children: "Outer Item" element and inner container
            XCTAssertEqual(outerChildren.count, 2)

            // Find the outer item element
            let outerElements = outerChildren.compactMap { node -> AccessibilityElement? in
                if case let .element(element, _) = node { return element }
                return nil
            }
            XCTAssertEqual(outerElements.count, 1)
            XCTAssertEqual(outerElements.first?.description, "Outer Item")

            // Find the inner container
            let innerContainers = outerChildren.compactMap { node -> (AccessibilityContainer, [AccessibilityHierarchy])? in
                if case let .container(info, children) = node { return (info, children) }
                return nil
            }
            XCTAssertEqual(innerContainers.count, 1)
            if let innerContainer = innerContainers.first?.0,
               case let .semanticGroup(label, _, _) = innerContainer.type
            {
                XCTAssertEqual(label, "Inner Container")
            } else {
                XCTFail("Expected semanticGroup container type for inner")
            }

            // Inner container should have 2 element children
            if let innerChildren = innerContainers.first?.1 {
                let innerElements = innerChildren.compactMap { node -> AccessibilityElement? in
                    if case let .element(element, _) = node { return element }
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
        let containerLabels = containers.compactMap { container -> String? in
            if case let .semanticGroup(label, _, _) = container.type { return label }
            return nil
        }
        XCTAssertEqual(Set(containerLabels), ["Outer Container", "Inner Container"])
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

        if case let .container(_, children) = hierarchy.first {
            let childDescriptions = children.compactMap { node -> String? in
                if case let .element(element, _) = node { return element.description }
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

        let hasListContainer = containers.contains {
            if case .list = $0.type { return true }
            return false
        }
        let hasLandmarkContainer = containers.contains {
            if case .landmark = $0.type { return true }
            return false
        }
        XCTAssertTrue(hasListContainer)
        XCTAssertTrue(hasLandmarkContainer)
    }

    // MARK: - Codable Tests

    func testAccessibilityElementCodable() throws {
        let element = AccessibilityElement(
            description: "Test Button",
            label: "Button Label",
            value: "Button Value",
            traits: [.button, .selected],
            identifier: "test-button-id",
            hint: "Double tap to activate",
            userInputLabels: ["tap button", "press button"],
            shape: .frame(CGRect(x: 10, y: 20, width: 100, height: 44)),
            activationPoint: CGPoint(x: 60, y: 42),
            usesDefaultActivationPoint: true,
            customActions: [AccessibilityElement.CustomAction(name: "Delete", image: nil)],
            customContent: [],
            customRotors: [],
            accessibilityLanguage: "en-US",
            respondsToUserInteraction: true,
            containerContext: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(element)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AccessibilityElement.self, from: data)

        XCTAssertEqual(decoded.description, element.description)
        XCTAssertEqual(decoded.label, element.label)
        XCTAssertEqual(decoded.value, element.value)
        XCTAssertEqual(decoded.traits, element.traits)
        XCTAssertEqual(decoded.identifier, element.identifier)
        XCTAssertEqual(decoded.hint, element.hint)
        XCTAssertEqual(decoded.userInputLabels, element.userInputLabels)
        XCTAssertEqual(decoded.shape, element.shape)
        XCTAssertEqual(decoded.activationPoint, element.activationPoint)
        XCTAssertEqual(decoded.usesDefaultActivationPoint, element.usesDefaultActivationPoint)
        XCTAssertEqual(decoded.customActions.map { $0.name }, element.customActions.map { $0.name })
        XCTAssertEqual(decoded.accessibilityLanguage, element.accessibilityLanguage)
        XCTAssertEqual(decoded.respondsToUserInteraction, element.respondsToUserInteraction)
    }

    func testAccessibilityContainerCodable() throws {
        let container = AccessibilityContainer(
            type: .list,
            frame: CGRect(x: 0, y: 0, width: 320, height: 200)
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(container)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AccessibilityContainer.self, from: data)

        XCTAssertEqual(decoded.type, .list)
        XCTAssertEqual(decoded.frame, container.frame)
    }

    func testAccessibilityHierarchyCodable() throws {
        let element1 = AccessibilityElement(
            description: "Item 1",
            label: "Item 1",
            value: nil,
            traits: [],
            identifier: nil,
            hint: nil,
            userInputLabels: nil,
            shape: .frame(CGRect(x: 0, y: 0, width: 100, height: 44)),
            activationPoint: CGPoint(x: 50, y: 22),
            usesDefaultActivationPoint: true,
            customActions: [],
            customContent: [],
            customRotors: [],
            accessibilityLanguage: nil,
            respondsToUserInteraction: false,
            containerContext: nil
        )

        let element2 = AccessibilityElement(
            description: "Item 2",
            label: "Item 2",
            value: nil,
            traits: [],
            identifier: nil,
            hint: nil,
            userInputLabels: nil,
            shape: .frame(CGRect(x: 0, y: 50, width: 100, height: 44)),
            activationPoint: CGPoint(x: 50, y: 72),
            usesDefaultActivationPoint: true,
            customActions: [],
            customContent: [],
            customRotors: [],
            accessibilityLanguage: nil,
            respondsToUserInteraction: false,
            containerContext: nil
        )

        let container = AccessibilityContainer(
            type: .list,
            frame: CGRect(x: 0, y: 0, width: 100, height: 100)
        )

        let hierarchy: [AccessibilityHierarchy] = [
            .container(container, children: [
                .element(element1, traversalIndex: 0),
                .element(element2, traversalIndex: 1),
            ]),
        ]

        let encoder = JSONEncoder()
        let data = try encoder.encode(hierarchy)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode([AccessibilityHierarchy].self, from: data)

        XCTAssertEqual(decoded.count, 1)

        if case let .container(decodedContainer, children) = decoded.first {
            XCTAssertEqual(decodedContainer.type, .list)
            XCTAssertEqual(children.count, 2)

            if case let .element(child1, index1) = children[0] {
                XCTAssertEqual(child1.description, "Item 1")
                XCTAssertEqual(index1, 0)
            } else {
                XCTFail("Expected element child")
            }

            if case let .element(child2, index2) = children[1] {
                XCTAssertEqual(child2.description, "Item 2")
                XCTAssertEqual(index2, 1)
            } else {
                XCTFail("Expected element child")
            }
        } else {
            XCTFail("Expected container at root")
        }
    }

    func testShapeCodableWithPath() throws {
        let path = UIBezierPath(roundedRect: CGRect(x: 10, y: 20, width: 100, height: 50), cornerRadius: 8)
        let shape = AccessibilityElement.Shape.path(path)

        let encoder = JSONEncoder()
        let data = try encoder.encode(shape)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AccessibilityElement.Shape.self, from: data)

        if case let .path(decodedPath) = decoded {
            XCTAssertEqual(decodedPath.bounds, path.bounds)
        } else {
            XCTFail("Expected path shape")
        }
    }

    func testContainerTypeCodable() throws {
        let types: [AccessibilityContainer.ContainerType] = [
            .list,
            .landmark,
            .tabBar,
            .semanticGroup(label: "Test", value: nil, identifier: "test-id"),
            .dataTable(rowCount: 3, columnCount: 4),
        ]

        for type in types {
            let encoder = JSONEncoder()
            let data = try encoder.encode(type)

            let decoder = JSONDecoder()
            let decoded = try decoder.decode(AccessibilityContainer.ContainerType.self, from: data)

            XCTAssertEqual(decoded, type)
        }
    }

    func testTraitsCodable() throws {
        let traits: UIAccessibilityTraits = [.button, .selected, .header, .link]

        let encoder = JSONEncoder()
        let data = try encoder.encode(traits)

        // Verify human-readable format (array of trait names)
        let jsonArray = try JSONSerialization.jsonObject(with: data) as! [String]
        XCTAssertTrue(jsonArray.contains("button"), "Traits should include 'button'")
        XCTAssertTrue(jsonArray.contains("selected"), "Traits should include 'selected'")
        XCTAssertTrue(jsonArray.contains("header"), "Traits should include 'header'")
        XCTAssertTrue(jsonArray.contains("link"), "Traits should include 'link'")

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(UIAccessibilityTraits.self, from: data)

        XCTAssertEqual(decoded, traits)
    }

    func testTraitsEmptyEncodesAsEmptyArray() throws {
        let traits: UIAccessibilityTraits = []

        let encoder = JSONEncoder()
        let data = try encoder.encode(traits)

        let jsonString = String(data: data, encoding: .utf8)!
        XCTAssertEqual(jsonString, "[]", "Empty traits should encode as empty array")

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(UIAccessibilityTraits.self, from: data)

        XCTAssertEqual(decoded, traits)
    }

    func testShapePathEncodesAsPathElements() throws {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 100, y: 0))
        path.addLine(to: CGPoint(x: 100, y: 50))
        path.close()

        let shape = AccessibilityElement.Shape.path(path)

        let encoder = JSONEncoder()
        let data = try encoder.encode(shape)

        // Verify round-trip works
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AccessibilityElement.Shape.self, from: data)

        if case let .path(decodedPath) = decoded {
            XCTAssertEqual(decodedPath.bounds, path.bounds)
        } else {
            XCTFail("Expected path shape")
        }
    }

    func testCustomActionWithImageCodable() throws {
        // Create a simple red image for testing
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        let testImage = renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }

        let action = AccessibilityElement.CustomAction(name: "Delete", image: testImage)

        let encoder = JSONEncoder()
        let data = try encoder.encode(action)

        // Verify imageData and imageScale are included
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["name"] as? String, "Delete")
        XCTAssertNotNil(json["imageData"], "Image should be encoded as imageData")
        XCTAssertNotNil(json["imageScale"], "Image scale should be encoded")

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AccessibilityElement.CustomAction.self, from: data)

        XCTAssertEqual(decoded.name, "Delete")
        XCTAssertNotNil(decoded.image, "Image should be decoded")
        XCTAssertEqual(decoded.image?.size, testImage.size, "Image size should be preserved")
        XCTAssertEqual(decoded.image?.scale, testImage.scale, "Image scale should be preserved")
    }

    func testCustomActionWithoutImageCodable() throws {
        let action = AccessibilityElement.CustomAction(name: "Edit", image: nil)

        let encoder = JSONEncoder()
        let data = try encoder.encode(action)

        // Verify imageData is not included when image is nil
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["name"] as? String, "Edit")
        XCTAssertNil(json["imageData"], "imageData should not be present when image is nil")

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AccessibilityElement.CustomAction.self, from: data)

        XCTAssertEqual(decoded.name, "Edit")
        XCTAssertNil(decoded.image)
    }

    // MARK: - Data Table Tests

    func testDataTableContainerWithDimensions() {
        let rootView = UIView(frame: .init(x: 0, y: 0, width: 200, height: 200))

        let dataTable = TestDataTableView(
            frame: CGRect(x: 0, y: 0, width: 200, height: 200),
            rows: 5,
            columns: 4
        )
        rootView.addSubview(dataTable)

        // Add some cells
        let cell1 = TestDataTableCell(row: 0, column: 0, label: "A1")
        cell1.frame = CGRect(x: 0, y: 0, width: 50, height: 40)
        cell1.accessibilityFrame = CGRect(x: 0, y: 0, width: 50, height: 40)
        dataTable.addSubview(cell1)
        dataTable.cells[CellIndex(row: 0, column: 0)] = cell1

        let cell2 = TestDataTableCell(row: 0, column: 1, label: "B1")
        cell2.frame = CGRect(x: 50, y: 0, width: 50, height: 40)
        cell2.accessibilityFrame = CGRect(x: 50, y: 0, width: 50, height: 40)
        dataTable.addSubview(cell2)
        dataTable.cells[CellIndex(row: 0, column: 1)] = cell2

        let parser = AccessibilityHierarchyParser()
        let hierarchy = parser.parseAccessibilityHierarchy(in: rootView)

        // Should have one container with dataTable type
        XCTAssertEqual(hierarchy.count, 1)

        if case let .container(container, children) = hierarchy.first {
            if case let .dataTable(rowCount, columnCount) = container.type {
                XCTAssertEqual(rowCount, 5)
                XCTAssertEqual(columnCount, 4)
            } else {
                XCTFail("Expected dataTable container type")
            }
            XCTAssertEqual(children.count, 2)
        } else {
            XCTFail("Expected dataTable container")
        }
    }

    func testDataTableContainerCodable() throws {
        let container = AccessibilityContainer(
            type: .dataTable(rowCount: 5, columnCount: 4),
            frame: CGRect(x: 0, y: 0, width: 320, height: 200)
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(container)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AccessibilityContainer.self, from: data)

        if case let .dataTable(rowCount, columnCount) = decoded.type {
            XCTAssertEqual(rowCount, 5)
            XCTAssertEqual(columnCount, 4)
        } else {
            XCTFail("Expected dataTable type")
        }
    }

    func testSemanticGroupContainerCodable() throws {
        let container = AccessibilityContainer(
            type: .semanticGroup(label: "Group Label", value: "Group Value", identifier: "group-id"),
            frame: CGRect(x: 0, y: 0, width: 200, height: 100)
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(container)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AccessibilityContainer.self, from: data)

        if case let .semanticGroup(label, value, identifier) = decoded.type {
            XCTAssertEqual(label, "Group Label")
            XCTAssertEqual(value, "Group Value")
            XCTAssertEqual(identifier, "group-id")
        } else {
            XCTFail("Expected semanticGroup type")
        }
    }

    func testTabBarContainerCodable() throws {
        let container = AccessibilityContainer(
            type: .tabBar,
            frame: CGRect(x: 0, y: 0, width: 320, height: 49)
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(container)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AccessibilityContainer.self, from: data)

        XCTAssertEqual(decoded.type, .tabBar)
    }

    func testLandmarkContainerCodable() throws {
        let container = AccessibilityContainer(
            type: .landmark,
            frame: CGRect(x: 0, y: 0, width: 320, height: 200)
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(container)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AccessibilityContainer.self, from: data)

        XCTAssertEqual(decoded.type, .landmark)
    }

    // MARK: - High-Importance Custom Content Tests

    func testHighImportanceCustomContentIncludedInDescription() {
        let element = AccessibilityElement(
            description: "Photo, 42",
            label: "Photo",
            value: nil,
            traits: .image,
            identifier: nil,
            hint: nil,
            userInputLabels: nil,
            shape: .frame(.zero),
            activationPoint: .zero,
            usesDefaultActivationPoint: true,
            customActions: [],
            customContent: [
                .init(label: "Likes", value: "42", isImportant: true),
                .init(label: "Comments", value: "5", isImportant: false),
            ],
            customRotors: [],
            accessibilityLanguage: nil,
            respondsToUserInteraction: false,
            containerContext: nil
        )

        // High-importance content value should be in description (comma-separated)
        XCTAssertTrue(element.description.contains(", 42"))

        // Default-importance content should NOT be in description
        XCTAssertFalse(element.description.contains("5"))
    }

    func testHighImportanceContentAppearsBeforeTraits() {
        let element = AccessibilityElement(
            description: "Bailey: beagle, three years. Image.",
            label: "Bailey",
            value: "beagle",
            traits: .image,
            identifier: nil,
            hint: nil,
            userInputLabels: nil,
            shape: .frame(.zero),
            activationPoint: .zero,
            usesDefaultActivationPoint: true,
            customActions: [],
            customContent: [
                .init(label: "Age", value: "three years", isImportant: true),
            ],
            customRotors: [],
            accessibilityLanguage: nil,
            respondsToUserInteraction: false,
            containerContext: nil
        )

        // Per WWDC21: "Bailey, beagle, three years. Image."
        let desc = element.description
        let customContentIndex = desc.range(of: "three years")!.lowerBound
        let traitIndex = desc.range(of: "Image")!.lowerBound
        XCTAssertTrue(customContentIndex < traitIndex)
    }

    func testMultipleHighImportanceContentItems() {
        let element = AccessibilityElement(
            description: "Tweet, 100, 25",
            label: "Tweet",
            value: nil,
            traits: [],
            identifier: nil,
            hint: nil,
            userInputLabels: nil,
            shape: .frame(.zero),
            activationPoint: .zero,
            usesDefaultActivationPoint: true,
            customActions: [],
            customContent: [
                .init(label: "Likes", value: "100", isImportant: true),
                .init(label: "Retweets", value: "25", isImportant: true),
            ],
            customRotors: [],
            accessibilityLanguage: nil,
            respondsToUserInteraction: false,
            containerContext: nil
        )

        // Both values should appear
        XCTAssertTrue(element.description.contains("100"))
        XCTAssertTrue(element.description.contains("25"))
    }

    func testHighImportanceContentWithEmptyValue() {
        let element = AccessibilityElement(
            description: "Status, Verified",
            label: "Status",
            value: nil,
            traits: [],
            identifier: nil,
            hint: nil,
            userInputLabels: nil,
            shape: .frame(.zero),
            activationPoint: .zero,
            usesDefaultActivationPoint: true,
            customActions: [],
            customContent: [
                .init(label: "Verified", value: "", isImportant: true),
            ],
            customRotors: [],
            accessibilityLanguage: nil,
            respondsToUserInteraction: false,
            containerContext: nil
        )

        // Should include label when value is empty
        XCTAssertTrue(element.description.contains("Verified"))
    }

    func testCustomContentCodable() throws {
        let content = AccessibilityElement.CustomContent(
            label: "Rating",
            value: "5 stars",
            isImportant: true
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(content)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AccessibilityElement.CustomContent.self, from: data)

        XCTAssertEqual(decoded.label, "Rating")
        XCTAssertEqual(decoded.value, "5 stars")
        XCTAssertEqual(decoded.isImportant, true)
    }

    func testElementWithCustomContentCodable() throws {
        let element = AccessibilityElement(
            description: "Photo, 42",
            label: "Photo",
            value: nil,
            traits: .image,
            identifier: nil,
            hint: nil,
            userInputLabels: nil,
            shape: .frame(.zero),
            activationPoint: .zero,
            usesDefaultActivationPoint: true,
            customActions: [],
            customContent: [
                .init(label: "Likes", value: "42", isImportant: true),
                .init(label: "Comments", value: "5", isImportant: false),
            ],
            customRotors: [],
            accessibilityLanguage: nil,
            respondsToUserInteraction: false,
            containerContext: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(element)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AccessibilityElement.self, from: data)

        XCTAssertEqual(decoded.customContent.count, 2)
        XCTAssertEqual(decoded.customContent[0].label, "Likes")
        XCTAssertEqual(decoded.customContent[0].value, "42")
        XCTAssertEqual(decoded.customContent[0].isImportant, true)
        XCTAssertEqual(decoded.customContent[1].label, "Comments")
        XCTAssertEqual(decoded.customContent[1].value, "5")
        XCTAssertEqual(decoded.customContent[1].isImportant, false)
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
        accessibilityLabel = label
        accessibilityValue = value
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var accessibilityContainerType: UIAccessibilityContainerType {
        get { containerType }
        set {}
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

// MARK: - Data Table Test Views

private struct CellIndex: Hashable {
    let row: Int
    let column: Int
}

/// Test view that conforms to UIAccessibilityContainerDataTable
private final class TestDataTableView: UIView, UIAccessibilityContainerDataTable {
    let rows: Int
    let columns: Int
    var cells: [CellIndex: TestDataTableCell] = [:]

    init(frame: CGRect, rows: Int, columns: Int) {
        self.rows = rows
        self.columns = columns
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var accessibilityContainerType: UIAccessibilityContainerType {
        get { .dataTable }
        set {}
    }

    // MARK: - UIAccessibilityContainerDataTable

    func accessibilityDataTableCellElement(forRow row: Int, column: Int) -> UIAccessibilityContainerDataTableCell? {
        return cells[CellIndex(row: row, column: column)]
    }

    func accessibilityRowCount() -> Int {
        return rows
    }

    func accessibilityColumnCount() -> Int {
        return columns
    }
}

/// Test cell that conforms to UIAccessibilityContainerDataTableCell
private final class TestDataTableCell: UIView, UIAccessibilityContainerDataTableCell {
    let row: Int
    let column: Int

    init(row: Int, column: Int, label: String) {
        self.row = row
        self.column = column
        super.init(frame: .zero)
        isAccessibilityElement = true
        accessibilityLabel = label
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIAccessibilityContainerDataTableCell

    func accessibilityRowRange() -> NSRange {
        return NSRange(location: row, length: 1)
    }

    func accessibilityColumnRange() -> NSRange {
        return NSRange(location: column, length: 1)
    }
}

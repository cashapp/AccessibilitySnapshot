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

    // MARK: - Activation Point Default Detection

    func testZeroFrameAndZeroActivationPointIsDefault() {
        let container = UIView(frame: .init(x: 0, y: 0, width: 400, height: 400))

        let element = ActivationPointTestView(frame: .init(x: 10, y: 10, width: 100, height: 50))
        element.isAccessibilityElement = true
        element.accessibilityLabel = "Zero"
        element.overriddenFrame = .zero
        element.overriddenActivationPoint = .zero
        container.addSubview(element)

        let markers = parseMarkers(in: container)
        XCTAssertEqual(markers.count, 1)
        XCTAssertTrue(markers[0].usesDefaultActivationPoint)
    }

    func testZeroFrameWithPathAndValidActivationPointIsDefault() {
        let container = UIView(frame: .init(x: 0, y: 0, width: 400, height: 400))

        let pathBounds = CGRect(x: 16, y: 16, width: 370, height: 48)
        let element = ActivationPointTestView(frame: .init(x: 10, y: 10, width: 370, height: 48))
        element.isAccessibilityElement = true
        element.accessibilityLabel = "PathElement"
        element.overriddenFrame = .zero
        element.overriddenPath = UIBezierPath(rect: pathBounds)
        element.overriddenActivationPoint = CGPoint(x: pathBounds.midX, y: pathBounds.midY)
        container.addSubview(element)

        let markers = parseMarkers(in: container)
        XCTAssertEqual(markers.count, 1)
        XCTAssertTrue(markers[0].usesDefaultActivationPoint)
    }

    func testNormalFrameWithCenterActivationPointIsDefault() {
        let container = UIView(frame: .init(x: 0, y: 0, width: 400, height: 400))

        let frame = CGRect(x: 50, y: 50, width: 200, height: 60)
        let element = ActivationPointTestView(frame: frame)
        element.isAccessibilityElement = true
        element.accessibilityLabel = "Centered"
        element.accessibilityTraits = .adjustable
        element.accessibilityHint = "Change the amount"
        element.overriddenFrame = frame
        element.overriddenActivationPoint = CGPoint(x: frame.midX, y: frame.midY)
        container.addSubview(element)

        let markers = parseMarkers(in: container)
        XCTAssertEqual(markers.count, 1)
        XCTAssertTrue(markers[0].usesDefaultActivationPoint)
        XCTAssertEqual(markers[0].hint, element.accessibilityDescription(context: nil).hint)
    }

    func testNormalFrameWithCustomActivationPointIsNotDefault() {
        let container = UIView(frame: .init(x: 0, y: 0, width: 400, height: 400))

        let frame = CGRect(x: 50, y: 50, width: 200, height: 60)
        let element = ActivationPointTestView(frame: frame)
        element.isAccessibilityElement = true
        element.accessibilityLabel = "Custom"
        element.overriddenFrame = frame
        element.overriddenActivationPoint = CGPoint(x: frame.maxX - 10, y: frame.midY)
        container.addSubview(element)

        let markers = parseMarkers(in: container)
        XCTAssertEqual(markers.count, 1)
        XCTAssertFalse(markers[0].usesDefaultActivationPoint)
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
            if case let .semanticGroup(label, _) = containerInfo.type {
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

    func testSemanticGroupWithoutLabelIsPreserved() {
        // Container-aware parsing preserves the container node from the graph regardless of whether
        // it carries a label. (Previously an unlabeled semantic group was flattened away; that made
        // it the special case against `testListContainerIsAlwaysPreserved`. The graph-derived model
        // treats all container types consistently.)
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

        // One semantic-group container at root, holding the element.
        XCTAssertEqual(hierarchy.count, 1)

        if case let .container(containerInfo, children) = hierarchy.first {
            guard case .semanticGroup = containerInfo.type else {
                return XCTFail("Expected a semantic-group container")
            }
            XCTAssertEqual(children.count, 1)
            if case let .element(elementInfo, _) = children.first {
                XCTAssertEqual(elementInfo.description, "Element")
            } else {
                XCTFail("Expected the element inside the preserved container")
            }
        } else {
            XCTFail("Expected a container at root level (should be preserved)")
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
            XCTAssertEqual(children.flattenToElements().map { $0.context }, [nil, nil])
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
            if case let .semanticGroup(label, _) = outerInfo.type {
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
               case let .semanticGroup(label, _) = innerContainer.type
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
            if case let .semanticGroup(label, _) = container.type { return label }
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

    func testShapeCodableWithPath() throws {
        let path = UIBezierPath(roundedRect: CGRect(x: 10, y: 20, width: 100, height: 50), cornerRadius: 8)
        let elements = AccessibilityPathElement.elements(from: path.cgPath)
        let shape = AccessibilityShape.path(elements)

        let encoder = JSONEncoder()
        let data = try encoder.encode(shape)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AccessibilityShape.self, from: data)

        if case let .path(decodedPath) = decoded {
            XCTAssertEqual(decodedPath, elements)
        } else {
            XCTFail("Expected path shape")
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

        let elements = AccessibilityPathElement.elements(from: path.cgPath)
        let shape = AccessibilityShape.path(elements)

        let encoder = JSONEncoder()
        let data = try encoder.encode(shape)

        // Verify round-trip works
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AccessibilityShape.self, from: data)

        if case let .path(decodedPath) = decoded {
            XCTAssertEqual(decodedPath, elements)
        } else {
            XCTFail("Expected path shape")
        }
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
            if case let .dataTable(rowCount, columnCount, _) = container.type {
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

    func testDataTableContextCapturesSpansAndNonEmittedHeadersBeforeCallbacks() throws {
        let table = TestDataTableView(
            frame: CGRect(x: 0, y: 0, width: 200, height: 100),
            rows: 4,
            columns: 5
        )
        let first = TestDataTableCell(row: 2, column: 0, label: "First", rowSpan: 2, columnSpan: 2)
        let second = TestDataTableCell(row: 2, column: 2, label: "Second")
        for (index, cell) in [first, second].enumerated() {
            cell.frame = CGRect(x: index * 100, y: 0, width: 90, height: 40)
            cell.accessibilityFrame = cell.frame
            table.addSubview(cell)
            table.cells[CellIndex(row: cell.row, column: cell.column)] = cell
        }
        table.accessibilityElements = [first, second]

        let rowHeader = TestDataTableCell(row: 2, column: 4, label: "Region")
        rowHeader.accessibilityValue = "North"
        let columnHeader = TestDataTableCell(row: 0, column: 0, label: "Revenue")
        columnHeader.accessibilityValue = "USD"
        let precedingHeader = TestDataTableCell(row: 1, column: 0, label: "Immediately preceding")
        let invalidRowHeader = TestDataTableCell(row: 2, column: 3, label: "Not a table cell")
        table.cells[CellIndex(row: 2, column: 4)] = rowHeader
        table.rowHeaders[2] = [first, rowHeader, invalidRowHeader]
        table.columnHeaders[0] = [first, precedingHeader, columnHeader]
        table.columnHeaders[2] = [second, columnHeader]

        let queriedCells = [first, second, rowHeader, columnHeader, precedingHeader, invalidRowHeader]
        var countsAtFirstCallback: [Int]?
        let hierarchy: [AccessibilityHierarchy] = AccessibilityHierarchyParser().parseAccessibilityHierarchy(
            in: table,
            userInterfaceLayoutDirectionProvider: TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .phone),
            makeElement: { element, index, _ in
                if countsAtFirstCallback == nil {
                    countsAtFirstCallback = [table.queryCount] + queriedCells.map { $0.queryCount }
                    table.allowsQueries = false
                    for cell in queriedCells {
                        cell.allowsQueries = false
                    }
                    rowHeader.accessibilityLabel = "Changed region"
                    rowHeader.accessibilityValue = "South"
                    columnHeader.accessibilityLabel = "Changed revenue"
                    columnHeader.accessibilityValue = "EUR"
                }
                return .element(element, traversalIndex: index)
            },
            makeContainer: { container, children, _ in
                .container(container, children: children)
            }
        )

        let capturedCounts = try XCTUnwrap(countsAtFirstCallback)
        XCTAssertGreaterThan(capturedCounts[0], 0)
        XCTAssertEqual([table.queryCount] + queriedCells.map { $0.queryCount }, capturedCounts)

        let elements = hierarchy.flattenToElements()
        XCTAssertEqual(elements.map { $0.context }, [
            .dataTableCell(
                row: 2, column: 0, width: 2, height: 2, isFirstInRow: true,
                rowHeaders: [.init(label: "Region", value: "North")],
                columnHeaders: [.init(label: "Revenue", value: "USD")]
            ),
            .dataTableCell(
                row: 2, column: 2, width: 1, height: 1, isFirstInRow: false,
                rowHeaders: [],
                columnHeaders: [.init(label: "Revenue", value: "USD")]
            ),
        ])
        XCTAssertEqual(elements.map { $0.description }, [
            "Region: North. Revenue: USD. First. Spans 2 rows. Spans 2 columns. Row 3. Column 1.",
            "Revenue: USD. Second. Column 3.",
        ])
        XCTAssertEqual(hierarchy.flattenToContainers().map { $0.type }, [
            .dataTable(rowCount: 4, columnCount: 5, cells: [
                .init(
                    row: 2, column: 0, rowSpan: 2, columnSpan: 2, isFirstInRow: true,
                    rowHeaderChildIndices: [], columnHeaderChildIndices: []
                ),
                .init(
                    row: 2, column: 2, rowSpan: 1, columnSpan: 1, isFirstInRow: false,
                    rowHeaderChildIndices: [], columnHeaderChildIndices: []
                ),
            ]),
        ])
    }

    // MARK: - Zero-Frame Wrapper Views

    /// Verifies that the parser traverses through a zero-frame non-clipping wrapper view to
    /// find accessible children. This reproduces the SwiftUI bridging view hierarchy used by
    /// UISearchController on iOS 26+, where a zero-frame _UIInheritedView wraps visible search
    /// field content.
    func testAccessibleChildrenFoundThroughZeroFrameNonClippingWrapper() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))

        let container = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 116))

        // A zero-frame wrapper that does not clip — children overflow and are visible.
        let zeroFrameWrapper = UIView(frame: .zero)
        zeroFrameWrapper.clipsToBounds = false
        container.addSubview(zeroFrameWrapper)

        let searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: 375, height: 56))
        zeroFrameWrapper.addSubview(searchBar)

        window.addSubview(container)
        window.makeKeyAndVisible()
        container.setNeedsLayout()
        container.layoutIfNeeded()

        let elements = parseMarkers(in: container)

        let hasSearchField = elements.contains { $0.traits.contains(.searchField) }
        XCTAssertTrue(hasSearchField, "Expected the parser to traverse a zero-frame non-clipping wrapper and find the search field.")

        window.resignKey()
        window.isHidden = true
    }

    /// Verifies that the parser still prunes a zero-frame wrapper that clips its bounds, since
    /// clipped children are invisible. This is the complement of
    /// testAccessibleChildrenFoundThroughZeroFrameNonClippingWrapper and ensures the predicate
    /// does not over-allow zero-frame views.
    func testAccessibleChildrenPrunedBehindZeroFrameClippingWrapper() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))

        let container = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 116))

        // A zero-frame wrapper that clips — children are invisible.
        let zeroFrameWrapper = UIView(frame: .zero)
        zeroFrameWrapper.clipsToBounds = true
        container.addSubview(zeroFrameWrapper)

        let searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: 375, height: 56))
        zeroFrameWrapper.addSubview(searchBar)

        window.addSubview(container)
        window.makeKeyAndVisible()
        container.setNeedsLayout()
        container.layoutIfNeeded()

        let elements = parseMarkers(in: container)

        let hasSearchField = elements.contains { $0.traits.contains(.searchField) }
        XCTAssertFalse(hasSearchField, "Expected the parser to prune children behind a zero-frame clipping wrapper.")

        window.resignKey()
        window.isHidden = true
    }

    // MARK: - Sort Order Tests

    /// When accessibilityElements contains only subgroups, the explicit array order
    /// should still be preserved. Verified against VoiceOver on a real device: VoiceOver
    /// respects the accessibilityElements array order regardless of whether children are
    /// direct elements or subgroups.
    func testAccessibilityElementsPreservesOrderEvenWithOnlySubgroups() {
        let rootView = UIView(frame: .init(x: 0, y: 0, width: 200, height: 300))

        // Two container views in accessibilityElements, where cells come before
        // headers in the array but headers are visually above cells.
        let cellContainer = UIView(frame: .init(x: 0, y: 100, width: 200, height: 200))
        cellContainer.shouldGroupAccessibilityChildren = true
        rootView.addSubview(cellContainer)

        let cell1 = UIView(frame: .init(x: 0, y: 0, width: 200, height: 40))
        cell1.isAccessibilityElement = true
        cell1.accessibilityLabel = "Cell 1"
        cell1.accessibilityFrame = CGRect(x: 0, y: 100, width: 200, height: 40)
        cellContainer.addSubview(cell1)

        let cell2 = UIView(frame: .init(x: 0, y: 50, width: 200, height: 40))
        cell2.isAccessibilityElement = true
        cell2.accessibilityLabel = "Cell 2"
        cell2.accessibilityFrame = CGRect(x: 0, y: 150, width: 200, height: 40)
        cellContainer.addSubview(cell2)

        let headerContainer = UIView(frame: .init(x: 0, y: 0, width: 200, height: 90))
        headerContainer.shouldGroupAccessibilityChildren = true
        rootView.addSubview(headerContainer)

        let header = UIView(frame: .init(x: 0, y: 0, width: 200, height: 40))
        header.isAccessibilityElement = true
        header.accessibilityLabel = "Header"
        header.accessibilityFrame = CGRect(x: 0, y: 0, width: 200, height: 40)
        headerContainer.addSubview(header)

        // Set accessibilityElements with cells before headers
        rootView.accessibilityElements = [cellContainer, headerContainer]

        let parser = AccessibilityHierarchyParser()
        let elements = parser.parseAccessibilityHierarchy(
            in: rootView,
            userInterfaceLayoutDirectionProvider: TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .phone)
        ).flattenToElements().map { $0.description }

        // Explicit array order is preserved: cells before header,
        // matching VoiceOver's actual behavior for accessibilityElements.
        XCTAssertEqual(elements, ["Cell 1", "Cell 2", "Header"])
    }

    /// When accessibilityElements contains direct accessibility elements (not just containers),
    /// the explicit array order should be preserved.
    func testMixedAccessibilityElementsPreserveExplicitOrder() {
        let rootView = UIView(frame: .init(x: 0, y: 0, width: 200, height: 200))

        // A direct accessibility element
        let directElement = UIView(frame: .init(x: 0, y: 100, width: 200, height: 40))
        directElement.isAccessibilityElement = true
        directElement.accessibilityLabel = "Direct Element"
        directElement.accessibilityFrame = CGRect(x: 0, y: 100, width: 200, height: 40)
        rootView.addSubview(directElement)

        // A container with a child
        let container = UIView(frame: .init(x: 0, y: 0, width: 200, height: 40))
        container.shouldGroupAccessibilityChildren = true
        rootView.addSubview(container)

        let containerChild = UIView(frame: .init(x: 0, y: 0, width: 200, height: 40))
        containerChild.isAccessibilityElement = true
        containerChild.accessibilityLabel = "Container Child"
        containerChild.accessibilityFrame = CGRect(x: 0, y: 0, width: 200, height: 40)
        container.addSubview(containerChild)

        // Direct element listed first, even though container child is visually above
        rootView.accessibilityElements = [directElement, container]

        let parser = AccessibilityHierarchyParser()
        let elements = parser.parseAccessibilityHierarchy(
            in: rootView,
            userInterfaceLayoutDirectionProvider: TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .phone)
        ).flattenToElements().map { $0.description }

        // Explicit order preserved because there's a direct element in accessibilityElements
        XCTAssertEqual(elements, ["Direct Element", "Container Child"])
    }

    /// Groups should be positioned among siblings by their first child's frame,
    /// not the union of all children's frames. This ensures correct interleaving
    /// when multiple groups have overlapping vertical ranges.
    func testGroupsSortByFirstChildFrame() {
        let rootView = UIView(frame: .init(x: 0, y: 0, width: 200, height: 400))

        // Group A: elements at y=50 and y=300 (union spans y=50..340, first child at y=50)
        let groupA = UIView(frame: .init(x: 0, y: 0, width: 200, height: 400))
        groupA.shouldGroupAccessibilityChildren = true
        rootView.addSubview(groupA)

        let a1 = UIView(frame: .init(x: 0, y: 50, width: 200, height: 40))
        a1.isAccessibilityElement = true
        a1.accessibilityLabel = "A1"
        a1.accessibilityFrame = CGRect(x: 0, y: 50, width: 200, height: 40)
        groupA.addSubview(a1)

        let a2 = UIView(frame: .init(x: 0, y: 300, width: 200, height: 40))
        a2.isAccessibilityElement = true
        a2.accessibilityLabel = "A2"
        a2.accessibilityFrame = CGRect(x: 0, y: 300, width: 200, height: 40)
        groupA.addSubview(a2)

        // Group B: element at y=0 (first child at y=0, should sort before Group A)
        let groupB = UIView(frame: .init(x: 0, y: 0, width: 200, height: 50))
        groupB.shouldGroupAccessibilityChildren = true
        rootView.addSubview(groupB)

        let b1 = UIView(frame: .init(x: 0, y: 0, width: 200, height: 40))
        b1.isAccessibilityElement = true
        b1.accessibilityLabel = "B1"
        b1.accessibilityFrame = CGRect(x: 0, y: 0, width: 200, height: 40)
        groupB.addSubview(b1)

        let parser = AccessibilityHierarchyParser()
        let elements = parser.parseAccessibilityHierarchy(
            in: rootView,
            userInterfaceLayoutDirectionProvider: TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .phone)
        ).flattenToElements().map { $0.description }

        // Group B (first child at y=0) should sort before Group A (first child at y=50)
        XCTAssertEqual(elements, ["B1", "A1", "A2"])
    }

    /// When two groups' first children are within the vertical threshold (8pt on phone),
    /// horizontal position should break the tie — matching the thresholded comparator
    /// used by sortedElements for sibling ordering.
    func testGroupSortFrameRespectsVerticalThreshold() {
        let rootView = UIView(frame: .init(x: 0, y: 0, width: 400, height: 200))

        // Group A: first child at y=0, x=200 (right side)
        let groupA = UIView(frame: .init(x: 200, y: 0, width: 200, height: 100))
        groupA.shouldGroupAccessibilityChildren = true
        rootView.addSubview(groupA)

        let a1 = UIView(frame: .init(x: 0, y: 0, width: 200, height: 40))
        a1.isAccessibilityElement = true
        a1.accessibilityLabel = "A1"
        a1.accessibilityFrame = CGRect(x: 200, y: 0, width: 200, height: 40)
        groupA.addSubview(a1)

        // Group B: first child at y=5 (within 8pt threshold), x=0 (left side)
        let groupB = UIView(frame: .init(x: 0, y: 5, width: 200, height: 100))
        groupB.shouldGroupAccessibilityChildren = true
        rootView.addSubview(groupB)

        let b1 = UIView(frame: .init(x: 0, y: 0, width: 200, height: 40))
        b1.isAccessibilityElement = true
        b1.accessibilityLabel = "B1"
        b1.accessibilityFrame = CGRect(x: 0, y: 5, width: 200, height: 40)
        groupB.addSubview(b1)

        let parser = AccessibilityHierarchyParser()
        let elements = parser.parseAccessibilityHierarchy(
            in: rootView,
            userInterfaceLayoutDirectionProvider: TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .phone)
        ).flattenToElements().map { $0.description }

        // 5pt vertical difference is below the 8pt phone threshold, so horizontal
        // position breaks the tie: B1 (x=0) sorts before A1 (x=200) in LTR.
        XCTAssertEqual(elements, ["B1", "A1"])
    }

    // MARK: - Captured Context

    func testTabTraitContextUsesSortedGraphOrder() {
        let tabBar = UIView(frame: CGRect(x: 0, y: 0, width: 180, height: 40))
        tabBar.accessibilityTraits = .tabBar

        for (label, x) in [("Third", 120), ("First", 0), ("Second", 60)] {
            let tab = UIView(frame: CGRect(x: x, y: 0, width: 50, height: 40))
            tab.isAccessibilityElement = true
            tab.accessibilityLabel = label
            tab.accessibilityTraits = .button
            tab.accessibilityFrame = tab.frame
            tabBar.addSubview(tab)
        }

        let hierarchy = AccessibilityHierarchyParser().parseAccessibilityHierarchy(
            in: tabBar,
            userInterfaceLayoutDirectionProvider: TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .phone)
        )
        let elements = hierarchy.flattenToElements()

        XCTAssertEqual(hierarchy.flattenToContainers().map { $0.type }, [.tabBar])
        XCTAssertEqual(elements.map { $0.label }, ["First", "Second", "Third"])
        XCTAssertEqual(elements.map { $0.context }, [
            .tab(index: 1, count: 3),
            .tab(index: 2, count: 3),
            .tab(index: 3, count: 3),
        ])
        XCTAssertEqual(elements.map { $0.description }, [
            "First. Tab. 1 of 3.",
            "Second. Tab. 2 of 3.",
            "Third. Tab. 3 of 3.",
        ])
    }

    func testSubviewTabTraitContextCountsNestedLeaves() {
        let tabBar = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        tabBar.accessibilityTraits = .tabBar
        let nested = UIView(frame: tabBar.bounds)
        tabBar.addSubview(nested)
        let leaves = ["First", "Second", "Third"].enumerated().map { index, label in
            let leaf = UIView(frame: CGRect(x: 0, y: index * 40, width: 100, height: 30))
            leaf.isAccessibilityElement = true
            leaf.accessibilityLabel = label
            leaf.accessibilityFrame = leaf.frame
            nested.addSubview(leaf)
            return leaf
        }
        nested.accessibilityElements = leaves

        let elements = AccessibilityHierarchyParser().parseAccessibilityHierarchy(in: tabBar).flattenToElements()
        XCTAssertEqual(elements.map { $0.label }, ["First", "Second", "Third"])
        XCTAssertEqual(elements.map { $0.context }, [
            .tab(index: 1, count: 3), .tab(index: 2, count: 3), .tab(index: 3, count: 3),
        ])
    }

    func testSubviewTabTraitContextDistinguishesRepeatedSourceOccurrences() {
        let tabBar = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        tabBar.accessibilityTraits = .tabBar
        let leaf = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
        leaf.isAccessibilityElement = true
        leaf.accessibilityLabel = "Repeated"
        leaf.accessibilityFrame = leaf.frame
        for _ in 0 ..< 2 {
            let wrapper = UIView(frame: tabBar.bounds)
            wrapper.accessibilityElements = [leaf]
            tabBar.addSubview(wrapper)
        }
        var callbackIndices: [Int] = []
        var callbackSources: [NSObject] = []
        let hierarchy: [AccessibilityHierarchy] = AccessibilityHierarchyParser().parseAccessibilityHierarchy(
            in: tabBar,
            makeElement: { element, index, source in
                callbackIndices.append(index)
                callbackSources.append(source)
                return .element(element, traversalIndex: index)
            },
            makeContainer: { container, children, _ in .container(container, children: children) }
        )

        XCTAssertEqual(hierarchy.flattenToElements().map { $0.context }, [
            .tab(index: 1, count: 2), .tab(index: 2, count: 2),
        ])
        XCTAssertEqual(callbackIndices, [0, 1])
        XCTAssertEqual(callbackSources.count, 2)
        XCTAssertTrue(callbackSources.allSatisfy { $0 === leaf })
    }

    func testVendedTabTraitContextKeepsChildGroupPositions() {
        let tabBar = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        tabBar.accessibilityTraits = .tabBar
        let groups = [UIView(frame: tabBar.bounds), UIView(frame: tabBar.bounds)]
        for (index, group) in groups.enumerated() {
            tabBar.addSubview(group)
            let leaves = ["A", "B"].enumerated().map { leafIndex, label in
                let leaf = UIView(frame: CGRect(x: index * 100, y: leafIndex * 40, width: 90, height: 30))
                leaf.isAccessibilityElement = true
                leaf.accessibilityLabel = "\(index + 1)\(label)"
                leaf.accessibilityFrame = leaf.frame
                group.addSubview(leaf)
                return leaf
            }
            group.accessibilityElements = leaves
        }
        tabBar.accessibilityElements = groups

        let elements = AccessibilityHierarchyParser().parseAccessibilityHierarchy(in: tabBar).flattenToElements()
        XCTAssertEqual(elements.map { $0.label }, ["1A", "1B", "2A", "2B"])
        XCTAssertEqual(elements.map { $0.context }, [
            .tab(index: 1, count: 2), .tab(index: 1, count: 2),
            .tab(index: 2, count: 2), .tab(index: 2, count: 2),
        ])
    }

    func testVendedMetadataGroupPreservesSubviewOrderInExplicitParent() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 200))
        let group = UIView(frame: root.bounds)
        group.accessibilityContainerType = .semanticGroup
        root.addSubview(group)
        for (label, y) in [("Bottom", 100), ("Top", 0)] {
            let leaf = UIView(frame: CGRect(x: 0, y: y, width: 100, height: 30))
            leaf.isAccessibilityElement = true
            leaf.accessibilityLabel = label
            leaf.accessibilityFrame = leaf.frame
            group.addSubview(leaf)
        }
        root.accessibilityElements = [group]

        let hierarchy = AccessibilityHierarchyParser().parseAccessibilityHierarchy(in: root)
        XCTAssertEqual(hierarchy.flattenToElements().map { $0.label }, ["Bottom", "Top"])
    }

    func testVendedMetadataGroupsPreserveSubviewOrderInExplicitParent() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 300))
        var groups: [UIView] = []
        for (name, top, bottom) in [("First", 100, 200), ("Last", 0, 250)] {
            let group = UIView(frame: root.bounds)
            group.accessibilityContainerType = .semanticGroup
            let nested = UIView(frame: root.bounds)
            nested.accessibilityContainerType = .semanticGroup
            group.addSubview(nested)
            root.addSubview(group)
            for (parent, label, y) in [(nested, "\(name) Bottom", bottom), (group, "\(name) Top", top)] {
                let leaf = UIView(frame: CGRect(x: 0, y: y, width: 100, height: 30))
                leaf.isAccessibilityElement = true
                leaf.accessibilityLabel = label
                leaf.accessibilityFrame = leaf.frame
                parent.addSubview(leaf)
            }
            groups.append(group)
        }
        let middle = UIView(frame: CGRect(x: 0, y: 50, width: 100, height: 30))
        middle.isAccessibilityElement = true
        middle.accessibilityLabel = "Middle"
        middle.accessibilityFrame = middle.frame
        root.addSubview(middle)
        root.accessibilityElements = [groups[0], middle, groups[1]]

        let hierarchy = AccessibilityHierarchyParser().parseAccessibilityHierarchy(in: root)
        XCTAssertEqual(hierarchy.flattenToElements().map { $0.label }, [
            "First Bottom", "First Top", "Middle", "Last Bottom", "Last Top",
        ])
    }

    func testAuthoredInputLabelEchoIsPreservedByParser() throws {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
        view.isAccessibilityElement = true
        view.accessibilityLabel = "Label"
        view.accessibilityUserInputLabels = ["Label"]
        let marker = try XCTUnwrap(AccessibilityHierarchyParser().parseAccessibilityHierarchy(in: view).flattenToElements().first)
        XCTAssertEqual(marker.userInputLabels, ["Label"])
    }

    func testMetadataContainersPreserveInterleavedNavigationOrder() {
        let configurations: [(UIView) -> Void] = [
            { $0.accessibilityIdentifier = "Wrapper" },
            { $0.accessibilityCustomActions = [UIAccessibilityCustomAction(name: "Action", actionHandler: { _ in true })] },
            { $0.accessibilityViewIsModal = true },
            { $0.accessibilityContainerType = .semanticGroup },
            { ($0 as! UIScrollView).contentSize = CGSize(width: 100, height: 500) },
        ]
        for (index, configure) in configurations.enumerated() {
            let root = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 200))
            let wrapper: UIView = index == configurations.count - 1 ? UIScrollView(frame: root.bounds) : UIView(frame: root.bounds)
            configure(wrapper)
            let shell = UIView(frame: root.bounds)
            root.addSubview(shell)
            shell.addSubview(wrapper)
            for (parent, label, y) in [(wrapper, "A2", 120), (root, "B", 60), (wrapper, "A1", 0)] {
                let leaf = UIView(frame: CGRect(x: 0, y: y, width: 100, height: 30))
                leaf.isAccessibilityElement = true
                leaf.accessibilityLabel = label
                leaf.accessibilityFrame = leaf.frame
                parent.addSubview(leaf)
            }
            var callbackEvents: [String] = []
            let hierarchy: [AccessibilityHierarchy] = AccessibilityHierarchyParser().parseAccessibilityHierarchy(
                in: root,
                makeElement: { element, index, _ in
                    callbackEvents.append("element:\(element.label ?? ""):\(index)")
                    return .element(element, traversalIndex: index)
                },
                makeContainer: { container, children, source in
                    if source === wrapper {
                        callbackEvents.append("container:Wrapper")
                    }
                    return .container(container, children: children)
                }
            )
            let expected = ["A1", "B", "A2"]
            XCTAssertEqual(hierarchy.flattenToElements().map { $0.label }, expected)
            XCTAssertEqual(callbackEvents, ["element:A1:0", "element:A2:2", "container:Wrapper", "element:B:1"])
            XCTAssertEqual(hierarchy.flattenToElements().map { $0.context }, [nil, nil, nil])
            guard case let .container(_, children) = hierarchy.first else {
                XCTFail("Expected retained metadata container for configuration \(index)")
                continue
            }
            XCTAssertEqual(children.flattenToElements().map { $0.label }, ["A1", "A2"])
            var ownedTraversalIndices: [Int] = []
            for child in children {
                child.forEach { node in
                    if case let .element(_, traversalIndex) = node {
                        ownedTraversalIndices.append(traversalIndex)
                    }
                }
            }
            XCTAssertEqual(ownedTraversalIndices, [0, 2])
        }
    }

    func testAuthoredListRoleIsNotOverriddenByTabItemTrait() {
        let list = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        list.accessibilityContainerType = .list
        let leaves = ["First", "Last"].enumerated().map { index, label in
            let leaf = UIView(frame: CGRect(x: 0, y: index * 40, width: 100, height: 30))
            leaf.isAccessibilityElement = true
            leaf.accessibilityLabel = label
            leaf.accessibilityTraits = .tabBarItemTrait
            leaf.accessibilityFrame = leaf.frame
            list.addSubview(leaf)
            return leaf
        }
        list.accessibilityElements = leaves

        let hierarchy = AccessibilityHierarchyParser().parseAccessibilityHierarchy(in: list)
        XCTAssertEqual(hierarchy.flattenToContainers().map { $0.type }, [.list])
        XCTAssertEqual(hierarchy.flattenToElements().map { $0.context }, [.listStart, .listEnd])
    }

    func testOnlyLastModalSubviewIsTraversed() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 200))
        for (index, label) in ["Background", "First modal", "Last modal", "Trailing sibling"].enumerated() {
            let leaf = UIView(frame: CGRect(x: 0, y: index * 40, width: 100, height: 30))
            leaf.isAccessibilityElement = true
            leaf.accessibilityLabel = label
            leaf.accessibilityFrame = leaf.frame
            leaf.accessibilityViewIsModal = index == 1 || index == 2
            root.addSubview(leaf)
        }
        XCTAssertEqual(AccessibilityHierarchyParser().parseAccessibilityHierarchy(in: root).flattenToElements().map { $0.label }, ["Last modal"])
    }

    func testSnapshotDeliveryOmitsOffscreenElementsButHierarchyKeepsThem() throws {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let scroll = UIScrollView(frame: root.bounds)
        scroll.contentSize = CGSize(width: 100, height: 400)
        root.addSubview(scroll)
        let leaves = ["Visible", "Offscreen", "Zero frame"].enumerated().map { index, label in
            let leaf = UIAccessibilityElement(accessibilityContainer: scroll)
            leaf.accessibilityLabel = label
            leaf.accessibilityFrameInContainerSpace = index == 2 ? .zero : CGRect(x: 0, y: index * 200, width: 100, height: 30)
            return leaf
        }
        scroll.accessibilityElements = leaves
        let snapshot = CapturingSnapshotView(containedView: root, snapshotConfiguration: .init(viewRenderingMode: .renderLayerInContext, colorRenderingMode: .fullColor))
        let window = UIWindow(frame: root.bounds)
        snapshot.addSubview(root)
        window.addSubview(snapshot)
        window.makeKeyAndVisible()
        defer {
            window.resignKey()
            window.isHidden = true
        }

        let parser = AccessibilityHierarchyParser()
        let hierarchy = parser.parseAccessibilityHierarchy(in: root)
        XCTAssertEqual(hierarchy.flattenToElements().map { $0.label }, ["Visible", "Offscreen", "Zero frame"])
        XCTAssertEqual(hierarchy.flattenToElements().map { $0.visibility }, [.onscreen, .offscreen, .offscreen])
        XCTAssertEqual(parser.parseAccessibilityElements(in: root).map { $0.label }, ["Visible"])

        try snapshot.parseAccessibility()
        XCTAssertEqual(try XCTUnwrap(snapshot.parsedData).markers.map { $0.label }, ["Visible"])
    }

    func testVendedListGroupsKeepChildBoundaryContextAndSourceCallbacks() {
        let list = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 200))
        list.accessibilityContainerType = .list

        let firstGroup = UIView(frame: CGRect(x: 0, y: 100, width: 100, height: 80))
        firstGroup.accessibilityContainerType = .landmark
        let lastGroup = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 80))
        lastGroup.accessibilityContainerType = .semanticGroup
        var sources: [UIView] = []
        for (group, labels, y) in [
            (firstGroup, ["First A", "First B"], 100),
            (lastGroup, ["Last A", "Last B"], 0),
        ] {
            let children = labels.enumerated().map { index, label in
                let child = UIView(frame: CGRect(x: 0, y: index * 40, width: 100, height: 30))
                child.isAccessibilityElement = true
                child.accessibilityLabel = label
                child.accessibilityFrame = CGRect(x: 0, y: y + index * 40, width: 100, height: 30)
                group.addSubview(child)
                return child
            }
            group.accessibilityElements = children
            list.addSubview(group)
            sources.append(contentsOf: children)
        }
        list.accessibilityElements = [firstGroup, lastGroup]

        var callbackElements: [AccessibilityElement] = []
        var callbackIndices: [Int] = []
        var callbackSources: [NSObject] = []
        var containerSources: [NSObject] = []
        let hierarchy: [AccessibilityHierarchy] = AccessibilityHierarchyParser().parseAccessibilityHierarchy(
            in: list,
            userInterfaceLayoutDirectionProvider: TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .phone),
            makeElement: { element, index, source in
                callbackElements.append(element)
                callbackIndices.append(index)
                callbackSources.append(source)
                return .element(element, traversalIndex: index)
            },
            makeContainer: { container, children, source in
                containerSources.append(source)
                return .container(container, children: children)
            }
        )

        let elements = hierarchy.flattenToElements()
        XCTAssertEqual(elements.map { $0.label }, ["First A", "First B", "Last A", "Last B"])
        XCTAssertEqual(elements.map { $0.context }, [.listStart, .listStart, .listEnd, .listEnd])
        XCTAssertEqual(elements.map { $0.description }, [
            "First A. List Start.", "First B. List Start.",
            "Last A. List End.", "Last B. List End.",
        ])
        XCTAssertEqual(callbackElements, elements)
        XCTAssertEqual(callbackIndices, [0, 1, 2, 3])
        XCTAssertEqual(callbackSources.count, sources.count)
        XCTAssertTrue(zip(callbackSources, sources).allSatisfy { $0.0 === $0.1 })
        XCTAssertEqual(containerSources.count, 3)
        XCTAssertTrue(containerSources[0] === firstGroup)
        XCTAssertTrue(containerSources[1] === lastGroup)
        XCTAssertTrue(containerSources[2] === list)
        XCTAssertEqual(hierarchy.flattenToContainers().map { $0.type }, [
            .list, .landmark, .semanticGroup(label: nil, value: nil),
        ])
    }

    // MARK: - Inconsistent Hierarchy Resilience

    /// A container that exposes accessibility elements via `accessibilityElements` but reports
    /// `NSNotFound` when asked for their index. Previously triggered an `assert` inside
    /// `context(for:from:...)`.
    private final class InconsistentListContainer: UIView {
        let child: UIAccessibilityElement

        override init(frame: CGRect) {
            child = UIAccessibilityElement(accessibilityContainer: NSNull())
            super.init(frame: frame)
            child.accessibilityLabel = "child"
            child.accessibilityFrame = CGRect(x: 0, y: 0, width: 50, height: 50)
            accessibilityContainerType = .list
            accessibilityElements = [child]
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("not used") }

        override func index(ofAccessibilityElement element: Any) -> Int {
            return NSNotFound
        }
    }

    func testParserDerivesContextFromGraphWhenContainerReportsNotFound() {
        // A container that lies about its children (drops one on `index(of:)`) no longer strips that
        // element's context. Graph-derived parsing reads the element's position from the tree it
        // actually walked, not from the container's self-report, so list context still applies.
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let container = InconsistentListContainer(frame: root.bounds)
        root.addSubview(container)

        let parser = AccessibilityHierarchyParser()
        let elements = parser.parseAccessibilityHierarchy(
            in: root,
            userInterfaceLayoutDirectionProvider: TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .phone)
        ).flattenToElements()

        XCTAssertEqual(elements.map { $0.description }, ["child. List Start."], "Element keeps its graph-derived list context even when its container drops it")
        XCTAssertEqual(elements.map { $0.context }, [.listStart])
    }

    /// A `UITabBar` with no items previously triggered a modulo-by-zero `precondition` inside
    /// `context(for:from:...)`. The parser should now skip the tab-bar context for elements under
    /// such a tab bar without crashing.
    func testParserHandlesUITabBarWithoutItems() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let tabBar = UITabBar(frame: CGRect(x: 0, y: 150, width: 200, height: 50))
        // No items set — `tabBar.items` is nil, so the parser sees an empty item list.

        let child = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        child.isAccessibilityElement = true
        child.accessibilityLabel = "orphan"
        tabBar.addSubview(child)

        root.addSubview(tabBar)

        let parser = AccessibilityHierarchyParser()
        let elements = parser.parseAccessibilityHierarchy(
            in: root,
            userInterfaceLayoutDirectionProvider: TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .phone)
        ).flattenToElements().map { $0.description }

        XCTAssertTrue(
            elements.contains("orphan"),
            "Element under an itemless UITabBar should still be parsed without tab-bar context"
        )
    }

    /// A view whose `accessibilityPath` is an empty `UIBezierPath` previously produced a
    /// `CGRect.null` bounding box, whose infinite values trapped in downstream `Int(_:)`
    /// conversions. The parser should fall back to the element's frame for shape and size.
    func testParserHandlesEmptyAccessibilityPath() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let element = ActivationPointTestView(frame: CGRect(x: 10, y: 10, width: 50, height: 50))
        element.isAccessibilityElement = true
        element.accessibilityLabel = "emptyPath"
        element.overriddenPath = UIBezierPath()
        root.addSubview(element)

        let parser = AccessibilityHierarchyParser()
        let elements = parser.parseAccessibilityHierarchy(
            in: root,
            userInterfaceLayoutDirectionProvider: TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .phone)
        ).flattenToElements().map { $0.description }

        XCTAssertEqual(elements, ["emptyPath"], "Element with empty accessibility path should still be parsed")
    }

    func testParserProducesEncodableShapeForNonFiniteFrame() throws {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let element = ActivationPointTestView(frame: CGRect(x: 10, y: 10, width: 50, height: 50))
        element.isAccessibilityElement = true
        element.accessibilityLabel = "nonFinite"
        element.overriddenFrame = CGRect(x: CGFloat.nan, y: 0, width: CGFloat.infinity, height: 50)
        root.addSubview(element)

        let marker = try XCTUnwrap(parseMarkers(in: root).first)
        XCTAssertEqual(marker.shape, .frame(.zero), "A non-finite frame should fall back to a zero frame")
        XCTAssertNoThrow(try JSONEncoder().encode(marker.shape), "The produced shape must be JSON-encodable")
    }

    // MARK: - Generic Fold Tests

    func testGenericFoldPassesSourceObjects() {
        let rootView = UIView(frame: .init(x: 0, y: 0, width: 100, height: 100))

        let container = UIView(frame: .init(x: 0, y: 0, width: 100, height: 100))
        container.accessibilityContainerType = .list
        rootView.addSubview(container)

        let element = UIView(frame: .init(x: 10, y: 10, width: 30, height: 30))
        element.isAccessibilityElement = true
        element.accessibilityLabel = "Item"
        element.accessibilityFrame = CGRect(x: 10, y: 10, width: 30, height: 30)
        container.addSubview(element)

        typealias FoldNode = (label: String, source: NSObject, container: AccessibilityContainer?)

        let parser = AccessibilityHierarchyParser()
        let nodes: [FoldNode] = parser.parseAccessibilityHierarchy(
            in: rootView,
            userInterfaceLayoutDirectionProvider: TestUserInterfaceLayoutDirectionProvider(
                userInterfaceLayoutDirection: .leftToRight
            ),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .phone),
            makeElement: { elem, index, source in
                (label: elem.description, source: source, container: nil)
            },
            makeContainer: { cont, children, source in
                (label: "container", source: source, container: cont)
            }
        )

        XCTAssertEqual(nodes.count, 1)
        let listNode = nodes[0]
        XCTAssertTrue(listNode.source === container)
        XCTAssertNotNil(listNode.container)
    }

    // MARK: - Private Helpers

    private func parseMarkers(in view: UIView) -> [AccessibilityMarker] {
        let parser = AccessibilityHierarchyParser()
        return parser.parseAccessibilityElements(
            in: view,
            userInterfaceLayoutDirectionProvider: TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .phone)
        )
    }
}

// MARK: -

private final class CapturingSnapshotView: AccessibilitySnapshotBaseView {
    var parsedData: ParsedAccessibilityData?

    override func render(data: ParsedAccessibilityData) {
        parsedData = data
    }
}

private final class ActivationPointTestView: UIView {
    var overriddenFrame: CGRect?
    var overriddenActivationPoint: CGPoint?
    var overriddenPath: UIBezierPath?

    override var accessibilityFrame: CGRect {
        get { overriddenFrame ?? super.accessibilityFrame }
        set { overriddenFrame = newValue }
    }

    override var accessibilityActivationPoint: CGPoint {
        get { overriddenActivationPoint ?? super.accessibilityActivationPoint }
        set { overriddenActivationPoint = newValue }
    }

    override var accessibilityPath: UIBezierPath? {
        get { overriddenPath ?? super.accessibilityPath }
        set { overriddenPath = newValue }
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
    var rowHeaders: [Int: [UIAccessibilityContainerDataTableCell]] = [:]
    var columnHeaders: [Int: [UIAccessibilityContainerDataTableCell]] = [:]
    var allowsQueries = true
    private(set) var queryCount = 0

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
        queryCount += 1
        return allowsQueries ? cells[CellIndex(row: row, column: column)] : nil
    }

    func accessibilityRowCount() -> Int {
        queryCount += 1
        return allowsQueries ? rows : 0
    }

    func accessibilityColumnCount() -> Int {
        queryCount += 1
        return allowsQueries ? columns : 0
    }

    func accessibilityHeaderElements(forRow row: Int) -> [UIAccessibilityContainerDataTableCell]? {
        queryCount += 1
        return allowsQueries ? rowHeaders[row] : nil
    }

    func accessibilityHeaderElements(forColumn column: Int) -> [UIAccessibilityContainerDataTableCell]? {
        queryCount += 1
        return allowsQueries ? columnHeaders[column] : nil
    }
}

/// Test cell that conforms to UIAccessibilityContainerDataTableCell
private final class TestDataTableCell: UIView, UIAccessibilityContainerDataTableCell {
    let row: Int
    let column: Int
    let rowSpan: Int
    let columnSpan: Int
    var allowsQueries = true
    private(set) var queryCount = 0

    init(row: Int, column: Int, label: String, rowSpan: Int = 1, columnSpan: Int = 1) {
        self.row = row
        self.column = column
        self.rowSpan = rowSpan
        self.columnSpan = columnSpan
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
        queryCount += 1
        return allowsQueries ? NSRange(location: row, length: rowSpan) : NSRange(location: NSNotFound, length: 0)
    }

    func accessibilityColumnRange() -> NSRange {
        queryCount += 1
        return allowsQueries ? NSRange(location: column, length: columnSpan) : NSRange(location: NSNotFound, length: 0)
    }
}

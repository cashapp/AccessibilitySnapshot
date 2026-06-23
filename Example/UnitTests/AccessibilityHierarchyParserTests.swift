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
        element.overriddenFrame = frame
        element.overriddenActivationPoint = CGPoint(x: frame.midX, y: frame.midY)
        container.addSubview(element)

        let markers = parseMarkers(in: container)
        XCTAssertEqual(markers.count, 1)
        XCTAssertTrue(markers[0].usesDefaultActivationPoint)
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

    func testParserReturnsContextlessElementWhenContainerReportsNotFound() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let container = InconsistentListContainer(frame: root.bounds)
        root.addSubview(container)

        let parser = AccessibilityHierarchyParser()
        let elements = parser.parseAccessibilityHierarchy(
            in: root,
            userInterfaceLayoutDirectionProvider: TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .phone)
        ).flattenToElements().map { $0.description }

        XCTAssertEqual(elements, ["child"], "Element should still be parsed even when its container drops it")
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

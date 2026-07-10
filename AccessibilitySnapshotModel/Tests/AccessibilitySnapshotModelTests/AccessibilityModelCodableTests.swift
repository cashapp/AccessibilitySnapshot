import AccessibilitySnapshotModel
import Foundation
import XCTest

/// Codable and wire-format coverage for the portable model. These tests depend only on
/// `AccessibilitySnapshotModel` (no UIKit / CoreGraphics), so they run on any SwiftPM
/// toolchain — see the model-only CI job that exercises them on Linux.
final class AccessibilityModelCodableTests: XCTestCase {
    // MARK: - Codable Round-Trips

    func testAccessibilityElementCodable() throws {
        let element = AccessibilityElement(
            description: "Test Button",
            label: "Button Label",
            value: "Button Value",
            traits: [.button, .selected],
            identifier: "test-button-id",
            hint: "Double tap to activate",
            userInputLabels: ["tap button", "press button"],
            shape: .frame(AccessibilityRect(x: 10, y: 20, width: 100, height: 44)),
            activationPoint: AccessibilityPoint(x: 60, y: 42),
            usesDefaultActivationPoint: true,
            customActions: [.init(name: "Delete")],
            customContent: [],
            customRotors: [],
            accessibilityLanguage: "en-US",
            respondsToUserInteraction: true
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
        XCTAssertEqual(decoded.customActions, element.customActions)
        XCTAssertEqual(decoded.accessibilityLanguage, element.accessibilityLanguage)
        XCTAssertEqual(decoded.respondsToUserInteraction, element.respondsToUserInteraction)
    }

    func testAccessibilityContainerCodable() throws {
        let container = AccessibilityContainer(
            type: .list,
            frame: AccessibilityRect(x: 0, y: 0, width: 320, height: 200)
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
            shape: .frame(AccessibilityRect(x: 0, y: 0, width: 100, height: 44)),
            activationPoint: AccessibilityPoint(x: 50, y: 22),
            usesDefaultActivationPoint: true,
            customActions: [],
            customContent: [],
            customRotors: [],
            accessibilityLanguage: nil,
            respondsToUserInteraction: false
        )

        let element2 = AccessibilityElement(
            description: "Item 2",
            label: "Item 2",
            value: nil,
            traits: [],
            identifier: nil,
            hint: nil,
            userInputLabels: nil,
            shape: .frame(AccessibilityRect(x: 0, y: 50, width: 100, height: 44)),
            activationPoint: AccessibilityPoint(x: 50, y: 72),
            usesDefaultActivationPoint: true,
            customActions: [],
            customContent: [],
            customRotors: [],
            accessibilityLanguage: nil,
            respondsToUserInteraction: false
        )

        let container = AccessibilityContainer(
            type: .list,
            frame: AccessibilityRect(x: 0, y: 0, width: 100, height: 100)
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

    func testCustomActionCodable() throws {
        let action = AccessibilityElement.CustomAction(name: "Delete")

        let encoder = JSONEncoder()
        let data = try encoder.encode(action)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AccessibilityElement.CustomAction.self, from: data)

        XCTAssertEqual(decoded.name, "Delete")
    }

    func testContainerTypeCodable() throws {
        let types: [AccessibilityContainer.ContainerType] = [
            .none,
            .list,
            .landmark,
            .tabBar,
            .semanticGroup(label: "Test", value: nil),
            .dataTable(rowCount: 3, columnCount: 4, cells: []),
        ]

        for type in types {
            let encoder = JSONEncoder()
            let data = try encoder.encode(type)

            let decoder = JSONDecoder()
            let decoded = try decoder.decode(AccessibilityContainer.ContainerType.self, from: data)

            XCTAssertEqual(decoded, type)
        }
    }

    func testDataTableContainerCodable() throws {
        let container = AccessibilityContainer(
            type: .dataTable(rowCount: 5, columnCount: 4, cells: []),
            frame: AccessibilityRect(x: 0, y: 0, width: 320, height: 200)
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(container)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AccessibilityContainer.self, from: data)

        if case let .dataTable(rowCount, columnCount, _) = decoded.type {
            XCTAssertEqual(rowCount, 5)
            XCTAssertEqual(columnCount, 4)
        } else {
            XCTFail("Expected dataTable type")
        }
    }

    func testSemanticGroupContainerCodable() throws {
        let container = AccessibilityContainer(
            type: .semanticGroup(label: "Group Label", value: "Group Value"),
            identifier: "group-id",
            frame: AccessibilityRect(x: 0, y: 0, width: 200, height: 100)
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(container)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AccessibilityContainer.self, from: data)

        if case let .semanticGroup(label, value) = decoded.type {
            XCTAssertEqual(label, "Group Label")
            XCTAssertEqual(value, "Group Value")
            XCTAssertEqual(decoded.identifier, "group-id")
        } else {
            XCTFail("Expected semanticGroup type")
        }
    }

    func testTabBarContainerCodable() throws {
        let container = AccessibilityContainer(
            type: .tabBar,
            frame: AccessibilityRect(x: 0, y: 0, width: 320, height: 49)
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
            frame: AccessibilityRect(x: 0, y: 0, width: 320, height: 200)
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(container)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AccessibilityContainer.self, from: data)

        XCTAssertEqual(decoded.type, .landmark)
    }

    // MARK: - Wire-Format Compatibility

    // The portable model types replaced CoreGraphics geometry but must keep the exact
    // JSON wire format that the previous `CGPoint`/`CGRect`/`AccessibilityElement.Shape`
    // Codable conformances produced, so persisted payloads keep decoding.

    func testGeometryEncodesAsLegacyCGGeometryArrays() throws {
        let encoder = JSONEncoder()

        let point = try encoder.encode(AccessibilityPoint(x: 1, y: 2))
        XCTAssertEqual(String(data: point, encoding: .utf8), "[1,2]")

        let size = try encoder.encode(AccessibilitySize(width: 100, height: 44))
        XCTAssertEqual(String(data: size, encoding: .utf8), "[100,44]")

        let rect = try encoder.encode(AccessibilityRect(x: 10, y: 20, width: 100, height: 44))
        XCTAssertEqual(String(data: rect, encoding: .utf8), "[[10,20],[100,44]]")
    }

    func testShapeDecodesLegacyFrameWireFormat() throws {
        let legacyJSON = Data(#"{"type":"frame","frame":[[10,20],[100,44]]}"#.utf8)
        let decoded = try JSONDecoder().decode(AccessibilityShape.self, from: legacyJSON)
        XCTAssertEqual(decoded, .frame(AccessibilityRect(x: 10, y: 20, width: 100, height: 44)))
    }

    func testShapeDecodesLegacyPathWireFormat() throws {
        let legacyJSON = Data(#"""
        {"type":"path","pathElements":[{"move":{"to":[0,0]}},{"line":{"to":[100,0]}},{"closeSubpath":{}}]}
        """#.utf8)
        let decoded = try JSONDecoder().decode(AccessibilityShape.self, from: legacyJSON)
        XCTAssertEqual(decoded, .path([
            .move(to: AccessibilityPoint(x: 0, y: 0)),
            .line(to: AccessibilityPoint(x: 100, y: 0)),
            .closeSubpath,
        ]))
    }

    func testShapeFrameEncodesWithTypeDiscriminator() throws {
        let data = try JSONEncoder().encode(AccessibilityShape.frame(AccessibilityRect(x: 10, y: 20, width: 100, height: 44)))
        let object = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(object["type"] as? String, "frame")
        XCTAssertEqual(object["frame"] as? [[Double]], [[10, 20], [100, 44]])
    }

    // MARK: - Visibility Codable

    func testElementDecodesPayloadWithoutVisibilityKeyWithoutCrashing() throws {
        // `visibility` is a field this fork adds. A payload produced before it existed must still
        // decode (defaulting to `.onscreen`) rather than crash — snapshot has real consumers whose
        // stored data predates this field.
        let priorJSON = Data(#"""
        {
          "description": "Prior",
          "traits": [],
          "shape": {"type":"frame","frame":[[0,0],[10,10]]},
          "activationPoint": [5,5],
          "usesDefaultActivationPoint": true,
          "customActions": [],
          "customContent": [],
          "customRotors": [],
          "respondsToUserInteraction": false
        }
        """#.utf8)
        let decoded = try JSONDecoder().decode(AccessibilityElement.self, from: priorJSON)
        XCTAssertEqual(decoded.visibility, .onscreen)
        XCTAssertEqual(decoded.description, "Prior")
    }

    func testOffscreenVisibilityRoundTrips() throws {
        let element = AccessibilityElement(
            description: "Hidden",
            label: nil, value: nil, traits: [], identifier: nil, hint: nil,
            userInputLabels: nil,
            shape: .frame(.zero), activationPoint: .zero, usesDefaultActivationPoint: true,
            customActions: [], customContent: [], customRotors: [],
            accessibilityLanguage: nil, respondsToUserInteraction: false,
            visibility: .offscreen
        )
        let decoded = try JSONDecoder().decode(AccessibilityElement.self, from: JSONEncoder().encode(element))
        XCTAssertEqual(decoded.visibility, .offscreen)
        XCTAssertEqual(decoded, element)
    }

    // MARK: - DataTable cells Codable Compatibility

    func testDataTableDecodesLegacyPayloadWithoutCellsKey() throws {
        // Pre-`cells` payloads used the synthesized shape {"dataTable":{"rowCount","columnCount"}}.
        let legacyJSON = Data(#"{"dataTable":{"rowCount":3,"columnCount":4}}"#.utf8)
        let decoded = try JSONDecoder().decode(AccessibilityContainer.ContainerType.self, from: legacyJSON)
        guard case let .dataTable(rowCount, columnCount, cells) = decoded else {
            return XCTFail("Expected dataTable")
        }
        XCTAssertEqual(rowCount, 3)
        XCTAssertEqual(columnCount, 4)
        XCTAssertTrue(cells.isEmpty)
    }

    func testDataTableCellsRoundTrip() throws {
        let cells: [AccessibilityContainer.DataTableCellInfo?] = [
            .init(row: 0, column: 0, rowSpan: 1, columnSpan: 1, isFirstInRow: true, rowHeaderChildIndices: [], columnHeaderChildIndices: []),
            nil,
            .init(row: 1, column: 2, rowSpan: 2, columnSpan: 1, isFirstInRow: false, rowHeaderChildIndices: [0], columnHeaderChildIndices: [1]),
        ]
        let type = AccessibilityContainer.ContainerType.dataTable(rowCount: 2, columnCount: 3, cells: cells)
        let decoded = try JSONDecoder().decode(AccessibilityContainer.ContainerType.self, from: JSONEncoder().encode(type))
        XCTAssertEqual(decoded, type)
    }
}

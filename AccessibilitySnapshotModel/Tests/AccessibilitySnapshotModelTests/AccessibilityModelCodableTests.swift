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
            customActions: ["Delete"],
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

    func testAccessibilityElementVisibilityCodableDefaultsToOnscreen() throws {
        let element = AccessibilityElement(
            description: "Offscreen Button",
            label: "Offscreen Button",
            value: nil,
            traits: [.button],
            identifier: nil,
            hint: nil,
            userInputLabels: nil,
            shape: .frame(AccessibilityRect(x: 0, y: 200, width: 100, height: 44)),
            activationPoint: AccessibilityPoint(x: 50, y: 222),
            usesDefaultActivationPoint: true,
            customActions: [],
            customContent: [],
            customRotors: [],
            accessibilityLanguage: nil,
            respondsToUserInteraction: true,
            visibility: ScreenVisibility.offscreen
        )

        let data = try JSONEncoder().encode(element)
        let decoded = try JSONDecoder().decode(AccessibilityElement.self, from: data)
        XCTAssertEqual(decoded, element)
        XCTAssertEqual(decoded.visibility, .offscreen)

        var object = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(object.removeValue(forKey: "visibility") as? String, "offscreen")
        let legacyData = try JSONSerialization.data(withJSONObject: object)
        let legacyDecoded = try JSONDecoder().decode(AccessibilityElement.self, from: legacyData)
        XCTAssertEqual(legacyDecoded.visibility, .onscreen)
    }

    func testAccessibilityElementContextCodableAndCopying() throws {
        let context = AccessibilityContext.dataTableCell(
            row: 2,
            column: 3,
            width: 2,
            height: 3,
            isFirstInRow: true,
            rowHeaders: [.init(label: "Quarter", value: "Q1")],
            columnHeaders: [
                .init(label: "Revenue", value: nil),
                .init(label: nil, value: "USD"),
            ]
        )
        let element = AccessibilityElement(
            description: "Cell",
            label: "Cell",
            value: "42",
            traits: [],
            identifier: nil,
            hint: "Raw hint",
            userInputLabels: nil,
            shape: .frame(AccessibilityRect(x: 0, y: 0, width: 100, height: 44)),
            activationPoint: AccessibilityPoint(x: 50, y: 22),
            usesDefaultActivationPoint: true,
            customActions: [],
            customContent: [],
            customRotors: [],
            accessibilityLanguage: "en-US",
            respondsToUserInteraction: false,
            context: context
        )

        let data = try JSONEncoder().encode(element)
        let decoded = try JSONDecoder().decode(AccessibilityElement.self, from: data)
        XCTAssertEqual(decoded, element)
        XCTAssertEqual(decoded.context, context)

        var object = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertNotNil(object.removeValue(forKey: "context"))
        let legacyData = try JSONSerialization.data(withJSONObject: object)
        let legacyDecoded = try JSONDecoder().decode(AccessibilityElement.self, from: legacyData)
        XCTAssertNil(legacyDecoded.context)

        let copy = decoded.withDescription("Composed description", hint: "Composed hint")
        XCTAssertEqual(copy.description, "Composed description")
        XCTAssertEqual(copy.hint, "Composed hint")
        XCTAssertEqual(copy.context, context)
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

    func testLegacyContainerPayloadDefaultsNewFields() throws {
        let payloads: [(String, AccessibilityContainer.ContainerType)] = [
            (#"{"list":{}}"#, .list),
            (#"{"landmark":{}}"#, .landmark),
            (#"{"tabBar":{}}"#, .tabBar),
            (#"{"dataTable":{"rowCount":2,"columnCount":3}}"#, .dataTable(rowCount: 2, columnCount: 3, cells: [])),
        ]
        for (typeJSON, expectedType) in payloads {
            let data = Data("{\"type\":\(typeJSON),\"frame\":[[10,20],[100,44]]}".utf8)
            let decoded = try JSONDecoder().decode(AccessibilityContainer.self, from: data)
            XCTAssertEqual(decoded.type, expectedType)
            XCTAssertEqual(decoded.frame, AccessibilityRect(x: 10, y: 20, width: 100, height: 44))
            XCTAssertNil(decoded.identifier)
            XCTAssertNil(decoded.scrollableContentSize)
            XCTAssertFalse(decoded.isModalBoundary)
            XCTAssertEqual(decoded.customActions, [])
        }
    }

    func testLegacySemanticGroupIdentifierMigratesToContainer() throws {
        let data = Data(#"{"type":{"semanticGroup":{"label":"Group","value":"Value","identifier":"legacy-id"}},"frame":[[0,0],[100,44]]}"#.utf8)
        let decoded = try JSONDecoder().decode(AccessibilityContainer.self, from: data)
        XCTAssertEqual(decoded.type, .semanticGroup(label: "Group", value: "Value"))
        XCTAssertEqual(decoded.identifier, "legacy-id")
        XCTAssertFalse(decoded.isModalBoundary)
        XCTAssertEqual(decoded.customActions, [])

        let encoded = try JSONEncoder().encode(decoded)
        let roundTrip = try JSONDecoder().decode(AccessibilityContainer.self, from: encoded)
        XCTAssertEqual(roundTrip, decoded)
        let object = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        XCTAssertEqual(object["identifier"] as? String, "legacy-id")
        let type = object["type"] as! [String: Any]
        let semanticGroup = type["semanticGroup"] as! [String: Any]
        XCTAssertNil(semanticGroup["identifier"])

        var mixedPayload = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        mixedPayload["identifier"] = "current-id"
        let mixedData = try JSONSerialization.data(withJSONObject: mixedPayload)
        let mixed = try JSONDecoder().decode(AccessibilityContainer.self, from: mixedData)
        XCTAssertEqual(mixed.identifier, "current-id")
    }

    func testContainerMetadataCodableRoundTrip() throws {
        let container = AccessibilityContainer(
            type: .semanticGroup(label: nil, value: nil),
            identifier: "current-id",
            scrollableContentSize: AccessibilitySize(width: 100, height: 500),
            frame: AccessibilityRect(x: 10, y: 20, width: 100, height: 44),
            isModalBoundary: true,
            customActions: ["Delete"]
        )
        let data = try JSONEncoder().encode(container)
        XCTAssertEqual(try JSONDecoder().decode(AccessibilityContainer.self, from: data), container)
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
        let action: AccessibilityElement.CustomAction = "Delete"

        let encoder = JSONEncoder()
        let data = try encoder.encode(action)

        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "\"Delete\"")

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AccessibilityElement.CustomAction.self, from: data)

        XCTAssertEqual(decoded, action)
    }

    func testContainerTypeCodable() throws {
        let types: [AccessibilityContainer.ContainerType] = [
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

        if case let .dataTable(rowCount, columnCount, cells) = decoded.type {
            XCTAssertEqual(rowCount, 5)
            XCTAssertEqual(columnCount, 4)
            XCTAssertEqual(cells, [])
        } else {
            XCTFail("Expected dataTable type")
        }

        let legacyData = Data(#"{"dataTable":{"rowCount":5,"columnCount":4}}"#.utf8)
        let legacyDecoded = try decoder.decode(AccessibilityContainer.ContainerType.self, from: legacyData)
        XCTAssertEqual(legacyDecoded, .dataTable(rowCount: 5, columnCount: 4, cells: []))
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

        XCTAssertEqual(decoded.identifier, "group-id")
        if case let .semanticGroup(label, value) = decoded.type {
            XCTAssertEqual(label, "Group Label")
            XCTAssertEqual(value, "Group Value")
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
}

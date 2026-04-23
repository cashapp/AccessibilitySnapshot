@testable import AccessibilitySnapshotParser
import SwiftUI
import UIKit
import XCTest

@available(iOS 15.0, *)
final class SwipeActionsParserTests: XCTestCase {
    // MARK: - Helpers

    private func parsedHierarchy(for view: some View) -> [AccessibilityHierarchy] {
        let hostingController = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = hostingController
        window.makeKeyAndVisible()

        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()

        let expectation = expectation(description: "SwiftUI render")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { expectation.fulfill() }
        wait(for: [expectation], timeout: 5.0)

        let parser = AccessibilityHierarchyParser()
        return parser.parseAccessibilityHierarchy(in: hostingController.view)
    }

    private func containers(in nodes: [AccessibilityHierarchy]) -> [(AccessibilityContainer, [AccessibilityHierarchy])] {
        nodes.flatMap { node -> [(AccessibilityContainer, [AccessibilityHierarchy])] in
            switch node {
            case .element:
                return []
            case let .container(container, children):
                return [(container, children)] + containers(in: children)
            }
        }
    }

    private func elements(in nodes: [AccessibilityHierarchy]) -> [AccessibilityElement] {
        nodes.flatMap { node -> [AccessibilityElement] in
            switch node {
            case let .element(elem, _):
                return [elem]
            case let .container(_, children):
                return elements(in: children)
            }
        }
    }

    // MARK: - Tests

    func testSwipeOnlyAction_capturedOnContainer() {
        let hierarchy = parsedHierarchy(for: List {
            Text("Item")
                .swipeActions { Button("Delete") {} }
        })

        let allContainers = containers(in: hierarchy)
        let withActions = allContainers.filter { !$0.0.customActions.isEmpty }

        XCTAssertEqual(withActions.count, 1)
        XCTAssertEqual(withActions.first?.0.customActions.map(\.name), ["Delete"])
    }

    func testSwipeAndPublicSameName_bothCaptured() {
        let hierarchy = parsedHierarchy(for: List {
            Text("Item")
                .swipeActions { Button("Archive") {} }
                .accessibilityAction(named: "Archive") {}
        })

        let allContainers = containers(in: hierarchy)
        let withActions = allContainers.filter { !$0.0.customActions.isEmpty }
        let allElements = elements(in: hierarchy)
        let itemElement = allElements.first { $0.description == "Item" }

        // Container captures the swipe action
        XCTAssertEqual(withActions.count, 1)
        XCTAssertEqual(withActions.first?.0.customActions.map(\.name), ["Archive"])

        // Element captures the public action
        XCTAssertEqual(itemElement?.customActions.map(\.name), ["Archive"])
    }

    func testSwipeAndPublicDifferentNames_bothCaptured() {
        let hierarchy = parsedHierarchy(for: List {
            Text("Item")
                .swipeActions { Button("Archive") {} }
                .accessibilityAction(named: "Star") {}
        })

        let allContainers = containers(in: hierarchy)
        let withActions = allContainers.filter { !$0.0.customActions.isEmpty }
        let allElements = elements(in: hierarchy)
        let itemElement = allElements.first { $0.description == "Item" }

        // Container captures swipe action
        XCTAssertEqual(withActions.count, 1)
        XCTAssertEqual(withActions.first?.0.customActions.map(\.name), ["Archive"])

        // Element captures public action
        XCTAssertEqual(itemElement?.customActions.map(\.name), ["Star"])
    }

    func testMultiElementRow_containerHoldsSwipeAction() {
        let hierarchy = parsedHierarchy(for: List {
            HStack {
                Button("First") {}
                Button("Second") {}
            }
            .swipeActions { Button("Row Action") {} }
        })

        let allContainers = containers(in: hierarchy)
        let withActions = allContainers.filter { !$0.0.customActions.isEmpty }

        XCTAssertEqual(withActions.count, 1)
        XCTAssertEqual(withActions.first?.0.customActions.map(\.name), ["Row Action"])

        // Both child elements exist but have no actions themselves
        let children = elements(in: withActions.first?.1 ?? [])
        XCTAssertEqual(children.count, 2)
        for child in children {
            XCTAssertTrue(child.customActions.isEmpty)
        }
    }

    func testRowWithoutSwipeActions_noContainerActions() {
        let hierarchy = parsedHierarchy(for: List {
            Text("Plain Row")
        })

        let allContainers = containers(in: hierarchy)
        let withActions = allContainers.filter { !$0.0.customActions.isEmpty }
        XCTAssertTrue(withActions.isEmpty)
    }
}

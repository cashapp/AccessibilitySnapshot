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

        let padMagicNumber = 25

        elementA.accessibilityFrame = .init(x: 0, y: padMagicNumber, width: 10, height: 10)
        elementB.accessibilityFrame = .init(x: 10, y: 0, width: 0, height: 10)
        elementC.accessibilityFrame = .init(x: 20, y: -padMagicNumber, width: 10, height: 10)
        elementD.accessibilityFrame = .init(x: 30, y: -padMagicNumber, width: 10, height: 10)

        let padAgain = parser.parseAccessibilityElements(
            in: gridView,
            userInterfaceLayoutDirectionProvider:
            TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .pad)
        ).map { $0.description }

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

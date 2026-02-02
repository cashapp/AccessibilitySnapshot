import AccessibilitySnapshot
import SnapshotTesting
import Testing
import UIKit

@testable import AccessibilitySnapshotDemo

/// Swift Testing versions of SnapshotTestingTests that share the same reference images.
/// This demonstrates that AccessibilitySnapshot works identically with both test frameworks.
@MainActor
@Suite("AccessibilitySnapshot with Swift Testing")
struct SwiftTestingSnapshotTests {
    /// Directory containing the shared reference images (same as XCTest version).
    private var snapshotDirectory: String {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__/SnapshotTestingTests")
            .path
    }

    // MARK: - Tests

    @Test("Simple SwiftUI configuration")
    func testSimpleSwiftUIConfiguration() {
        assertSharedSnapshot(
            of: SwiftUIView(),
            as: .accessibilityImage(size: UIScreen.main.bounds.size),
            named: nameForDevice(),
            testName: "testSimpleSwiftUIConfiguration"
        )
    }

    @Test("Simple SwiftUI with scroll view configuration")
    func testSimpleSwiftUIWithScrollViewConfiguration() {
        assertSharedSnapshot(
            of: SwiftUIViewWithScrollView(),
            as: .accessibilityImage(size: UIScreen.main.bounds.size),
            named: nameForDevice(),
            testName: "testSimpleSwiftUIWithScrollViewConfiguration"
        )
    }

    @Test("Simple configuration")
    func testSimpleConfiguration() {
        let viewController = ViewAccessibilityPropertiesViewController()
        viewController.view.frame = UIScreen.main.bounds
        assertSharedSnapshot(
            of: viewController,
            as: .accessibilityImage,
            named: nameForDevice(),
            testName: "testSimpleConfiguration"
        )
    }

    @Test("Showing activation point")
    func testShowingActivationPoint() {
        let viewController = ActivationPointViewController()
        viewController.view.frame = UIScreen.main.bounds

        assertSharedSnapshot(
            of: viewController,
            as: .accessibilityImage(showActivationPoints: .always),
            named: nameForDevice(baseName: "always"),
            testName: "testShowingActivationPoint"
        )

        assertSharedSnapshot(
            of: viewController,
            as: .accessibilityImage(showActivationPoints: .whenOverridden),
            named: nameForDevice(baseName: "whenOverridden"),
            testName: "testShowingActivationPoint"
        )

        assertSharedSnapshot(
            of: viewController,
            as: .accessibilityImage(showActivationPoints: .never),
            named: nameForDevice(baseName: "never"),
            testName: "testShowingActivationPoint"
        )
    }

    @Test("Using monochrome snapshot")
    func testUsingMonochromeSnapshot() {
        let view = UILabel()
        view.text = "Hello World"
        view.textColor = .red
        view.sizeToFit()

        assertSharedSnapshot(
            of: view,
            as: .accessibilityImage(useMonochromeSnapshot: false),
            named: nameForDevice(baseName: "false"),
            testName: "testUsingMonochromeSnapshot"
        )

        assertSharedSnapshot(
            of: view,
            as: .accessibilityImage(useMonochromeSnapshot: true),
            named: nameForDevice(baseName: "true"),
            testName: "testUsingMonochromeSnapshot"
        )
    }

    @Test("Rendering methods")
    func testRenderingMethods() {
        let view = UIView()
        view.bounds.size = .init(width: 40, height: 40)
        view.layer.transform = CATransform3DMakeRotation(.pi / 4, 1, 1, 1)
        view.backgroundColor = .red

        view.isAccessibilityElement = true
        view.accessibilityLabel = "Test Element"

        let container = UIView(frame: .init(x: 0, y: 0, width: 100, height: 100))
        view.center = .init(x: 50, y: 50)
        container.addSubview(view)

        assertSharedSnapshot(
            of: container,
            as: .accessibilityImage(drawHierarchyInKeyWindow: false),
            named: nameForDevice(baseName: "false"),
            testName: "testRenderingMethods"
        )

        assertSharedSnapshot(
            of: container,
            as: .accessibilityImage(drawHierarchyInKeyWindow: true),
            named: nameForDevice(baseName: "true"),
            testName: "testRenderingMethods"
        )
    }

    @Test("Marker colors")
    func testMarkerColors() {
        let view = AccessibleContainerView(count: 8, innerMargin: 10)
        view.sizeToFit()

        assertSharedSnapshot(
            of: view,
            as: .accessibilityImage(),
            named: nameForDevice(baseName: "default"),
            testName: "testMarkerColors"
        )

        assertSharedSnapshot(
            of: view,
            as: .accessibilityImage(markerColors: [.red, .green, .blue]),
            named: nameForDevice(baseName: "custom"),
            testName: "testMarkerColors"
        )
    }

    @Test("Invert colors")
    func testInvertColors() {
        let viewController = InvertColorsViewController()
        viewController.view.frame = UIScreen.main.bounds
        assertSharedSnapshot(
            of: viewController,
            as: .imageWithSmartInvert,
            named: nameForDevice(),
            testName: "testInvertColors"
        )
    }

    @Test("Hit targets")
    func testHitTargets() {
        let viewController = ButtonAccessibilityTraitsViewController()
        viewController.view.frame = UIScreen.main.bounds
        assertSharedSnapshot(
            of: viewController,
            as: .imageWithHitTargets(),
            named: nameForDevice(),
            testName: "testHitTargets"
        )
    }

    @Test("UIKit text field")
    func testUIKitTextField() {
        let viewController = TextFieldViewController()
        viewController.view.frame = UIScreen.main.bounds

        assertSharedSnapshot(
            of: viewController,
            as: .accessibilityImage,
            named: nameForDevice(),
            testName: "testUIKitTextField"
        )
    }

    @Test("UIKit text view")
    func testUIKitTextView() {
        let viewController = TextViewViewController()
        viewController.view.frame = UIScreen.main.bounds

        assertSharedSnapshot(
            of: viewController,
            as: .accessibilityImage,
            named: nameForDevice(),
            testName: "testUIKitTextView"
        )
    }

    @Test("SwiftUI text entry")
    func testSwiftUITextEntry() {
        let view = SwiftUITextEntry()
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)

        assertSharedSnapshot(
            of: view,
            as: .accessibilityImage,
            named: nameForDevice(),
            testName: "testSwiftUITextEntry"
        )
    }

    // MARK: - Private Methods

    /// Custom assert that uses verifySnapshot to specify a shared snapshot directory.
    private func assertSharedSnapshot<Value, Format>(
        of value: @autoclosure () throws -> Value,
        as snapshotting: Snapshotting<Value, Format>,
        named name: String? = nil,
        testName: String,
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let failure = try verifySnapshot(
            of: value(),
            as: snapshotting,
            named: name,
            snapshotDirectory: snapshotDirectory,
            fileID: fileID,
            file: file,
            testName: testName,
            line: line,
            column: column
        )
        if let message = failure {
            Issue.record(Comment(rawValue: message), sourceLocation: SourceLocation(fileID: String(describing: fileID), filePath: String(describing: file), line: Int(line), column: Int(column)))
        }
    }

    private func nameForDevice(baseName: String? = nil) -> String {
        let size = UIScreen.main.bounds.size
        let scale = UIScreen.main.scale
        let version = UIDevice.current.systemVersion
        let deviceName = "\(Int(size.width))x\(Int(size.height))-\(version)-\(Int(scale))x"

        return [baseName, deviceName]
            .compactMap { $0 }
            .joined(separator: "-")
    }
}

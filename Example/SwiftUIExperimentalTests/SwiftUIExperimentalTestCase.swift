import FBSnapshotTestCase_Accessibility
import iOSSnapshotTestCase

import SwiftUI

/// Base test case for SwiftUI Experimental tests.
///
/// These tests require iOS 16.0+ and use the SwiftUI layout engine to demonstrate
/// accessibility snapshot testing with SwiftUI-rendered overlays.
///
/// ## Usage
///
/// Use the `snapshotVerifyAccessibility(_:identifier:file:line:)` helper method
/// which automatically uses the correct size and layout engine:
///
/// ```swift
/// func testMyView() {
///     snapshotVerifyAccessibility(MySwiftUIView())
/// }
/// ```
///
/// This helper ensures SwiftUI views are rendered at screen size, which is
/// required for views with flexible layouts (e.g., `ScrollView`, `List`).
@available(iOS 16.0, *)
class SwiftUIExperimentalTestCase: FBSnapshotTestCase {
    // MARK: - Accessibility Snapshot Helper

    /// Snapshots a SwiftUI view using the SwiftUI layout engine at screen size.
    ///
    /// - Parameters:
    ///   - view: The SwiftUI view to snapshot.
    ///   - identifier: Optional identifier for multiple snapshots in one test.
    ///   - file: Source file (auto-captured).
    ///   - line: Source line (auto-captured).
    func snapshotVerifyAccessibility<V: View>(
        _ view: V,
        identifier: String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        SnapshotVerifyAccessibility(
            view,
            size: UIScreen.main.bounds.size,
            identifier: identifier,
            layoutEngine: .swiftui,
            file: file,
            line: line
        )
    }

    // MARK: - Configuration

    private struct TestDeviceConfig: Equatable {
        var systemVersion: String
        var screenSize: CGSize
        var screenScale: CGFloat
    }

    private static let testedDevices = [
        TestDeviceConfig(systemVersion: "18.5", screenSize: CGSize(width: 402, height: 874), screenScale: 3),
        TestDeviceConfig(systemVersion: "26.2", screenSize: CGSize(width: 402, height: 874), screenScale: 3),
    ]

    override func setUp() {
        super.setUp()

        let currentConfig = TestDeviceConfig(
            systemVersion: UIDevice.current.systemVersion,
            screenSize: UIScreen.main.bounds.size,
            screenScale: UIScreen.main.scale
        )
        guard Self.testedDevices.contains(currentConfig) else {
            fatalError(
                "Attempting to run tests on a device that is not in the testedDevices list. "
                    + "Current device: iOS \(currentConfig.systemVersion), "
                    + "\(Int(currentConfig.screenSize.width))x\(Int(currentConfig.screenSize.height)) "
                    + "@\(Int(currentConfig.screenScale))x"
            )
        }

        guard ProcessInfo.processInfo.environment["FB_REFERENCE_IMAGE_DIR"] != nil else {
            fatalError("FB_REFERENCE_IMAGE_DIR not set. Make sure the current scheme sets this environment variable.")
        }

        guard UIApplication.shared.preferredContentSizeCategory == .large else {
            fatalError("Dynamic Type must be set to the default (.large) to run snapshot tests.")
        }

        fileNameOptions = [.OS, .screenSize, .screenScale]
        recordMode = false
    }
}

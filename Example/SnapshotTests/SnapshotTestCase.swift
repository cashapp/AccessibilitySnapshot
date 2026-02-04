import AccessibilitySnapshotCore
import FBSnapshotTestCase_Accessibility
import iOSSnapshotTestCase
import SwiftUI

class SnapshotTestCase: FBSnapshotTestCase {
    // MARK: - Layout Engine Configuration

    var layoutEngine: LayoutEngine { .default }

    // MARK: - SwiftUI Accessibility Snapshot Helper

    @available(iOS 16.0, *)
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
            layoutEngine: layoutEngine,
            file: file,
            line: line
        )
    }

    // MARK: - Private Types

    private struct TestDeviceConfig {
        // MARK: - Public Properties

        let systemVersion: String
        let screenSize: CGSize
        let screenScale: CGFloat

        // MARK: - Public Methods

        func matchesCurrentDevice() -> Bool {
            let device = UIDevice.current
            let screen = UIScreen.main

            return device.systemVersion == systemVersion
                && screen.bounds.size == screenSize
                && screen.scale == screenScale
        }
    }

    // MARK: - Private Static Properties

    private static let testedDevices = [
        TestDeviceConfig(systemVersion: "17.5", screenSize: CGSize(width: 393, height: 852), screenScale: 3),
        TestDeviceConfig(systemVersion: "18.5", screenSize: CGSize(width: 402, height: 874), screenScale: 3),
        TestDeviceConfig(systemVersion: "26.2", screenSize: CGSize(width: 402, height: 874), screenScale: 3),
    ]

    // MARK: - FBSnapshotTestCase

    override func setUp() {
        super.setUp()

        guard SnapshotTestCase.testedDevices.contains(where: { $0.matchesCurrentDevice() }) else {
            fatalError("Attempting to run tests on a device for which we have not collected test data.\n- iOS \(UIDevice.current.systemVersion),\(UIScreen.main.bounds.size.width)x\(UIScreen.main.bounds.size.height) @\(UIScreen.main.scale)x")
        }

        guard ProcessInfo.processInfo.environment["FB_REFERENCE_IMAGE_DIR"] != nil else {
            fatalError("The environment variable FB_REFERENCE_IMAGE_DIR must be set for the current scheme")
        }

        guard UIApplication.shared.preferredContentSizeCategory == .large else {
            fatalError("Tests must be run on a device that has Dynamic Type disabled")
        }

        fileNameOptions = [.OS, .screenSize, .screenScale]

        recordMode = false
    }
}

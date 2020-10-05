//
//  Copyright 2020 Square Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import AccessibilitySnapshot
import SnapshotTesting
import XCTest

@testable import AccessibilitySnapshotDemo

/// Tests covering the integration between the core components of AccessibilitySnapshot and SnapshotTesting.
final class SnapshotTestingTests: XCTestCase {

    // MARK: - Tests

    func testSimpleConfiguration() {
        let viewController = ViewAccessibilityPropertiesViewController()
        viewController.view.frame = UIScreen.main.bounds
        assertSnapshot(matching: viewController, as: .accessibilityImage, named: nameForDevice())
    }

    func testShowingActivationPoint() {
        let viewController = ActivationPointViewController()
        viewController.view.frame = UIScreen.main.bounds

        assertSnapshot(
            matching: viewController,
            as: .accessibilityImage(showActivationPoints: .always),
            named: nameForDevice(baseName: "always")
        )

        assertSnapshot(
            matching: viewController,
            as: .accessibilityImage(showActivationPoints: .whenOverridden),
            named: nameForDevice(baseName: "whenOverridden")
        )

        assertSnapshot(
            matching: viewController,
            as: .accessibilityImage(showActivationPoints: .never),
            named: nameForDevice(baseName: "never")
        )
    }

    func testUsingMonochromeSnapshot() {
        let view = UILabel()
        view.text = "Hello World"
        view.textColor = .red
        view.sizeToFit()

        assertSnapshot(
            matching: view,
            as: .accessibilityImage(useMonochromeSnapshot: false),
            named: nameForDevice(baseName: "false")
        )

        assertSnapshot(
            matching: view,
            as: .accessibilityImage(useMonochromeSnapshot: true),
            named: nameForDevice(baseName: "true")
        )
    }

    func testMarkerColors() {
        let view = AccessibleContainerView(count: 8, innerMargin: 10)
        view.sizeToFit()

        assertSnapshot(
            matching: view,
            as: .accessibilityImage(),
            named: nameForDevice(baseName: "default")
        )

        assertSnapshot(
            matching: view,
            as: .accessibilityImage(markerColors: [.red, .green, .blue]),
            named: nameForDevice(baseName: "custom")
        )
    }

    func testInvertColors() {
        guard #available(iOS 11, *) else {
            // Snapshotting with inverted colors is only available on iOS 11+.
            return
        }

        let viewController = InvertColorsViewController()
        viewController.view.frame = UIScreen.main.bounds
        assertSnapshot(matching: viewController, as: .imageWithSmartInvert, named: nameForDevice())
    }

    // MARK: - Private Methods

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

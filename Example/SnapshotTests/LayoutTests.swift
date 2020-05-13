//
//  Copyright 2019 Square Inc.
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

import FBSnapshotTestCase
import UIKit

@testable import AccessibilitySnapshot

final class LayoutTests: SnapshotTestCase {

    // MARK: - Tests

    func testStandard() {
        let view = UIView(frame: .init(x: 0, y: 0, width: 200, height: 50))

        for _ in 0..<5 {
            addAccessibleView(to: view)
        }

        SnapshotVerifyAccessibility(view)
    }

    func testClipping() {
        let view = UIView(frame: .init(x: 0, y: 0, width: 200, height: 200))
        view.backgroundColor = .white

        // Position the element so that it will go outside the bounds of the parent view.
        let accessibleView = UIView(
            frame: .init(x: view.bounds.maxX - 50, y: view.bounds.maxY - 50, width: 100, height: 100)
        )
        accessibleView.isAccessibilityElement = true
        accessibleView.accessibilityLabel = "Label"
        view.addSubview(accessibleView)

        SnapshotVerifyAccessibility(view)
    }

    // MARK: - Tests - Full Screen

    func testFullScreenWithFewMarkers() {
        let view = UIView(frame: UIScreen.main.bounds)

        for _ in 0..<3 {
            addAccessibleView(to: view)
        }

        SnapshotVerifyAccessibility(view)
    }

    func testFullScreenWithManyMarkers() {
        let view = UIView(frame: UIScreen.main.bounds)

        for _ in 0..<24 {
            addAccessibleView(to: view)
        }

        SnapshotVerifyAccessibility(view)
    }

    func testFullScreenWithManyManyMarkers() {
        let view = UIView(frame: UIScreen.main.bounds)

        for _ in 0..<70 {
            addAccessibleView(to: view)
        }

        SnapshotVerifyAccessibility(view)
    }

    // MARK: - Tests - Wide Views

    func testWideViewWithFewMarkers() {
        let view = UIView(frame: .init(x: 0, y: 0, width: 1000, height: 50))

        for _ in 0..<3 {
            addAccessibleView(to: view)
        }

        SnapshotVerifyAccessibility(view)
    }

    func testWideViewWithManyMarkers() {
        let view = UIView(frame: .init(x: 0, y: 0, width: 1000, height: 50))

        for _ in 0..<70 {
            addAccessibleView(to: view)
        }

        SnapshotVerifyAccessibility(view)
    }

    // MARK: - Tests - Text Wrapping

    func testLongMarkerDescription() {
        let view = UIView(frame: .init(x: 0, y: 0, width: 200, height: 50))

        addAccessibleView(to: view, accessibilityLabel: Factory.longText)

        SnapshotVerifyAccessibility(view)
    }

    // MARK: - Private Methods

    private func addAccessibleView(
        to view: UIView,
        accessibilityLabel: String? = "Accessibility Label",
        accessibilityHint: String? = nil
    ) {
        let accessibleView = UIView(frame: view.bounds)
        accessibleView.isAccessibilityElement = true
        accessibleView.accessibilityLabel = accessibilityLabel
        accessibleView.accessibilityHint = accessibilityHint

        view.addSubview(accessibleView)
    }

}

// MARK: -

private enum Factory {

    static let longText = "This is long text that will cause the label to wrap to multiple lines given the default "
                            + "width of the legend."

}

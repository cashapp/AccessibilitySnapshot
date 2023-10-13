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

import AccessibilitySnapshot
import FBSnapshotTestCase

@testable import AccessibilitySnapshotDemo

final class ElementSelectionTests: SnapshotTestCase {

    func testTwoAccessibilityElements() {
        let elementSelectionViewController = ElementSelectionViewController(
            configurations: .twoAccessibilityElements
        )
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementSelectionViewController.view)
    }

    func testAccessibilityElementWithElementsHidden() {
        let elementSelectionViewController = ElementSelectionViewController(
            configurations: .accessibilityElementWithElementsHidden
        )
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementSelectionViewController.view)
    }

    func testAccessibilityElementHidden() {
        let elementSelectionViewController = ElementSelectionViewController(
            configurations: .accessibilityElementHidden
        )
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementSelectionViewController.view)
    }

    func testNoAccessibilityElements() {
        let elementSelectionViewController = ElementSelectionViewController(
            configurations: .noAccessibilityElements
        )
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementSelectionViewController.view)
    }

    func testMixedAccessibilityElements() {
        let elementSelectionViewController = ElementSelectionViewController(
            configurations: .mixedAccessibilityElements
        )
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementSelectionViewController.view)
    }

    func testAccessibilityContainer() {
        let elementSelectionViewController = ElementSelectionViewController(
            configurations: .accessibilityContainer
        )
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementSelectionViewController.view)
    }

    func testAccessibilityContainerWithElementsHidden() {
        let elementSelectionViewController = ElementSelectionViewController(
            configurations: .accessibilityContainerWithElementsHidden
        )
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementSelectionViewController.view)
    }

    func testAccessibilityContainerHidden() {
        let elementSelectionViewController = ElementSelectionViewController(
            configurations: .accessibilityContainerHidden
        )
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementSelectionViewController.view)
    }

    func testGroupedViews() {
        let elementSelectionViewController = ElementSelectionViewController(
            configurations: .groupedViews
        )
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementSelectionViewController.view)
    }

    func testGroupedViewsInParentThatHidesElements() {
        let elementSelectionViewController = ElementSelectionViewController(
            configurations: .groupedViewsInParentThatHidesElements
        )
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementSelectionViewController.view)
    }

    func testGroupedViewsInHiddenParent() {
        let elementSelectionViewController = ElementSelectionViewController(
            configurations: .groupedViewsInHiddenParent
        )
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementSelectionViewController.view)
    }

}

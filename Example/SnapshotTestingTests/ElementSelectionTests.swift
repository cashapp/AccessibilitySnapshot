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
import SnapshotTesting
import UIKit

@testable import AccessibilitySnapshotDemo

final class ElementSelectionTests: SnapshotTestCase {

    func testTwoAccessibilityElements() {
        let elementSelectionViewController = ElementSelectionViewController(configurations: [
            .accessibilityElement(accessibilityElementsHidden: false, isHidden: false),
            .accessibilityElement(accessibilityElementsHidden: false, isHidden: false),
        ])
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        assertSnapshot(matching: elementSelectionViewController, as: .accessibilityImage)
    }

    func testAccessibilityElementWithElementsHidden() {
        let elementSelectionViewController = ElementSelectionViewController(configurations: [
            .accessibilityElement(accessibilityElementsHidden: false, isHidden: false),
            .accessibilityElement(accessibilityElementsHidden: true, isHidden: false),
        ])
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        assertSnapshot(matching: elementSelectionViewController, as: .accessibilityImage)
    }

    func testAccessibilityElementHidden() {
        let elementSelectionViewController = ElementSelectionViewController(configurations: [
            .accessibilityElement(accessibilityElementsHidden: false, isHidden: false),
            .accessibilityElement(accessibilityElementsHidden: false, isHidden: true),
        ])
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        assertSnapshot(matching: elementSelectionViewController, as: .accessibilityImage)
    }

    func testNoAccessibilityElements() {
        let elementSelectionViewController = ElementSelectionViewController(configurations: [
            .nonAccessibilityElement,
            .nonAccessibilityElement,
        ])
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        assertSnapshot(matching: elementSelectionViewController, as: .accessibilityImage)
    }

    func testMixedAccessibilityElements() {
        let elementSelectionViewController = ElementSelectionViewController(configurations: [
            .accessibilityElement(accessibilityElementsHidden: false, isHidden: false),
            .nonAccessibilityElement,
            .accessibilityElement(accessibilityElementsHidden: false, isHidden: false),
            .nonAccessibilityElement,
        ])
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        assertSnapshot(matching: elementSelectionViewController, as: .accessibilityImage)
    }

    func testAccessibilityContainer() {
        let elementSelectionViewController = ElementSelectionViewController(configurations: [
            .accessibilityContainer(accessibilityElementsHidden: false, isHidden: false),
        ])
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        assertSnapshot(matching: elementSelectionViewController, as: .accessibilityImage)
    }

    func testAccessibilityContainerWithElementsHidden() {
        let elementSelectionViewController = ElementSelectionViewController(configurations: [
            .accessibilityElement(accessibilityElementsHidden: false, isHidden: false),
            .accessibilityContainer(accessibilityElementsHidden: true, isHidden: false),
        ])
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        assertSnapshot(matching: elementSelectionViewController, as: .accessibilityImage)
    }

    func testAccessibilityContainerHidden() {
        let elementSelectionViewController = ElementSelectionViewController(configurations: [
            .accessibilityElement(accessibilityElementsHidden: false, isHidden: false),
            .accessibilityContainer(accessibilityElementsHidden: false, isHidden: true),
        ])
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        assertSnapshot(matching: elementSelectionViewController, as: .accessibilityImage)
    }

    func testGroupedViews() {
        let elementSelectionViewController = ElementSelectionViewController(configurations: [
            .accessibilityElement(accessibilityElementsHidden: false, isHidden: false),
            .viewWithAccessibleSubviews(accessibilityElementsHidden: false, isHidden: false),
        ])
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        assertSnapshot(matching: elementSelectionViewController, as: .accessibilityImage)
    }

    func testGroupedViewsInParentThatHidesElements() {
        let elementSelectionViewController = ElementSelectionViewController(configurations: [
            .accessibilityElement(accessibilityElementsHidden: false, isHidden: false),
            .viewWithAccessibleSubviews(accessibilityElementsHidden: true, isHidden: false),
        ])
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        assertSnapshot(matching: elementSelectionViewController, as: .accessibilityImage)
    }

    func testGroupedViewsInHiddenParent() {
        let elementSelectionViewController = ElementSelectionViewController(configurations: [
            .accessibilityElement(accessibilityElementsHidden: false, isHidden: false),
            .viewWithAccessibleSubviews(accessibilityElementsHidden: false, isHidden: true),
        ])
        elementSelectionViewController.view.frame = UIScreen.main.bounds
        assertSnapshot(matching: elementSelectionViewController, as: .accessibilityImage)
    }

}

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

final class AccessibilitySnapshotTests: SnapshotTestCase {

    func testViewDescription() {
        let viewPropertiesViewController = ViewAccessibilityPropertiesViewController()
        viewPropertiesViewController.view.frame = UIScreen.main.bounds
        assertSnapshot(matching: viewPropertiesViewController, as: .accessibilityImage)
    }

    func testLabelDescription() {
        let labelPropertiesViewController = LabelAccessibilityPropertiesViewController()
        labelPropertiesViewController.view.frame = UIScreen.main.bounds
        assertSnapshot(matching: labelPropertiesViewController, as: .accessibilityImage)
    }

    func testButtonTraits() {
        let buttonTraitsViewController = ButtonAccessibilityTraitsViewController()
        buttonTraitsViewController.view.frame = UIScreen.main.bounds
        assertSnapshot(matching: buttonTraitsViewController, as: .accessibilityImage)
    }

    func testDescriptionEdgeCases() {
        let descriptionEdgeCasesViewController = DescriptionEdgeCasesViewController()
        descriptionEdgeCasesViewController.view.frame = UIScreen.main.bounds
        assertSnapshot(matching: descriptionEdgeCasesViewController, as: .accessibilityImage)
    }

    func testAccessibilityPaths() {
        let accessibilityPathViewController = AccessibilityPathViewController()
        accessibilityPathViewController.view.frame = UIScreen.main.bounds
        assertSnapshot(matching: accessibilityPathViewController, as: .accessibilityImage)
    }

    func testTabBars() {
        let tabBarViewController = TabBarViewController()
        tabBarViewController.view.frame = UIScreen.main.bounds
        assertSnapshot(matching: tabBarViewController, as: .accessibilityImage)
    }

    func testCustomActions() {
        let customActionsViewController = AccessibilityCustomActionsViewController()
        customActionsViewController.view.frame = UIScreen.main.bounds
        assertSnapshot(matching: customActionsViewController, as: .accessibilityImage)
    }

}

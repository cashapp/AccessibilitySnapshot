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
import Paralayout

@testable import AccessibilitySnapshotDemo

final class AccessibilitySnapshotTests: SnapshotTestCase {

    func testViewDescription() {
        let viewPropertiesViewController = ViewAccessibilityPropertiesViewController()
        viewPropertiesViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(viewPropertiesViewController.view)
    }

    func testLabelDescription() {
        let labelPropertiesViewController = LabelAccessibilityPropertiesViewController()
        labelPropertiesViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(labelPropertiesViewController.view)
    }

    func testButtonTraits() {
        let buttonTraitsViewController = ButtonAccessibilityTraitsViewController()
        buttonTraitsViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(buttonTraitsViewController.view)
    }

    func testDescriptionEdgeCases() {
        let descriptionEdgeCasesViewController = DescriptionEdgeCasesViewController()
        descriptionEdgeCasesViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(descriptionEdgeCasesViewController.view)
    }

    func testAccessibilityPaths() {
        let accessibilityPathViewController = AccessibilityPathViewController()
        accessibilityPathViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(accessibilityPathViewController.view)
    }

    func testTabBars() {
        let tabBarViewController = TabBarViewController()
        tabBarViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(tabBarViewController.view)
    }

    func testCustomActions() {
        let customActionsViewController = AccessibilityCustomActionsViewController()
        customActionsViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(customActionsViewController.view)
    }

    func testLargeView() throws {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 1400, height: 1400))
        view.backgroundColor = .white

        let label = UILabel()
        label.text = "Hello world"
        label.textColor = .red
        view.addSubview(label)

        label.sizeToFit()
        label.center = view.point(at: .center)

        if ProcessInfo().operatingSystemVersion.majorVersion != 13 {
            SnapshotVerifyAccessibility(view, identifier: "monochrome", useMonochromeSnapshot: true)
        }

        SnapshotVerifyAccessibility(view, identifier: "polychrome", useMonochromeSnapshot: false)
    }

}

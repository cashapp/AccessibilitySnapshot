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

    // This test is currently disabled due to a bug in iOSSnapshotTestCase. See cashapp/AccessibilitySnapshot#75.
    func testLargeViewThatRequiresTiling() throws {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 3000, height: 3000))

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.blue.cgColor, UIColor.white.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        view.layer.addSublayer(gradientLayer)
        gradientLayer.frame = view.bounds

        let label = UILabel()
        label.text = "Hello world"
        label.textColor = .red
        view.addSubview(label)

        label.sizeToFit()
        label.center = view.point(at: .center)

        usingDrawViewHierarchyInRect {
            SnapshotVerifyAccessibility(view, useMonochromeSnapshot: false)
        }
    }

    func testViewInViewControllerHierarchy() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

        let label = UILabel()
        label.text = "Hello world"
        label.textColor = .red
        view.addSubview(label)

        label.sizeToFit()
        label.center = view.point(at: .center)

        let viewController = UIViewController()
        viewController.view = view

        let parent = UIViewController()
        parent.addChild(viewController)
        parent.view.addSubview(view)

        SnapshotVerifyAccessibility(view)

        // Verify that the original state was restored correctly.
        XCTAssertEqual(view.superview, parent.view)
        XCTAssertEqual(viewController.parent, parent)
    }

    // This test is currently disabled due to a bug in iOSSnapshotTestCase. See cashapp/AccessibilitySnapshot#75.
    func testLargeViewInViewControllerThatRequiresTiling() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 3000, height: 3000))

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.blue.cgColor, UIColor.white.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        view.layer.addSublayer(gradientLayer)
        gradientLayer.frame = view.bounds

        let label = UILabel()
        label.text = "Hello world"
        label.textColor = .red
        view.addSubview(label)

        label.sizeToFit()
        label.center = view.point(at: .center)

        let viewController = UIViewController()
        viewController.view = view

        let parent = UIViewController()
        parent.addChild(viewController)
        parent.view.addSubview(view)

        usingDrawViewHierarchyInRect {
            SnapshotVerifyAccessibility(view, useMonochromeSnapshot: false)
        }
    }

    // MARK: - Private Methods

    private func usingDrawViewHierarchyInRect(_ test: () -> Void) {
        let oldValue = usesDrawViewHierarchyInRect
        usesDrawViewHierarchyInRect = true
        test()
        usesDrawViewHierarchyInRect = oldValue
    }

}

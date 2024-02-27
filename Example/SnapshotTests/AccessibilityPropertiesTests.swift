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

    func testSwitchControls() {
        let switchControlViewController = SwitchControlViewController()
        switchControlViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(switchControlViewController.view)
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
    
    @available(iOS 14.0, *)
    func testCustomContent() throws {
        try XCTSkipUnless(
            ProcessInfo().operatingSystemVersion.majorVersion >= 14,
            "This test only supports iOS 14 and later"
        )
        
        let customContentViewController = AccessibilityCustomContentViewController()
        customContentViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(customContentViewController.view)
    }

    func testLargeView() throws {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 1400, height: 1400))
        view.backgroundColor = .white

        let label = UILabel()
        label.text = "Hello world"
        label.textColor = .red
        view.addSubview(label)

        label.sizeToFit()
        label.align(withSuperview: .center)

        if ProcessInfo().operatingSystemVersion.majorVersion != 13 {
            SnapshotVerifyAccessibility(view, identifier: "monochrome", useMonochromeSnapshot: true)
        }

        SnapshotVerifyAccessibility(view, identifier: "polychrome", useMonochromeSnapshot: false)
    }

    // This test is currently disabled due to a bug in iOSSnapshotTestCase. See cashapp/AccessibilitySnapshot#75.
    func testLargeViewThatRequiresTiling() throws {
        let view = GradientBackgroundView(
            frame: CGRect(x: 0, y: 0, width: 3000, height: 3000),
            showSafeAreaInsets: true
        )

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
        label.align(withSuperview: .center)

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

    func testViewAsSubviewOfViewInViewControllerHierarchy() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

        let label = UILabel()
        label.text = "Hello world"
        label.textColor = .red
        view.addSubview(label)

        label.sizeToFit()
        label.align(withSuperview: .center)

        let viewController = UIViewController()
        viewController.view.addSubview(view)

        let parent = UIViewController()
        parent.addChild(viewController)
        parent.view.addSubview(viewController.view)

        SnapshotVerifyAccessibility(view)

        // Verify that the original state was restored correctly.
        XCTAssertEqual(view.superview, viewController.view)
    }

    // This test is currently disabled due to a bug in iOSSnapshotTestCase. See cashapp/AccessibilitySnapshot#75.
    func testLargeViewInViewControllerThatRequiresTiling() {
        let view = GradientBackgroundView(
            frame: CGRect(x: 0, y: 0, width: 3000, height: 3000),
            showSafeAreaInsets: true
        )

        let viewController = UIViewController()
        viewController.additionalSafeAreaInsets = .init(top: 600, left: 1000, bottom: 300, right: 100)
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

    // MARK: - Private Types

    private final class GradientBackgroundView: UIView {

        // MARK: - Life Cycle

        init(frame: CGRect, showSafeAreaInsets: Bool) {
            super.init(frame: frame)

            gradientLayer.colors = [UIColor.blue.cgColor, UIColor.white.cgColor]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)
            layer.addSublayer(gradientLayer)

            label.text = "Hello world"
            label.textColor = .red
            label.backgroundColor = .black
            addSubview(label)

            safeAreaView.layer.borderColor = UIColor.red.cgColor
            safeAreaView.layer.borderWidth = 1
            safeAreaView.isHidden = !showSafeAreaInsets
            addSubview(safeAreaView)

            layoutMargins = .init(top: 8, left: 8, bottom: 8, right: 8)
            insetsLayoutMarginsFromSafeArea = true

            layoutMarginsView.layer.borderColor = UIColor.green.cgColor
            layoutMarginsView.layer.borderWidth = 0.5
            layoutMarginsView.isHidden = !showSafeAreaInsets
            addSubview(layoutMarginsView)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let gradientLayer: CAGradientLayer = .init()

        private let label: UILabel = .init()

        private let safeAreaView: UIView = .init()

        private let layoutMarginsView: UIView = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            gradientLayer.frame = bounds

            let insetBounds = bounds.inset(by: safeAreaInsets)

            label.sizeToFit()
            label.center = CGPoint(x: insetBounds.midX, y: insetBounds.midY)

            safeAreaView.frame = insetBounds
            layoutMarginsView.frame = bounds.inset(by: layoutMargins)
        }

    }

}

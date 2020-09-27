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

final class DefaultControlsTests: SnapshotTestCase {

    // MARK: - UIDatePicker

    // This test is disabled because the accessibility descriptions are not correct.
    func testDatePicker() {
        let datePicker = UIDatePicker()

        let container = ContainerView(control: datePicker)
        container.frame.size = container.sizeThatFits(UIScreen.main.bounds.size)

        assertSnapshot(matching: container, as: .accessibilityImage)
    }

    // MARK: - UIPageControl

    func testPageControl() {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = 3
        pageControl.currentPage = 1
        pageControl.pageIndicatorTintColor = .darkGray
        pageControl.currentPageIndicatorTintColor = .black

        let container = ContainerView(control: pageControl)
        container.frame.size = container.sizeThatFits(UIScreen.main.bounds.size)

        assertSnapshot(matching: container, as: .accessibilityImage)
    }

    // MARK: - UISegmentedControl

    func testSegmentedControl() {
        let segmentedControl = UISegmentedControl()
        segmentedControl.insertSegment(withTitle: "Segment A", at: 0, animated: false)
        segmentedControl.insertSegment(withTitle: "Segment B", at: 1, animated: false)
        segmentedControl.insertSegment(withTitle: "Segment C", at: 2, animated: false)
        segmentedControl.selectedSegmentIndex = 1

        let container = ContainerView(control: segmentedControl)
        container.frame.size = container.sizeThatFits(UIScreen.main.bounds.size)

        assertSnapshot(matching: container, as: .accessibilityImage)
    }

    // MARK: - UISlider

    func testSlider() {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.value = 75

        let container = ContainerView(control: slider)
        container.frame.size = container.sizeThatFits(UIScreen.main.bounds.size)

        assertSnapshot(matching: container, as: .accessibilityImage)
    }

    // MARK: - UIStepper

    func testStepper() {
        let stepper = UIStepper()
        stepper.minimumValue = -1
        stepper.maximumValue = 1
        stepper.value = 0

        let container = ContainerView(control: stepper)
        container.frame.size = container.sizeThatFits(UIScreen.main.bounds.size)

        assertSnapshot(matching: container, as: .accessibilityImage)
    }

    func testStepperAtMin() {
        let stepper = UIStepper()
        stepper.minimumValue = 0
        stepper.maximumValue = 1
        stepper.value = 0

        let container = ContainerView(control: stepper)
        container.frame.size = container.sizeThatFits(UIScreen.main.bounds.size)

        assertSnapshot(matching: container, as: .accessibilityImage)
    }

}

// MARK: -

private final class ContainerView: UIView {

    // MARK: - Life Cycle

    init(control: UIControl) {
        self.control = control

        super.init(frame: .zero)

        backgroundColor = .white

        addSubview(control)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Properties

    private let control: UIControl

    // MARK: - UIView

    override func layoutSubviews() {
        control.frame.size = control.sizeThatFits(bounds.insetBy(dx: 10, dy: 10).size)
        control.alignToSuperview(.center)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let controlSize = control.sizeThatFits(size)
        return CGSize(width: size.width, height: controlSize.height + 20)
    }

}

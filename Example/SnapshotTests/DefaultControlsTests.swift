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

final class DefaultControlsTests: SnapshotTestCase {

    // MARK: - UIDatePicker

    // This test is disabled because the accessibility descriptions are not correct.
    func testDatePicker() {
        let datePicker = UIDatePicker()

        let container = ContainerView(subview: datePicker)
        container.frame.size = container.sizeThatFits(UIScreen.main.bounds.size)

        SnapshotVerifyAccessibility(container)
    }

    // MARK: - UIPageControl

    func testPageControl() {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = 3
        pageControl.currentPage = 1
        pageControl.pageIndicatorTintColor = .darkGray
        pageControl.currentPageIndicatorTintColor = .black

        let container = ContainerView(subview: pageControl)
        container.frame.size = container.sizeThatFits(UIScreen.main.bounds.size)

        SnapshotVerifyAccessibility(container)
    }

    // MARK: - UISegmentedControl

    func testSegmentedControl() {
        let segmentedControl = UISegmentedControl()
        segmentedControl.insertSegment(withTitle: "Segment A", at: 0, animated: false)
        segmentedControl.insertSegment(withTitle: "Segment B", at: 1, animated: false)
        segmentedControl.insertSegment(withTitle: "Segment C", at: 2, animated: false)
        segmentedControl.selectedSegmentIndex = 1

        let container = ContainerView(subview: segmentedControl)
        container.frame.size = container.sizeThatFits(UIScreen.main.bounds.size)

        SnapshotVerifyAccessibility(container)
    }

    // MARK: - UISlider

    func testSlider() {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.value = 75

        let container = ContainerView(subview: slider)
        container.frame.size = container.sizeThatFits(UIScreen.main.bounds.size)

        SnapshotVerifyAccessibility(container)
    }

    // MARK: - UIStepper

    func testStepper() {
        let stepper = UIStepper()
        stepper.minimumValue = -1
        stepper.maximumValue = 1
        stepper.value = 0

        let container = ContainerView(subview: stepper)
        container.frame.size = container.sizeThatFits(UIScreen.main.bounds.size)

        SnapshotVerifyAccessibility(container)
    }

    func testStepperAtMin() {
        let stepper = UIStepper()
        stepper.minimumValue = 0
        stepper.maximumValue = 1
        stepper.value = 0

        let container = ContainerView(subview: stepper)
        container.frame.size = container.sizeThatFits(UIScreen.main.bounds.size)

        SnapshotVerifyAccessibility(container)
    }

}

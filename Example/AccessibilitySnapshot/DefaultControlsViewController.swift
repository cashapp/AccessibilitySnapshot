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

import Paralayout
import UIKit

final class DefaultControlsViewController: AccessibilityViewController {

    // MARK: - Private Properties

    private let datePicker: UIDatePicker = .init()

    private let pageControl: UIPageControl = .init()

    private let segmentedControl: UISegmentedControl = .init()

    private let slider: UISlider = .init()

    private let stepper: UIStepper = .init()

    private var controls: [UIControl] {
        return [
            datePicker,
            pageControl,
            segmentedControl,
            slider,
            stepper,
        ]
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        pageControl.numberOfPages = 3
        pageControl.pageIndicatorTintColor = .lightGray
        pageControl.currentPageIndicatorTintColor = .black

        segmentedControl.insertSegment(withTitle: "Segment A", at: 0, animated: false)
        segmentedControl.insertSegment(withTitle: "Segment B", at: 1, animated: false)
        segmentedControl.insertSegment(withTitle: "Segment C", at: 2, animated: false)

        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.value = 75

        stepper.minimumValue = -1
        stepper.maximumValue = 1
        stepper.value = 0

        controls.forEach { view.addSubview($0) }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        controls.forEach { $0.sizeToFit() }

        let statusBarHeight = UIApplication.shared.statusBarFrame.height

        var distributionSpecifiers: [ViewDistributionSpecifying] = [ statusBarHeight.fixed, 1.flexible ]
        for subview in controls {
            distributionSpecifiers.append(subview)
            distributionSpecifiers.append(1.flexible)
        }
        view.applySubviewDistribution(distributionSpecifiers)
    }

}

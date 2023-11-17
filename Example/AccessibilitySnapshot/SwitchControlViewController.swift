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

final class SwitchControlViewController: AccessibilityViewController {

    // MARK: - UIViewController

    override func loadView() {
        view = View()
    }

}

// MARK: -

private extension SwitchControlViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            switchControls[0].isOn = true

            switchControls[1].isOn = false

            switchControls[2].isOn = true
            switchControls[2].isEnabled = false

            switchControls[3].isOn = true
            switchControls[3].accessibilityLabel = "Label"

            switchControls[4].isOn = false
            switchControls[4].accessibilityLabel = "Label"

            switchControls[5].isOn = true
            switchControls[5].accessibilityLabel = "Label"
            switchControls[5].accessibilityValue = "Value"

            switchControls[6].isOn = true
            switchControls[6].accessibilityLabel = "Label"
            switchControls[6].accessibilityValue = "Value"
            switchControls[6].accessibilityHint = "Hint"

            switchControls[7].isOn = false
            switchControls[7].accessibilityLabel = "Label"
            switchControls[7].accessibilityValue = "Value"
            switchControls[7].accessibilityHint = "Hint"
            switchControls[7].accessibilityTraits.insert([
                .selected,
                .button,
                .header,
                .link,
                .adjustable,
                .image,
                .searchField,
            ])

            switchControls[8].isOn = false
            switchControls[8].accessibilityLabel = "Label"
            switchControls[8].accessibilityValue = "Value"
            switchControls[8].accessibilityHint = "Hint"
            switchControls[8].accessibilityTraits.insert([
                .selected,
                .notEnabled,
                .button,
                .header,
                .link,
                .adjustable,
                .image,
                .searchField,
            ])

            switchControls.forEach { addSubview($0) }

            let switchTrait = UIAccessibilityTraits(rawValue: 0x0020000000000000)

            // Add a fake switch that has the switch button trait only, but is not a UISwitch.
            for fakeSwitchView in fakeSwitchViews {
                fakeSwitchView.isAccessibilityElement = true
                fakeSwitchView.accessibilityLabel = "Fake Label"
                fakeSwitchView.frame.size = .init(width: 48, height: 32)
                fakeSwitchView.backgroundColor = .lightGray
                fakeSwitchView.layer.cornerRadius = 16
            }

            fakeSwitchViews[0].accessibilityValue = "1"
            fakeSwitchViews[0].accessibilityTraits = [switchTrait, .button]

            fakeSwitchViews[1].accessibilityValue = "0"
            fakeSwitchViews[1].accessibilityTraits = [switchTrait, .button]

            fakeSwitchViews[2].accessibilityValue = "2"
            fakeSwitchViews[2].accessibilityTraits = [switchTrait, .button]

            fakeSwitchViews[3].accessibilityValue = "1"
            fakeSwitchViews[3].accessibilityTraits = [switchTrait]

            fakeSwitchViews[4].accessibilityValue = "3"
            fakeSwitchViews[4].accessibilityTraits = [switchTrait]

            fakeSwitchViews[5].accessibilityValue = "Value"
            fakeSwitchViews[5].accessibilityTraits = [.button, switchTrait]

            fakeSwitchViews.forEach { addSubview($0) }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let switchControls: [UISwitch] = (0..<9).map { _ in UISwitch() }

        /// `UIView`s with the switch button trait that act like a switch, but aren't actually switches.
        private let fakeSwitchViews: [UIView] = (0..<6).map { _ in UIView() }

        // MARK: - UIView

        override func layoutSubviews() {
            switchControls.forEach { $0.sizeToFit() }

            let statusBarHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0

            var distributionSpecifiers: [ViewDistributionSpecifying] = [ statusBarHeight.fixed, 1.flexible ]
            for subview in (switchControls + fakeSwitchViews) {
                distributionSpecifiers.append(subview)
                distributionSpecifiers.append(1.flexible)
            }
            applyVerticalSubviewDistribution(distributionSpecifiers)
        }

    }

}

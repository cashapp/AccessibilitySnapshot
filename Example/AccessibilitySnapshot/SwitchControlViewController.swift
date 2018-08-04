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

    // MARK: - Private Properties

    private let switchControls: [UISwitch] = (0..<8).map { _ in UISwitch() }

    /// UIView with the switch button trait that acts like a switch, but is not a UISwitch.
    private let fakeSwitchView: UIView = .init()

    /// UIView with the button and switch button traits that acts like a switch, but is not a UISwitch.
    private let fakeSwitchButton: UIView = .init()

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        switchControls[0].isOn = true

        switchControls[1].isOn = false

        switchControls[2].isOn = true
        switchControls[2].accessibilityLabel = "Label"

        switchControls[3].isOn = false
        switchControls[3].accessibilityLabel = "Label"

        switchControls[4].isOn = true
        switchControls[4].accessibilityLabel = "Label"
        switchControls[4].accessibilityValue = "Value"

        switchControls[5].isOn = true
        switchControls[5].accessibilityLabel = "Label"
        switchControls[5].accessibilityValue = "Value"
        switchControls[5].accessibilityHint = "Hint"

        switchControls[6].isOn = false
        switchControls[6].accessibilityLabel = "Label"
        switchControls[6].accessibilityValue = "Value"
        switchControls[6].accessibilityHint = "Hint"
        switchControls[6].accessibilityTraits.insert([
            .selected,
            .button,
            .header,
            .link,
            .adjustable,
            .image,
            .searchField,
        ])

        switchControls[7].isOn = false
        switchControls[7].accessibilityLabel = "Label"
        switchControls[7].accessibilityValue = "Value"
        switchControls[7].accessibilityHint = "Hint"
        switchControls[7].accessibilityTraits.insert([
            .selected,
            .notEnabled,
            .button,
            .header,
            .link,
            .adjustable,
            .image,
            .searchField,
        ])

        switchControls.forEach { view.addSubview($0) }

        // Add a fake switch that has the switch button trait only, but is not a UISwitch.
        fakeSwitchView.isAccessibilityElement = true
        fakeSwitchView.accessibilityLabel = "Fake Label"
        fakeSwitchView.accessibilityValue = "Value"
        fakeSwitchView.accessibilityTraits.insert(UIAccessibilityTraits(rawValue: 0x0020000000000000))
        fakeSwitchView.frame.size = .init(width: 48, height: 32)
        fakeSwitchView.backgroundColor = .lightGray
        fakeSwitchView.layer.cornerRadius = 16
        view.addSubview(fakeSwitchView)

        // Add a fake switch that has the switch button and button traits, but is not a UISwitch.
        fakeSwitchButton.isAccessibilityElement = true
        fakeSwitchButton.accessibilityLabel = "Fake Label"
        fakeSwitchButton.accessibilityValue = "Value"
        fakeSwitchButton.accessibilityTraits.insert(.button)
        fakeSwitchButton.accessibilityTraits.insert(UIAccessibilityTraits(rawValue: 0x0020000000000000))
        fakeSwitchButton.frame.size = .init(width: 48, height: 32)
        fakeSwitchButton.backgroundColor = .lightGray
        fakeSwitchButton.layer.cornerRadius = 16
        view.addSubview(fakeSwitchButton)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        switchControls.forEach { $0.sizeToFit() }

        let statusBarHeight = UIApplication.shared.statusBarFrame.height

        var distributionSpecifiers: [ViewDistributionSpecifying] = [ statusBarHeight.fixed, 1.flexible ]
        for subview in switchControls {
            distributionSpecifiers.append(subview)
            distributionSpecifiers.append(1.flexible)
        }
        distributionSpecifiers.append(contentsOf: [
            fakeSwitchView.distributionItem,
            1.flexible,
            fakeSwitchButton.distributionItem,
            1.flexible,
        ])
        view.applySubviewDistribution(distributionSpecifiers)
    }

}

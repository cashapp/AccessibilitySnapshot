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

final class SwitchControlsTests: SnapshotTestCase {

    func testOn() {
        let control = UISwitch()
        control.isOn = true

        let container = ContainerView(subview: control)
        container.frame.size = container.sizeThatFits(UIScreen.main.bounds.size)

        SnapshotVerifyAccessibility(container)
    }

    func testOff() {
        let control = UISwitch()
        control.isOn = false

        let container = ContainerView(subview: control)
        container.frame.size = container.sizeThatFits(UIScreen.main.bounds.size)

        SnapshotVerifyAccessibility(container)
    }

    func testOn_disabled() {
        let control = UISwitch()
        control.isOn = true
        control.isEnabled = false

        let container = ContainerView(subview: control)
        container.frame.size = container.sizeThatFits(UIScreen.main.bounds.size)

        SnapshotVerifyAccessibility(container)
    }

    func testOn_withLabel() {
        let control = UISwitch()
        control.isOn = true
        control.accessibilityLabel = "Label"

        let container = ContainerView(subview: control)
        container.frame.size = container.sizeThatFits(UIScreen.main.bounds.size)

        SnapshotVerifyAccessibility(container)
    }

    func testOn_withLabelAndValue() {
        let control = UISwitch()
        control.isOn = true
        control.accessibilityLabel = "Label"
        control.accessibilityValue = "Value"

        let container = ContainerView(subview: control)
        container.frame.size = container.sizeThatFits(UIScreen.main.bounds.size)

        SnapshotVerifyAccessibility(container)
    }

    func testOn_withLabelAndHint() {
        let control = UISwitch()
        control.isOn = true
        control.accessibilityLabel = "Label"
        control.accessibilityHint = "Hint"

        let container = ContainerView(subview: control)
        container.frame.size = container.sizeThatFits(UIScreen.main.bounds.size)

        SnapshotVerifyAccessibility(container)
    }

    func testOn_withLabelAndHintAndTraits() {
        let control = UISwitch()
        control.isOn = true
        control.accessibilityLabel = "Label"
        control.accessibilityHint = "Hint"
        control.accessibilityTraits.insert([
            .selected,
            .button,
            .header,
            .link,
            .adjustable,
            .image,
            .searchField,
        ])

        let container = ContainerView(subview: control)
        container.frame.size = container.sizeThatFits(UIScreen.main.bounds.size)

        SnapshotVerifyAccessibility(container)
    }

    func testFakeSwitch() {
        let fakeSwitch = UIView()
        fakeSwitch.frame.size = .init(width: 48, height: 32)
        fakeSwitch.backgroundColor = .lightGray
        fakeSwitch.layer.cornerRadius = 16

        fakeSwitch.isAccessibilityElement = true
        fakeSwitch.accessibilityLabel = "Label"
        fakeSwitch.accessibilityValue = "Value"

        var accessibilityTraits = UISwitch().accessibilityTraits
        accessibilityTraits.remove(.button)
        fakeSwitch.accessibilityTraits = accessibilityTraits

        let container = ContainerView(subview: fakeSwitch)
        container.frame.size = container.sizeThatFits(UIScreen.main.bounds.size)

        SnapshotVerifyAccessibility(container)
    }

    func testFakeSwitchButton() {
        let fakeSwitch = UIView()
        fakeSwitch.frame.size = .init(width: 48, height: 32)
        fakeSwitch.backgroundColor = .lightGray
        fakeSwitch.layer.cornerRadius = 16

        fakeSwitch.isAccessibilityElement = true
        fakeSwitch.accessibilityLabel = "Label"
        fakeSwitch.accessibilityValue = "Value"
        fakeSwitch.accessibilityTraits = UISwitch().accessibilityTraits

        let container = ContainerView(subview: fakeSwitch)
        container.frame.size = container.sizeThatFits(UIScreen.main.bounds.size)

        SnapshotVerifyAccessibility(container)
    }

}

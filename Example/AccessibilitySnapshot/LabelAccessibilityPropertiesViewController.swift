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

//  ┌──────────────────────────────────────────────────────────────────────────────┐
//  │                                                                              │
//  │                        Label Accessibility Properties                        │
//  │                                                                              │
//  ├────┬─────────┬─────────┬─────────┬─────────┬─────────────────────────────────┤
//  │ ## │  label  │  value  │  hint   │ element │      VoiceOver Description      │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────────────────────────────┤
//  │ 01 │         │         │         │  true   │ "01: Text"                      │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────────────────────────────┤
//  │ 02 │    X    │         │         │  true   │ "Label"                         │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────────────────────────────┤
//  │ 03 │         │    X    │         │  true   │ "03: Text: Value"               │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────────────────────────────┤
//  │ 04 │         │         │    X    │  true   │ "04: Text", "Hint"              │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────────────────────────────┤
//  │ 05 │    X    │    X    │         │  true   │ "Label: Value"                  │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────────────────────────────┤
//  │ 06 │    X    │         │    X    │  true   │ "Label", "Hint"                 │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────────────────────────────┤
//  │ 07 │         │    X    │    X    │  true   │ "07: Text: Value", "Hint"       │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────────────────────────────┤
//  │ 08 │    X    │    X    │    X    │  true   │ "Label: Value", "Hint"          │
//  └────┴─────────┴─────────┴─────────┴─────────┴─────────────────────────────────┘
final class LabelAccessibilityPropertiesViewController: AccessibilityViewController {

    // MARK: - Private Properties

    private let labels = (0..<8).map { _ in UILabel() }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        let numberFormatter = NumberFormatter()
        numberFormatter.minimumIntegerDigits = 2
        for (index, label) in labels.enumerated() {
            label.text = "\(numberFormatter.string(from: NSNumber(value: index + 1))!): Text"
            label.isAccessibilityElement = true
            view.addSubview(label)
        }

        // Label with text only.
        labels[0].accessibilityLabel = nil
        labels[0].accessibilityValue = nil
        labels[0].accessibilityHint = nil

        // Label with label.
        labels[1].accessibilityLabel = "Label"
        labels[1].accessibilityValue = nil
        labels[1].accessibilityHint = nil

        // Label with value.
        labels[2].accessibilityLabel = nil
        labels[2].accessibilityValue = "Value"
        labels[2].accessibilityHint = nil

        // Label with hint.
        labels[3].accessibilityLabel = nil
        labels[3].accessibilityValue = nil
        labels[3].accessibilityHint = "Hint"

        // Label with label and value.
        labels[4].accessibilityLabel = "Label"
        labels[4].accessibilityValue = "Value"
        labels[4].accessibilityHint = nil

        // Label with label and hint.
        labels[5].accessibilityLabel = "Label"
        labels[5].accessibilityValue = nil
        labels[5].accessibilityHint = "Hint"

        // Label with value and hint.
        labels[6].accessibilityLabel = nil
        labels[6].accessibilityValue = "Value"
        labels[6].accessibilityHint = "Hint"

        // Label with label, value, and hint.
        labels[7].accessibilityLabel = "Label"
        labels[7].accessibilityValue = "Value"
        labels[7].accessibilityHint = "Hint"
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        labels.forEach { $0.sizeToFit() }

        let statusBarHeight = UIApplication.shared.statusBarFrame.height

        var distributionSpecifiers: [ViewDistributionSpecifying] = [ statusBarHeight.fixed, 1.flexible ]
        for label in labels {
            distributionSpecifiers.append(label)
            distributionSpecifiers.append(1.flexible)
        }
        view.applySubviewDistribution(distributionSpecifiers)
    }

}

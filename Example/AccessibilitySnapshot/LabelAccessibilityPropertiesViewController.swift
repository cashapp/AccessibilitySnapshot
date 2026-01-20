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
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────────────────────────────┤
//  │ 09 │ Attr.X  │         │         │  true   │ Attributed label (fr-CA)        │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────────────────────────────┤
//  │ 10 │ Attr.X  │ Attr.X  │ Attr.X  │  true   │ Attr label/value/hint           │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────────────────────────────┤
//  │ 11 │ Attr.X  │         │         │  true   │ IPA notation ("Quinoa")         │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────────────────────────────┤
//  │ 12 │ Attr.X  │         │         │  true   │ Heading Level 1                 │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────────────────────────────┤
//  │ 13 │ Attr.X  │         │         │  true   │ Heading Level 2                 │
//  └────┴─────────┴─────────┴─────────┴─────────┴─────────────────────────────────┘
final class LabelAccessibilityPropertiesViewController: AccessibilityViewController {

    // MARK: - Private Properties

    private var labels: [UILabel] {
        return (view as! View).labels
    }

    // MARK: - UIViewController

    override func loadView() {
        view = View()
    }

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
        
        // Label with attributed label containing accessibility speech attributes.
        // This demonstrates how attributed strings with accessibility attributes are displayed.
        let bonjourLabel = NSMutableAttributedString(string: "Hello Bonjour")

        // Set language attribute for "Bonjour" (spoken in French)
        bonjourLabel.addAttribute(
            .accessibilitySpeechLanguage,
            value: "fr-CA",
            range: NSRange(location: 6, length: 7)
        )
        
        labels[8].accessibilityAttributedLabel = bonjourLabel
        labels[8].accessibilityValue = nil
        labels[8].accessibilityHint = nil
        
        // Label with attributed label, value, AND hint.
        // This demonstrates having attributes in all three properties.
        let bonjourLabel2 = NSMutableAttributedString(string: "Hello Bonjour")
        bonjourLabel2.addAttribute(
            .accessibilitySpeechLanguage,
            value: "fr-CA",
            range: NSRange(location: 6, length: 7)
        )
        
        let fiftyPercentValue = NSMutableAttributedString(string: "50%")
        fiftyPercentValue.addAttribute(
            .accessibilitySpeechSpellOut,
            value: true,
            range: NSRange(location: 0, length: 3)
        )
        
        let hint = NSMutableAttributedString(string: "Dies ist ein Hinweis.")
        hint.addAttribute(
            .accessibilitySpeechLanguage,
            value: "de-DE",
            range: NSRange(location: 0, length: 21)
        )
        
        labels[9].accessibilityAttributedLabel = bonjourLabel2
        labels[9].accessibilityAttributedValue = fiftyPercentValue
        labels[9].accessibilityAttributedHint = hint

        // Label with IPA notation for pronunciation
        let ipaLabel = NSMutableAttributedString(string: "Quinoa")
        ipaLabel.addAttribute(
            .accessibilitySpeechIPANotation,
            value: "ˈkiːnwɑː",
            range: NSRange(location: 0, length: 6)
        )
        labels[10].accessibilityAttributedLabel = ipaLabel
        
        // Label with heading level 1
        let titleLabel = NSMutableAttributedString(string: "Section Title")
        titleLabel.addAttribute(
            .accessibilityTextHeadingLevel,
            value: NSNumber(value: 1),
            range: NSRange(location: 0, length: 13)
        )
        labels[11].accessibilityAttributedLabel = titleLabel
        labels[11].accessibilityTraits = [.header]

        // Label with heading level 2
        let subtitleLabel = NSMutableAttributedString(string: "Section Subtitle")
        subtitleLabel.addAttribute(
            .accessibilityTextHeadingLevel,
            value: NSNumber(value: 2),
            range: NSRange(location: 0, length: 16)
        )
        labels[12].accessibilityAttributedLabel = subtitleLabel
        labels[12].accessibilityTraits = [.header]
    }

}

// MARK: -

extension LabelAccessibilityPropertiesViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Properties

        let labels = (0..<13).map { _ in UILabel() }

        // MARK: - UIView

        override func layoutSubviews() {
            labels.forEach { $0.sizeToFit() }

            let statusBarHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0

            var distributionSpecifiers: [ViewDistributionSpecifying] = [ statusBarHeight.fixed, 1.flexible ]
            for label in labels {
                distributionSpecifiers.append(label.distributionItemUsingCapInsets)
                distributionSpecifiers.append(1.flexible)
            }
            applyVerticalSubviewDistribution(distributionSpecifiers)
        }

    }

}

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

//  ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
//  │                                                                                                                           │
//  │                                                Button Accessibility Traits                                                │
//  │                                                                                                                           │
//  ├────┬───────────────────────────────────────┬──────────────────────────────────────────────────────────────────────────────┤
//  │ ## │                traits                 │                            VoiceOver Description                             │
//  ├────┼───────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 01 │(None)                                 │ "01"                                                                         │
//  ├────┼───────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 02 │Button                                 │ "02. Button."                                                                │
//  ├────┼───────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 03 │Link                                   │ "03. Link."                                                                  │
//  ├────┼───────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 04 │Header                                 │ "04. Heading."                                                               │
//  ├────┼───────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 05 │SearchField                            │ "05. Search Field."                                                          │
//  ├────┼───────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 06 │Image                                  │ "06. Image."                                                                 │
//  ├────┼───────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 07 │Selected                               │ "Selected: 07"                                                               │
//  ├────┼───────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 08 │PlaysSound                             │ "08"                                                                         │
//  ├────┼───────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 09 │KeyboardKey                            │ "09"                                                                         │
//  ├────┼───────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 10 │StaticText                             │ "10"                                                                         │
//  ├────┼───────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 11 │SummaryElement                         │ "11"                                                                         │
//  ├────┼───────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 12 │NotEnabled                             │ "12. Dimmed."                                                                │
//  ├────┼───────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 13 │UpdatesFrequently                      │ "13"                                                                         │
//  ├────┼───────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 14 │StartsMediaSession                     │ "14"                                                                         │
//  ├────┼───────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 15 │Adjustable                             │ "15. Adjustable.", "Swipe up or down with one finger to adjust the value."   │
//  ├────┼───────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 16 │AllowsDirectInteraction                │ "16"                                                                         │
//  ├────┼───────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 17 │CausesPageTurn                         │ "17"                                                                         │
//  ├────┼───────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 18 │TabBar                                 │ "18"                                                                         │
//  ├────┼───────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 19 │Button, Link                           │ "19. Button. Link."                                                          │
//  ├────┼───────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 20 │Button, Header                         │ "20. Button. Heading."                                                       │
//  ├────┼───────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 21 │Button, SearchField                    │ "21. Button. Search Field."                                                  │
//  ├────┼───────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 22 │Button, Image                          │ "22. Button. Image."                                                         │
//  ├────┼───────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 23 │Button, Selected                       │ "Selected: 23. Button."                                                      │
//  ├────┼───────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 24 │Button, NotEnabled                     │ "24. Dimmed. Button."                                                        │
//  ├────┼───────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 25 │Button, Adjustable                     │ "25. Button. Adjustable.", "Swipe up or down with one finger to adjust the   │
//  ├────┼───────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 26 │Button, KeyboardKey                    │ "26"                                                                         │
//  ├────┼───────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 27 │(all traits)                           │ "Selected: 26. Dimmed. Heading. Link. Adjustable. Image. Search Field."      │
//  └────┴───────────────────────────────────────┴──────────────────────────────────────────────────────────────────────────────┘
final class ButtonAccessibilityTraitsViewController: AccessibilityViewController {

    // MARK: - Private Properties

    private let buttons = (0..<27).map { _ in UIButton() }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        let numberFormatter = NumberFormatter()
        numberFormatter.minimumIntegerDigits = 2
        for (index, button) in buttons.enumerated() {
            button.setTitle(numberFormatter.string(from: NSNumber(value: (index + 1))), for: .normal)
            button.setTitleColor(.black, for: .normal)
            button.isAccessibilityElement = true
            view.addSubview(button)
        }

        view.accessibilityElements = buttons

        let accessibilityTraits: [UIAccessibilityTraits] = [
            .button,
            .link,
            .header,
            .searchField,
            .image,
            .selected,
            .playsSound,
            .keyboardKey,
            .staticText,
            .summaryElement,
            .notEnabled,
            .updatesFrequently,
            .startsMediaSession,
            .adjustable,
            .allowsDirectInteraction,
            .causesPageTurn,
            .tabBar,
        ]

        // Button with no traits.
        buttons[0].accessibilityTraits = .none

        // Single traits.
        for (index, trait) in accessibilityTraits.enumerated() {
            buttons[index+1].accessibilityTraits = trait
        }

        // Button with button and link traits.
        buttons[18].accessibilityTraits = [.button, .link]

        // Button with button and header traits.
        buttons[19].accessibilityTraits = [.button, .header]

        // Button with button and search field traits.
        buttons[20].accessibilityTraits = [.button, .searchField]

        // Button with button and image traits.
        buttons[21].accessibilityTraits = [.button, .image]

        // Button with button and selected traits.
        buttons[22].accessibilityTraits = [.button, .selected]

        // Button with button and not enabled traits.
        buttons[23].accessibilityTraits = [.button, .notEnabled]

        // Button with button and adjustable traits.
        buttons[24].accessibilityTraits = [.button, .adjustable]

        // Button with button and keyboard key traits.
        buttons[25].accessibilityTraits = [.button, .keyboardKey]

        // Button with all accessibility traits.
        buttons[26].accessibilityTraits = accessibilityTraits.reduce(.none, { $0.union($1) })
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        buttons.forEach { $0.sizeToFit() }

        let statusBarHeight = UIApplication.shared.statusBarFrame.height

        let additionalButtonSpacers = (buttons.count % 3 == 0) ? 0 : (3 - (buttons.count % 3))
        let buttonsPerColumn = (buttons.count + additionalButtonSpacers) / 3

        let outerMargin = view.bounds.width / 5

        var leftColSubviewDistribution: [ViewDistributionSpecifying] = [ statusBarHeight.fixed, 1.flexible ]
        for button in buttons[0..<buttonsPerColumn] {
            leftColSubviewDistribution.append(button)
            leftColSubviewDistribution.append(1.flexible)
        }
        view.applySubviewDistribution(leftColSubviewDistribution, alignment: .leading(inset: outerMargin))

        var centerColSubviewDistribution: [ViewDistributionSpecifying] = [ statusBarHeight.fixed, 1.flexible ]
        for button in buttons[buttonsPerColumn..<(2 * buttonsPerColumn)] {
            centerColSubviewDistribution.append(button)
            centerColSubviewDistribution.append(1.flexible)
        }
        view.applySubviewDistribution(centerColSubviewDistribution)

        var rightColSubviewDistribution: [ViewDistributionSpecifying] = [ statusBarHeight.fixed, 1.flexible ]
        for button in buttons[(2 * buttonsPerColumn)..<buttons.count] {
            rightColSubviewDistribution.append(button)
            rightColSubviewDistribution.append(1.flexible)
        }
        for _ in 0..<additionalButtonSpacers {
            rightColSubviewDistribution.append(buttons[0].frame.height.fixed)
            rightColSubviewDistribution.append(1.flexible)
        }
        view.applySubviewDistribution(rightColSubviewDistribution, alignment: .trailing(inset: outerMargin))
    }

}

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
//  │                                                  Description Edge Cases                                                   │
//  │                                                                                                                           │
//  ├────┬─────────┬─────────┬───────────────────┬──────────────────────────────────────────────────────────────────────────────┤
//  │ ## │  label  │  hint   │      traits       │                            VoiceOver Description                             │
//  ├────┼─────────┼─────────┼───────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 01 │         │    X    │ Adjustable        │ "Hint. Adjustable."                                                          │
//  ├────┼─────────┼─────────┼───────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 02 │    X    │    X    │ Adjustable        │ "Label. Adjustable.", "Hint. Swipe up or down with one finger to adjust the  │
//  ├────┼─────────┼─────────┼───────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 03 │         │         │ Button, Header    │ "Button. Heading."                                                           │
//  ├────┼─────────┼─────────┼───────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 04 │         │         │ Adjustable        │ "Adjustable", "Swipe up or down with one finger to adjust the value."        │
//  ├────┼─────────┼─────────┼───────────────────┼──────────────────────────────────────────────────────────────────────────────┤
//  │ 05 │         │    X    │ Button            │ "Hint. Button."                                                              │
//  └────┴─────────┴─────────┴───────────────────┴──────────────────────────────────────────────────────────────────────────────┘
final class DescriptionEdgeCasesViewController: AccessibilityViewController {

    // MARK: - Private Properties

    private var views: [UIView] {
        return (view as! View).views
    }

    // MARK: - UIViewController

    override func loadView() {
        view = View()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        for subview in views {
            subview.backgroundColor = .lightGray
            subview.isAccessibilityElement = true
        }

        // View with hint only and adjustable trait.
        views[0].accessibilityHint = "Hint"
        views[0].accessibilityTraits = .adjustable

        // View with label, hint, and adjustable trait.
        views[1].accessibilityLabel = "Label"
        views[1].accessibilityHint = "Hint"
        views[1].accessibilityTraits = .adjustable

        // View with traits only.
        views[2].accessibilityTraits = [.button, .header]

        // View with adjustable trait only.
        views[3].accessibilityTraits = .adjustable

        // View with hint and traits only.
        views[4].accessibilityHint = "Hint"
        views[4].accessibilityTraits = .button
    }

}

// MARK: -

extension DescriptionEdgeCasesViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            views.forEach(addSubview(_:))
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Properties

        let views = (0..<5).map { _ in UIView() }

        // MARK: - UIView

        override func layoutSubviews() {
            for subview in views {
                subview.bounds.size = CGSize(width: 30, height: 30)
                subview.layer.cornerRadius = 15
            }

            let statusBarHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0

            var distributionSpecifiers: [ViewDistributionSpecifying] = [ statusBarHeight.fixed, 1.flexible ]
            for subview in views {
                distributionSpecifiers.append(subview)
                distributionSpecifiers.append(1.flexible)
            }
            applyVerticalSubviewDistribution(distributionSpecifiers)
        }

    }

}

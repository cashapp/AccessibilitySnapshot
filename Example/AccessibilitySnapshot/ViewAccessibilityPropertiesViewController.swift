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

//  ┌─────────────────────────────────────────────────────────────────────────────────────────┐
//  │                                                                                         │
//  │                              View Accessibility Properties                              │
//  │                                                                                         │
//  ├────┬─────────┬─────────┬─────────┬─────────┬─────────┬──────────────────────────────────┤
//  │ ## │  label  │  value  │  hint   │ element │ actions │       VoiceOver Description      │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────┼──────────────────────────────────┤
//  │ 01 │         │         │         │  true   │  false  │  ""                              │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────┼──────────────────────────────────┤
//  │ 02 │    X    │         │         │  true   │  false  │  "Label"                         │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────┼──────────────────────────────────┤
//  │ 03 │         │    X    │         │  true   │  false  │  "Value"                         │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────┼──────────────────────────────────┤
//  │ 04 │         │         │    X    │  true   │  false  │  "Hint"                          │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────┼──────────────────────────────────┤
//  │ 05 │    X    │    X    │         │  true   │  false  │  "Label: Value"                  │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────┼──────────────────────────────────┤
//  │ 06 │    X    │         │    X    │  true   │  false  │  "Label", "Hint"                 │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────┼──────────────────────────────────┤
//  │ 07 │         │    X    │    X    │  true   │  false  │  "Value", "Hint"                 │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────┼──────────────────────────────────┤
//  │ 08 │    X    │    X    │    X    │  true   │  false  │  "Label: Value", "Hint"          │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────┼──────────────────────────────────┤
//  │ 09 │    X    │    X    │    X    │  true   │  true   │  "Label: Value", "Hint",         │
//  |    |         |         |         |         |         |  "Actions Available"             │
//  └────┴─────────┴─────────┴─────────┴─────────┴─────────┴──────────────────────────────────┘
final class ViewAccessibilityPropertiesViewController: AccessibilityViewController {

    // MARK: - Private Properties

    private let views = (0..<9).map { _ in UIView() }

    // MARK: - UIViewController

    override func loadView() {
        view = View()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        for subview in views {
            subview.backgroundColor = .lightGray
            subview.isAccessibilityElement = true
            view.addSubview(subview)
        }

        // View with no accessibility description.
        views[0].accessibilityLabel = nil
        views[0].accessibilityValue = nil
        views[0].accessibilityHint = nil

        // View with label.
        views[1].accessibilityLabel = "Label"
        views[1].accessibilityValue = nil
        views[1].accessibilityHint = nil

        // View with value.
        views[2].accessibilityLabel = nil
        views[2].accessibilityValue = "Value"
        views[2].accessibilityHint = nil

        // View with hint.
        views[3].accessibilityLabel = nil
        views[3].accessibilityValue = nil
        views[3].accessibilityHint = "Hint"

        // View with label and value.
        views[4].accessibilityLabel = "Label"
        views[4].accessibilityValue = "Value"
        views[4].accessibilityHint = nil

        // View with label and hint.
        views[5].accessibilityLabel = "Label"
        views[5].accessibilityValue = nil
        views[5].accessibilityHint = "Hint"

        // View with value and hint.
        views[6].accessibilityLabel = nil
        views[6].accessibilityValue = "Value"
        views[6].accessibilityHint = "Hint"

        // View with label, value, and hint.
        views[7].accessibilityLabel = "Label"
        views[7].accessibilityValue = "Value"
        views[7].accessibilityHint = "Hint"

        // View with label, value, hint, and custom actions.
        views[8].accessibilityLabel = "Label"
        views[8].accessibilityValue = "Value"
        views[8].accessibilityHint = "Hint"
        if #available(iOS 14.0, *) {
            views[8].accessibilityCustomActions = [
                UIAccessibilityCustomAction(name: "Action without image", image: nil) { _ in return false },
                UIAccessibilityCustomAction(name: "Action with checkmark.circle image", image: UIImage(systemName: "checkmark.circle")) { _ in return false },
                UIAccessibilityCustomAction(name: "Action with checkmark.circle.fill image", image: UIImage(systemName: "checkmark.circle.fill")) { _ in return false },
                UIAccessibilityCustomAction(name: "This is a really long action without an image. The name is quite long to ensure that it will span multiple lines.", image: nil) { _ in return false },
                UIAccessibilityCustomAction(name: "こんにちは", image: nil) { _ in return false },
                UIAccessibilityCustomAction(name: "నమస్కారం", image: nil) { _ in return false },
                UIAccessibilityCustomAction(name: "مرحبًا", image: nil) { _ in return false },
            ]
        }
    }

}

extension ViewAccessibilityPropertiesViewController {

    final class View: UIView {

        // MARK: - UIView

        override func layoutSubviews() {
            for subview in subviews {
                subview.bounds.size = CGSize(width: 30, height: 30)
                subview.layer.cornerRadius = 15
            }

            let statusBarHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0

            var distributionSpecifiers: [ViewDistributionSpecifying] = [ statusBarHeight.fixed, 1.flexible ]
            for subview in subviews {
                distributionSpecifiers.append(subview)
                distributionSpecifiers.append(1.flexible)
            }
            applyVerticalSubviewDistribution(distributionSpecifiers)
        }

    }

}

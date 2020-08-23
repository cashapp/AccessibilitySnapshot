//
//  Copyright 2020 Square Inc.
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

final class AccessibilityCustomActionsViewController: AccessibilityViewController {

    // MARK: - Life Cycle

    init() {
        self.views = [
            .init(includeLabel: true, includeHint: true),
            .init(includeLabel: true, includeHint: false),
            .init(includeLabel: false, includeHint: true),
            .init(includeLabel: false, includeHint: false),
        ]

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Properties

    private let views: [CustomActionView]

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        views.forEach(view.addSubview)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        views.forEach { $0.frame.size = .init(width: view.bounds.width / 2, height: 50) }

        let statusBarHeight = UIApplication.shared.statusBarFrame.height

        var distributionSpecifiers: [ViewDistributionSpecifying] = [ statusBarHeight.fixed, 1.flexible ]
        for subview in views {
            distributionSpecifiers.append(subview)
            distributionSpecifiers.append(1.flexible)
        }
        view.applySubviewDistribution(distributionSpecifiers)
    }

}

// MARK: -

private extension AccessibilityCustomActionsViewController {

    final class CustomActionView: UIView {

        // MARK: - Life Cycle

        init(includeLabel: Bool, includeHint: Bool) {
            super.init(frame: .zero)

            backgroundColor = .gray

            isAccessibilityElement = true

            accessibilityLabel = includeLabel ? "Label" : nil
            accessibilityHint = includeHint ? "Hint" : nil
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - UIAccessibility

        override var accessibilityCustomActions: [UIAccessibilityCustomAction]? {
            get {
                return [
                    UIAccessibilityCustomAction(
                        name: "First Action",
                        target: self,
                        selector: #selector(handleAction(_:))
                    ),
                    UIAccessibilityCustomAction(
                        name: """
                            Second Action with a Name that's Super Long and Will Definitely Cause Labels to Wrap when \
                            It's Written Out
                            """,
                        target: self,
                        selector: #selector(handleAction(_:))
                    ),
                    UIAccessibilityCustomAction(
                        name: "Third Action",
                        target: self,
                        selector: #selector(handleAction(_:))
                    ),
                ]
            }
            set {
                super.accessibilityCustomActions = newValue
            }
        }

        // MARK: - Private Methods

        @objc private func handleAction(_ action: UIAccessibilityCustomAction) -> Bool {
            return true
        }

    }

}

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

final class DynamicTypeViewController: AccessibilityViewController {

    // MARK: - Private Properties

    private let staticLabel: UILabel = .init()

    private let autoAdjustingLabel: UILabel = .init()

    private let staticCustomFontLabel: UILabel = .init()

    private let autoAdjustingCustomFontLabel: DynamicLabel = .init(autoAdjusting: true)

    private let manuallyAdjustingCustomFontLabel: DynamicLabel = .init(autoAdjusting: false)

    private var views: [UIView] {
        return [
            staticLabel,
            autoAdjustingLabel,
            staticCustomFontLabel,
            autoAdjustingCustomFontLabel,
            manuallyAdjustingCustomFontLabel,
        ]
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        staticLabel.text = "I Shouldn't Change"
        staticLabel.font = UIFont.preferredFont(forTextStyle: .body)

        autoAdjustingLabel.text = "Dynamic Type"
        autoAdjustingLabel.font = UIFont.preferredFont(forTextStyle: .body)
        autoAdjustingLabel.adjustsFontForContentSizeCategory = true

        staticCustomFontLabel.text = "I Shouldn't Change"
        staticCustomFontLabel.font = UIFont(name: "Optima", size: 17)!

        views.forEach(view.addSubview)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        views.forEach { $0.frame.size = $0.sizeThatFits(view.bounds.size) }

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

private extension DynamicTypeViewController {

    final class DynamicLabel: UIView {

        // MARK: - Life Cycle

        init(autoAdjusting: Bool) {
            super.init(frame: .zero)

            if autoAdjusting {
                // There's a bug that causes this not to get automatically scaled after it has been sized to the default
                // size (Large) on some devices. See rdar://36243585 for more details.
                label.adjustsFontForContentSizeCategory = true

            } else {
                notificationObserver = NotificationCenter.default.addObserver(
                    forName: UIContentSizeCategory.didChangeNotification,
                    object: nil,
                    queue: nil,
                    using: { [unowned self] _ in
                        self.updateFont()
                    }
                )

                label.adjustsFontForContentSizeCategory = false
            }

            updateFont()

            label.text = "Dynamic Type"
            addSubview(label)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        deinit {
            if let notificationObserver = notificationObserver {
                NotificationCenter.default.removeObserver(notificationObserver)
            }
        }

        // MARK: - Private Properties

        private let label: UILabel = .init()

        private let regularFont = UIFont(name: "Optima", size: 17)!

        private var notificationObserver: Any?

        // MARK: - UIView

        override func layoutSubviews() {
            label.frame = bounds
        }

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            return label.sizeThatFits(size)
        }

        // MARK: - Private Methods

        private func updateFont() {
            if #available(iOS 11, *) {
                label.font = UIFontMetrics.default.scaledFont(
                    for: self.regularFont,
                    compatibleWith: self.traitCollection
                )

            } else {
                let fontSize = UIFont.preferredFont(forTextStyle: .body).pointSize
                label.font = regularFont.withSize(fontSize)
            }
        }

    }

}

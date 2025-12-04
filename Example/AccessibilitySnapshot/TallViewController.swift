//
//  Copyright 2025 Square Inc.
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

final class TallViewController: AccessibilityViewController {

    // MARK: - UIViewController

    override func loadView() {
        view = View()
    }

}

// MARK: -

private extension TallViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            backgroundColor = .white

            // Configure top label
            topLabel.text = "Top"
            topLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
            topLabel.textAlignment = .center
            topLabel.textColor = .black

            // Configure bottom label
            bottomLabel.text = "Bottom"
            bottomLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
            bottomLabel.textAlignment = .center
            bottomLabel.textColor = .black

            // Add all subviews
            addSubview(topLabel)
            addSubview(bottomLabel)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - UIView

        override func layoutSubviews() {
            super.layoutSubviews()

            // Size labels to fit their content
            topLabel.sizeToFit()
            bottomLabel.sizeToFit()

            let statusBarHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0

            // Create vertical distribution: status bar space, top label, 6250px spacer, bottom label, flexible bottom space
            let distributionSpecifiers: [ViewDistributionSpecifying] = [
                statusBarHeight.fixed,     // Account for status bar
                topLabel,                  // Top label
                7000.fixed,                // 6250 pixel spacer view
                bottomLabel,               // Bottom label
            ]

            applyVerticalSubviewDistribution(distributionSpecifiers)
        }

        // MARK: - Private Properties

        private let topLabel: UILabel = .init()
        private let bottomLabel: UILabel = .init()

    }

}


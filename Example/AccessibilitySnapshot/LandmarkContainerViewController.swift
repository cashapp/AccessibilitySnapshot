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

@available(iOS 11, *)
final class LandmarkContainerViewController: AccessibilityViewController {

    // MARK: - UIViewController

    override func loadView() {
        self.view = View()
    }

}

// MARK: -

@available(iOS 11, *)
private extension LandmarkContainerViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            views = (1..<5).map {
                let label = UILabel()
                label.text = "Label \($0)"
                return label
            }

            super.init(frame: frame)

            views.forEach(addSubview)

            accessibilityElements = views
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let views: [UIView]

        // MARK: - UIView

        override func layoutSubviews() {
            views.forEach { $0.sizeToFit() }

            let statusBarHeight = UIApplication.shared.statusBarFrame.height

            var distributionSpecifiers: [ViewDistributionSpecifying] = [ statusBarHeight.fixed, 1.flexible ]
            for subview in views {
                distributionSpecifiers.append(subview)
                distributionSpecifiers.append(1.flexible)
            }
            applySubviewDistribution(distributionSpecifiers)
        }

        // MARK: - UIAccessibility

        override var accessibilityContainerType: UIAccessibilityContainerType {
            get {
                return .landmark
            }
            set {
                // No-op.
            }
        }

    }

}

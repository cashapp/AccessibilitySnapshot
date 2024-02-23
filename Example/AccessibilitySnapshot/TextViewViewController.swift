//
//  Copyright 2024 Block Inc.
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

final class TextViewViewController: AccessibilityViewController {

    // MARK: - UIViewController

    override func loadView() {
        self.view = View()
    }
}

// MARK: -

private extension TextViewViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            textViewWithText.text = "Hello from Text View"

            textInputViews.forEach {
                $0.layer.borderWidth = 1.0
                $0.layer.borderColor = UIColor.lightGray.cgColor
                addSubview($0)
            }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let textViewEmpty: UITextView = .init()

        private let textViewFirstResponder: UITextView = .init()

        private let textViewWithText: UITextView = .init()

        private var textInputViews: [UIView] {
            return [
                textViewEmpty,
                textViewFirstResponder,
                textViewWithText,
            ]
        }

        // MARK: - UIView

        override func layoutSubviews() {
            textInputViews.forEach { $0.frame.size = CGSize(width: 250, height: 30) }

            let statusBarHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0

            var distributionSpecifiers: [ViewDistributionSpecifying] = [ statusBarHeight.fixed, 1.flexible ]
            for subview in textInputViews {
                distributionSpecifiers.append(subview)
                distributionSpecifiers.append(1.flexible)
            }
            applyVerticalSubviewDistribution(distributionSpecifiers)

            textViewFirstResponder.becomeFirstResponder()
        }

    }

}

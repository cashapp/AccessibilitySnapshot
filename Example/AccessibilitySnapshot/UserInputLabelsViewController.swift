//
//  Copyright 2023 Block Inc.
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

final class UserInputLabelsViewController: AccessibilityViewController {

    override func loadView() {
        view = View()
    }

}

// MARK: -

private extension UserInputLabelsViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            noLabelsButton.setTitle("No labels", for: .normal)
            oneLabelButton.setTitle("One label", for: .normal)
            manyLabelsButton.setTitle("Many labels", for: .normal)
            longLabelButton.setTitle("Long label", for: .normal)
            
            nonInteractiveLabel.text = "Non-interactive"
            nonInteractiveLabel.accessibilityUserInputLabels = ["Non-interactive label"]
            
            oneLabelButton.accessibilityUserInputLabels = ["One Input Label"]
            
            longLabelButton.accessibilityUserInputLabels = [
                "A Really Really Really Really Really Long Label"
            ]
            
            let formatter = NumberFormatter()
            formatter.numberStyle = .spellOut
            
            manyLabelsButton.accessibilityUserInputLabels = [Int](1...20).map { formatter.string(for: $0)!.capitalized }
            
            buttons.forEach {
                $0.setTitleColor(.black, for: .normal)
                addSubview($0)
            }
            
            addSubview(nonInteractiveLabel)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let noLabelsButton: UIButton = .init()
        private let oneLabelButton: UIButton = .init()
        private let manyLabelsButton: UIButton = .init()
        private let longLabelButton: UIButton = .init()
        private let nonInteractiveLabel: UILabel = .init()

        private var buttons: [UIButton] {
            return [
                noLabelsButton,
                oneLabelButton,
                manyLabelsButton,
                longLabelButton
            ]
        }

        // MARK: - UIView

        override func layoutSubviews() {
            buttons.forEach {
                $0.sizeToFit(bounds.size)
            }
            
            nonInteractiveLabel.sizeToFit(bounds.size)

            let statusBarHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0

            applyVerticalSubviewDistribution(
                [
                    statusBarHeight.fixed,
                    1.flexible,
                    noLabelsButton,
                    1.flexible,
                    oneLabelButton,
                    1.flexible,
                    manyLabelsButton,
                    1.flexible,
                    longLabelButton,
                    1.flexible,
                    nonInteractiveLabel,
                    1.flexible,
                ]
            )
        }

    }

}

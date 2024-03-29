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

final class ActivationPointViewController: AccessibilityViewController {

    override func loadView() {
        view = View()
    }

}

// MARK: -

private extension ActivationPointViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            button.setTitle("Do Something", for: .normal)
            button.setTitleColor(.black, for: .normal)
            addSubview(button)

            addSubview(customActivationPointView)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        // A button for demonstrating what a standard activation point looks like.
        private let button: UIButton = .init()

        private let customActivationPointView: CustomActivationPointView = .init()

        private var views: [UIView] {
            return [
                button,
                customActivationPointView,
            ]
        }

        // MARK: - UIView

        override func layoutSubviews() {
            button.sizeToFit(bounds.size)
            customActivationPointView.sizeToFit(bounds.size)

            let statusBarHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0

            applyVerticalSubviewDistribution(
                [
                    statusBarHeight.fixed,
                    1.flexible,
                    button,
                    1.flexible,
                    customActivationPointView,
                    1.flexible,
                ]
            )
        }

    }

}

// MARK: -

private extension ActivationPointViewController {

    final class CustomActivationPointView: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            label.text = "Some Setting"
            addSubview(label)

            addSubview(switchButton)

            isAccessibilityElement = true
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let label: UILabel = .init()

        private let switchButton: UISwitch = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            label.sizeToFit()
            switchButton.sizeToFit()

            label.align(withSuperview: .leftCenter, inset: 32)
            switchButton.align(withSuperview: .rightCenter, inset: 32)

            label.isAccessibilityElement = false
        }

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            let labelHeight = label.sizeThatFits(.zero).height
            let switchHeight = switchButton.sizeThatFits(.zero).height

            return CGSize(width: size.width, height: max(labelHeight, switchHeight))
        }

        // MARK: - UIAccessibility

        override var accessibilityTraits: UIAccessibilityTraits {
            get {
                return super.accessibilityTraits.union(switchButton.accessibilityTraits)
            }
            set {
                super.accessibilityTraits = newValue
            }
        }

        override var accessibilityActivationPoint: CGPoint {
            get {
                // Set the activation point to the center of switch so tapping the parent element toggles the switch.
                return Position.center.point(
                    in: UIAccessibility.convertToScreenCoordinates(switchButton.frame, in: self),
                    layoutDirection: effectiveUserInterfaceLayoutDirection
                )
            }
            set {
                // No-op.
            }
        }

    }

}

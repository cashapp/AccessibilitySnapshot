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

final class ButtonShapesViewController: AccessibilityViewController {

    override func loadView() {
        view = View()
    }

}

// MARK: -

private extension ButtonShapesViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            standardButton.setTitle("Standard Button", for: .normal)
            standardButton.setTitleColor(.black, for: .normal)
            addSubview(standardButton)

            addSubview(customButton)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let standardButton: UIButton = .init()

        private let customButton: CustomButton = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            standardButton.sizeToFit()
            customButton.sizeToFit()

            applySubviewDistribution(
                [
                    UIApplication.shared.statusBarFrame.height.fixed,
                    2.flexible,
                    standardButton,
                    1.flexible,
                    customButton,
                    2.flexible,
                ]
            )
        }

    }

    final class CustomButton: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            label.text = "Custom Button"
            label.textColor = .black
            addSubview(label)

            if #available(iOS 14, *) {
                observerToken = NotificationCenter.default.addObserver(
                    forName: UIAccessibility.buttonShapesEnabledStatusDidChangeNotification,
                    object: nil,
                    queue: .main
                ) { [unowned self] _ in
                    self.updateButtonShape()
                }
            }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        deinit {
            if let observerToken = observerToken {
                NotificationCenter.default.removeObserver(observerToken)
            }
        }

        // MARK: - Private Properties

        private let label: UILabel = .init()

        private var observerToken: NSObjectProtocol?

        // MARK: - UIView

        override func layoutSubviews() {
            label.sizeToFit()
            label.center = .init(x: bounds.midX, y: bounds.midY)

            updateButtonShape()
        }

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            return CGRect(origin: .zero, size: label.sizeThatFits(size)).insetBy(dx: -8, dy: -8).size
        }

        // MARK: - Private Methods

        private func updateButtonShape() {
            if #available(iOS 14, *) {
                layer.borderWidth = UIAccessibility.buttonShapesEnabled ? 1 : 0
                layer.borderColor = UIColor.black.cgColor
                layer.cornerRadius = 8
            }
        }

    }

}

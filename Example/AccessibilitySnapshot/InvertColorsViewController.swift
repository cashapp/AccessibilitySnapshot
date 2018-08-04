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
final class InvertColorsViewController: AccessibilityViewController {

    // MARK: - Private Properties

    private let nestedSubviews: [UIView] = (0..<5).map { _ in UIView() }

    private let statusLabel: UILabel = .init()

    private var notificationObserver: AnyObject?

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        let nestedViews: [UIView] = [view] + nestedSubviews
        for (view, subview) in zip(nestedViews.dropLast(), nestedViews.dropFirst()) {
            view.addSubview(subview)
        }

        nestedSubviews[0].backgroundColor = .red

        nestedSubviews[1].backgroundColor = .blue

        nestedSubviews[2].backgroundColor = .green
        nestedSubviews[2].accessibilityIgnoresInvertColors = true

        nestedSubviews[3].backgroundColor = .yellow

        nestedSubviews[4].backgroundColor = .purple
        nestedSubviews[4].accessibilityIgnoresInvertColors = true

        statusLabel.textColor = .white
        nestedSubviews[2].addSubview(statusLabel)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        notificationObserver = NotificationCenter.default.addObserver(
            forName: UIAccessibility.invertColorsStatusDidChangeNotification,
            object: nil,
            queue: nil,
            using: { notification in
                self.updateStatusLabel()
            }
        )

        updateStatusLabel()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let notificationObserver = notificationObserver {
            NotificationCenter.default.removeObserver(notificationObserver)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        for view in nestedSubviews {
            view.frame = view.superview!.bounds.inset(left: 30, top: 60, right: 30, bottom: 60)
        }

        statusLabel.sizeToFit()
        statusLabel.alignToSuperview(.topCenter, inset: 20)
    }

    // MARK: - Private Methods

    private func updateStatusLabel() {
        statusLabel.text = UIAccessibility.isInvertColorsEnabled ? "Enabled" : "Disabled"
        view.setNeedsLayout()
    }

}

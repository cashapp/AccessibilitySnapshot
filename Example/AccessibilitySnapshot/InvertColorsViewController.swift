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

final class InvertColorsViewController: AccessibilityViewController {

    // MARK: - Private Properties

    private var notificationObserver: AnyObject?

    private var rootView: View {
        return view as! View
    }

    // MARK: - UIViewController

    override func loadView() {
        view = View()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // This additional call to updateStatusLabel() is needed because
        // of a view life cycle issue with the snapshot test framework
        updateStatusLabel()
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

    // MARK: - Private Methods

    private func updateStatusLabel() {
        rootView.statusLabel.text = UIAccessibility.isInvertColorsEnabled ? "Enabled" : "Disabled"
        rootView.setNeedsLayout()
    }

}

// MARK: -

private extension InvertColorsViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            let nestedViews: [UIView] = [self] + nestedSubviews
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

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let nestedSubviews: [UIView] = (0..<5).map { _ in UIView() }

        let statusLabel: UILabel = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            let nestedViews: [UIView] = [self] + nestedSubviews
            for (containingView, subview) in zip(nestedViews.dropLast(), nestedViews.dropFirst()) {
                subview.frame = containingView.bounds.insetBy(left: 30, top: 60, right: 30, bottom: 60)
            }

            statusLabel.sizeToFit()
            statusLabel.capInsetsAlignmentProxy.align(withSuperview: .topCenter, inset: 20)
        }

    }

}

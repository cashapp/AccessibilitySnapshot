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

final class UserIntefaceDirectionViewController: AccessibilityViewController {

    // MARK: - UIViewController

    override func loadView() {
        view = View()
    }

}

// MARK: -

private extension UserIntefaceDirectionViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            unspecifiedView.semanticContentAttribute = .unspecified
            addSubview(unspecifiedView)

            playbackView.semanticContentAttribute = .playback
            addSubview(playbackView)

            spatialView.semanticContentAttribute = .spatial
            addSubview(spatialView)

            forceLeftToRightView.semanticContentAttribute = .forceLeftToRight
            addSubview(forceLeftToRightView)

            forceRightToLeftView.semanticContentAttribute = .forceRightToLeft
            addSubview(forceRightToLeftView)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let unspecifiedView: ContainerView = .init()

        private let playbackView: ContainerView = .init()

        private let spatialView: ContainerView = .init()

        private let forceLeftToRightView: ContainerView = .init()

        private let forceRightToLeftView: ContainerView = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            let statusBarHeight = UIApplication.shared.statusBarFrame.height

            var distributionSpecifiers: [ViewDistributionSpecifying] = [ statusBarHeight.fixed, 1.flexible ]
            for subview in [unspecifiedView, playbackView, spatialView, forceLeftToRightView, forceRightToLeftView] {
                subview.frame.size = .init(width: 200, height: 32)
                distributionSpecifiers.append(subview)
                distributionSpecifiers.append(1.flexible)
            }
            applySubviewDistribution(distributionSpecifiers)
        }

    }

}

// MARK: -

private extension UserIntefaceDirectionViewController {

    final class ContainerView: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            let leftSubview = UIView()
            leftSubview.frame.size = .init(width: 32, height: 32)
            leftSubview.layer.cornerRadius = 16
            leftSubview.backgroundColor = .lightGray
            leftSubview.isAccessibilityElement = true
            leftSubview.accessibilityLabel = "Left Element"
            addSubview(leftSubview)

            let rightSubview = UIView()
            rightSubview.frame.size = .init(width: 32, height: 32)
            rightSubview.layer.cornerRadius = 16
            rightSubview.backgroundColor = .lightGray
            rightSubview.isAccessibilityElement = true
            rightSubview.accessibilityLabel = "Right Element"
            addSubview(rightSubview)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - UIView

        override func layoutSubviews() {
            applySubviewDistribution(subviews, axis: .horizontal)
        }

    }

}

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

final class SemanticContainerViewController: AccessibilityViewController {

    // MARK: - UIViewController

    override func loadView() {
        self.view = View()
    }

}

// MARK: -

private extension SemanticContainerViewController {

    final class MediaControlsContainer: UIView {

        // MARK: - Life Cycle

        init(title: String) {
            self.titleLabel = UILabel()
            self.previousButton = UIButton(type: .system)
            self.playPauseButton = UIButton(type: .system)
            self.nextButton = UIButton(type: .system)

            super.init(frame: .zero)

            titleLabel.text = title
            titleLabel.font = .preferredFont(forTextStyle: .headline)

            let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .medium)

            previousButton.setImage(UIImage(systemName: "backward.fill", withConfiguration: config), for: .normal)
            previousButton.accessibilityLabel = "Previous"

            playPauseButton.setImage(UIImage(systemName: "play.fill", withConfiguration: config), for: .normal)
            playPauseButton.accessibilityLabel = "Play"

            nextButton.setImage(UIImage(systemName: "forward.fill", withConfiguration: config), for: .normal)
            nextButton.accessibilityLabel = "Next"

            addSubview(titleLabel)
            addSubview(previousButton)
            addSubview(playPauseButton)
            addSubview(nextButton)

            accessibilityLabel = title
            accessibilityElements = [previousButton, playPauseButton, nextButton]
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let titleLabel: UILabel
        private let previousButton: UIButton
        private let playPauseButton: UIButton
        private let nextButton: UIButton

        // MARK: - UIView

        override func layoutSubviews() {
            super.layoutSubviews()

            titleLabel.sizeToFit()
            previousButton.sizeToFit()
            playPauseButton.sizeToFit()
            nextButton.sizeToFit()

            titleLabel.frame.origin = CGPoint(x: (bounds.width - titleLabel.bounds.width) / 2, y: 8)

            let buttonY = titleLabel.frame.maxY + 16
            let totalButtonWidth = previousButton.bounds.width + playPauseButton.bounds.width + nextButton.bounds.width + 40
            let startX = (bounds.width - totalButtonWidth) / 2

            previousButton.frame.origin = CGPoint(x: startX, y: buttonY)
            playPauseButton.frame.origin = CGPoint(x: previousButton.frame.maxX + 20, y: buttonY)
            nextButton.frame.origin = CGPoint(x: playPauseButton.frame.maxX + 20, y: buttonY)
        }

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            titleLabel.sizeToFit()
            playPauseButton.sizeToFit()
            let height = 8 + titleLabel.bounds.height + 16 + playPauseButton.bounds.height + 8
            return CGSize(width: size.width, height: height)
        }

        // MARK: - UIAccessibility

        override var accessibilityContainerType: UIAccessibilityContainerType {
            get {
                return .semanticGroup
            }
            set {
                // No-op.
            }
        }

    }

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            topControls = MediaControlsContainer(title: "Player 1")
            bottomControls = MediaControlsContainer(title: "Player 2")

            super.init(frame: frame)

            addSubview(topControls)
            addSubview(bottomControls)

            accessibilityElements = [topControls, bottomControls]
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let topControls: MediaControlsContainer
        private let bottomControls: MediaControlsContainer

        // MARK: - UIView

        override func layoutSubviews() {
            super.layoutSubviews()

            let statusBarHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0

            let controlsWidth = bounds.width - 32
            let topControlsSize = topControls.sizeThatFits(CGSize(width: controlsWidth, height: .greatestFiniteMagnitude))
            let bottomControlsSize = bottomControls.sizeThatFits(CGSize(width: controlsWidth, height: .greatestFiniteMagnitude))

            topControls.frame = CGRect(
                x: 16,
                y: statusBarHeight + 40,
                width: controlsWidth,
                height: topControlsSize.height
            )

            bottomControls.frame = CGRect(
                x: 16,
                y: topControls.frame.maxY + 40,
                width: controlsWidth,
                height: bottomControlsSize.height
            )
        }

    }

}


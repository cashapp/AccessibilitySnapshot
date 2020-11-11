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

final class NestedContainersViewController: AccessibilityViewController {

    override func loadView() {
        view = View()
    }

}

// MARK: -

private extension NestedContainersViewController {

    /// A view that shows two nested accessibility containers. The top container has a child container with two
    /// elements, plus three additional top level elements. The bottom container has two child containers, each of which
    /// has two elements, plus shares one of the elements with the first container.
    ///
    /// ```text
    ///   ┌─View─────────────────────────────────────────────────┐
    ///   │ ┌─ParentContainerView──────────────────────────────┐ │
    ///   │ │//////////////////////////////////////////////////│ │
    ///   │ │/┌─ChildContainerView───┐/////////////////////////│ │
    ///   │ │/│XX┌────────────────┐XX│///┌────────────────┐////│ │
    ///   │ │/│XX│       A        │XX│///│       C        │////│ │
    ///   │ │/│XX│                │XX│///│                │////│ │
    ///   │ │/│XX└────────────────┘XX│///└────────────────┘////│ │
    ///   │ │/│XX┌────────────────┐XX│///┌────────────────┐////│ │
    ///   │ │/│XX│       B        │XX│///│       D        │////│ │
    ///   │ │/│XX│                │XX│///│                │////│ │
    ///   │ │/│XX└────────────────┘XX│///└────────────────┘////│ │
    ///   │ │/└──────────────────────┘/////////////////////////│ │
    ///   │ │///////////////┌──────────────────┐///////////////│ │
    ///   │ └───────────────┤      Shared      ├───────────────┘ │
    ///   │ ┌───────────────┤                  ├───────────────┐ │
    ///   │ │\\\\\\\\\\\\\\\└──────────────────┘\\\\\\\\\\\\\\\│ │
    ///   │ │\┌─ChildContainerView───┐┌─ChildContainerView───┐\│ │
    ///   │ │\│XX┌────────────────┐XX││XX┌────────────────┐XX│\│ │
    ///   │ │\│XX│       E        │XX││XX│       G        │XX│\│ │
    ///   │ │\│XX│                │XX││XX│                │XX│\│ │
    ///   │ │\│XX└────────────────┘XX││XX└────────────────┘XX│\│ │
    ///   │ │\│XX┌────────────────┐XX││XX┌────────────────┐XX│\│ │
    ///   │ │\│XX│       F        │XX││XX│       H        │XX│\│ │
    ///   │ │\│XX│                │XX││XX│                │XX│\│ │
    ///   │ │\│XX└────────────────┘XX││XX└────────────────┘XX│\│ │
    ///   │ │\└──────────────────────┘└──────────────────────┘\│ │
    ///   │ │\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\│ │
    ///   │ └─ParentContainerView──────────────────────────────┘ │
    ///   └──────────────────────────────────────────────────────┘
    /// ```
    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            self.topContainerView = .init(
                leftTopElementLabel: "A",
                leftBottomElementLabel: "B",
                rightTopElementLabel: "C",
                rightBottomElementLabel: "D",
                rightGroupIsContainer: false,
                sharedElement: sharedElementView
            )

            self.bottomContainerView = .init(
                leftTopElementLabel: "E",
                leftBottomElementLabel: "F",
                rightTopElementLabel: "G",
                rightBottomElementLabel: "H",
                rightGroupIsContainer: true,
                sharedElement: sharedElementView
            )

            super.init(frame: frame)

            sharedElementView.isAccessibilityElement = true
            sharedElementView.accessibilityLabel = "Shared"
            sharedElementView.backgroundColor = .lightGray
            addSubview(sharedElementView)

            addSubview(topContainerView)
            addSubview(bottomContainerView)

            accessibilityElements = [topContainerView, bottomContainerView]
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let sharedElementView: UIView = .init()
        private let topContainerView: ParentContainerView
        private let bottomContainerView: ParentContainerView

        // MARK: - UIView

        override func layoutSubviews() {
            let contentBounds = bounds.insetBy(dx: 0, dy: 60)
            let containerHeight = contentBounds.height / 2 - 32

            topContainerView.frame = contentBounds.slice(from: .minYEdge, amount: containerHeight).slice
            bottomContainerView.frame = contentBounds.slice(from: .maxYEdge, amount: containerHeight).slice

            sharedElementView.bounds.size = .init(width: bounds.width / 2, height: 32)
            sharedElementView.alignToSuperview(.center)
        }

    }

}

// MARK: -

private extension NestedContainersViewController {

    final class ParentContainerView: UIView {

        // MARK: - Life Cycle

        init(
            leftTopElementLabel: String,
            leftBottomElementLabel: String,
            rightTopElementLabel: String,
            rightBottomElementLabel: String,
            rightGroupIsContainer: Bool,
            sharedElement: UIView
        ) {
            self.leftContainerView = .init(
                topElementLabel: leftTopElementLabel,
                bottomElementLabel: leftBottomElementLabel,
                isContainer: true
            )

            self.rightContainerView = .init(
                topElementLabel: rightTopElementLabel,
                bottomElementLabel: rightBottomElementLabel,
                isContainer: rightGroupIsContainer
            )

            super.init(frame: .zero)

            addSubview(leftContainerView)
            addSubview(rightContainerView)

            if rightGroupIsContainer {
                accessibilityElements = [
                    leftContainerView,
                    rightContainerView,
                    sharedElement,
                ]
            } else {
                accessibilityElements = [
                    leftContainerView,
                    rightContainerView.topView,
                    rightContainerView.bottomView,
                    sharedElement,
                ]
            }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let leftContainerView: ChildContainerView
        private let rightContainerView: ChildContainerView

        // MARK: - UIView

        override func layoutSubviews() {
            let containerWidth = bounds.width / 2
            (leftContainerView.frame, rightContainerView.frame) = bounds.slice(from: .minXEdge, amount: containerWidth)
        }

    }

    final class ChildContainerView: UIView {

        // MARK: - Life Cycle

        init(topElementLabel: String, bottomElementLabel: String, isContainer: Bool) {
            super.init(frame: .zero)

            topView.isAccessibilityElement = true
            topView.accessibilityLabel = topElementLabel
            topView.backgroundColor = .lightGray
            addSubview(topView)

            bottomView.isAccessibilityElement = true
            bottomView.accessibilityLabel = bottomElementLabel
            bottomView.backgroundColor = .lightGray
            addSubview(bottomView)

            if isContainer {
                accessibilityElements = [topView, bottomView]
            }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Properties

        let topView: UIView = .init()
        let bottomView: UIView = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            let contentBounds = bounds.insetBy(dx: 24, dy: 0)
            let elementHeight = contentBounds.height / 2 - 12

            topView.frame = contentBounds.slice(from: .minYEdge, amount: elementHeight).slice
            bottomView.frame = contentBounds.slice(from: .maxYEdge, amount: elementHeight).slice
        }

    }

}

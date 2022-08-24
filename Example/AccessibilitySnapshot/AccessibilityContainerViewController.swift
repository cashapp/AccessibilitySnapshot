//
//  Copyright 2022 Square Inc.
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

final class AccessibilityContainerViewController: AccessibilityViewController {

    // MARK: - Life Cycle

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Properties

    private var rootView: View {
        return view as! View
    }

    // MARK: - UIViewController

    override func loadView() {
        view = View()
    }

}

extension AccessibilityContainerViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            addSubview(subviewsView)
            addSubview(subviewsWithNonElementView)
            addSubview(elementsView)
            addSubview(subviewsAndElementsView)
            addSubview(semanticGroupView)

            backgroundColor = .white
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let subviewsView: SubviewsAndSelfView = .init(containerMode: .subviews)

        private let subviewsWithNonElementView: SubviewsAndSelfView = .init(containerMode: .subviewsWithNonElement)

        private let elementsView: SubviewsAndSelfView = .init(containerMode: .elements)

        private let subviewsAndElementsView: SubviewsAndSelfView = .init(containerMode: .subviewsAndElements)

        private let semanticGroupView: SubviewsAndSelfView = .init(containerMode: .subviews, isSemanticGroup: true)

        // MARK: - UIView

        override func layoutSubviews() {
            let contentBounds = bounds.inset(by: layoutMargins)

            subviewsView.resize(toFitWidth: contentBounds.width)
            subviewsWithNonElementView.resize(toFitWidth: contentBounds.width)
            elementsView.resize(toFitWidth: contentBounds.width)
            subviewsAndElementsView.resize(toFitWidth: contentBounds.width)
            semanticGroupView.resize(toFitWidth: contentBounds.width)

            applySubviewDistribution(
                [
                    subviewsView,
                    24.fixed,
                    subviewsWithNonElementView,
                    24.fixed,
                    elementsView,
                    24.fixed,
                    subviewsAndElementsView,
                    24.fixed,
                    semanticGroupView,
                ],
                inRect: contentBounds
            )
        }

    }

    private final class SubviewsAndSelfView: UIView {

        // MARK: - Life Cycle

        init(containerMode: ContainerMode, isSemanticGroup: Bool = false, frame: CGRect = .zero) {
            self.containerMode = containerMode
            self.isSemanticGroup = isSemanticGroup

            super.init(frame: frame)

            leftLabel.font = .boldSystemFont(ofSize: 14)
            leftLabel.textColor = .black
            leftLabel.text = "Left"
            addSubview(leftLabel)

            rightLabel.font = .systemFont(ofSize: 18)
            rightLabel.textColor = .black
            rightLabel.text = "Right"
            addSubview(rightLabel)

            backgroundColor = .lightGray
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Types

        enum ContainerMode {

            case subviews

            // Using this mode breaks VoiceOver, so it isn't included in the actual list. It's left here for easy
            // testing to see if this changes in the future.
            case selfAndSubviews

            case subviewsWithNonElement

            case elements

            case subviewsAndElements

        }

        // MARK: - Public Properties

        let containerMode: ContainerMode

        let isSemanticGroup: Bool

        let rightLabel: UILabel = .init()

        let leftLabel: UILabel = .init()

        var _leftElement: UIAccessibilityElement?
        var leftElement: UIAccessibilityElement {
            if let leftElement = _leftElement {
                return leftElement
            }

            let element = UIAccessibilityElement(accessibilityContainer: self)
            _leftElement = element
            return element
        }

        var _rightElement: UIAccessibilityElement?
        var rightElement: UIAccessibilityElement {
            if let rightElement = _rightElement {
                return rightElement
            }

            let element = UIAccessibilityElement(accessibilityContainer: self)
            _rightElement = element
            return element
        }

        // MARK: - UIAccessibility

        override var accessibilityLabel: String? {
            get {
                return "Group Description"
            }
            set {
                super.accessibilityLabel = newValue
            }
        }

        // MARK: - UIAccessibilityContainer

        override var accessibilityElements: [Any]? {
            get {
                switch containerMode {
                case .subviews, .subviewsWithNonElement:
                    return [rightLabel, leftLabel]

                case .selfAndSubviews:
                    return [self, rightLabel, leftLabel]

                case .elements:
                    leftElement.isAccessibilityElement = true
                    leftElement.accessibilityFrame = leftLabel.accessibilityFrame
                    leftElement.accessibilityLabel = leftLabel.accessibilityLabel

                    rightElement.isAccessibilityElement = true
                    rightElement.accessibilityFrame = rightLabel.accessibilityFrame
                    rightElement.accessibilityLabel = rightLabel.accessibilityLabel

                    return [
                        rightElement,
                        leftElement,
                    ]

                case .subviewsAndElements:
                    leftElement.accessibilityFrameInContainerSpace = leftLabel.frame
                    leftElement.accessibilityLabel = leftLabel.accessibilityLabel

                    return [
                        rightLabel,
                        leftElement,
                    ]
                }
            }
            set {
                super.accessibilityElements = newValue
            }
        }

        override var accessibilityContainerType: UIAccessibilityContainerType {
            get {
                if isSemanticGroup, #available(iOS 13, *) {
                    return .semanticGroup
                } else {
                    return .none
                }
            }
            set {
                super.accessibilityContainerType = newValue
            }
        }

        // MARK: - UIView

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            return CGSize(width: size.width, height: 60)
        }

        override func layoutSubviews() {
            leftLabel.sizeToFit()
            rightLabel.sizeToFit()

            applySubviewDistribution([leftLabel, 1.flexible, rightLabel], axis: .horizontal)

            switch containerMode {
            case .subviews, .selfAndSubviews, .elements, .subviewsAndElements:
                rightLabel.isAccessibilityElement = true
            case .subviewsWithNonElement:
                rightLabel.isAccessibilityElement = false
            }
        }

    }

}

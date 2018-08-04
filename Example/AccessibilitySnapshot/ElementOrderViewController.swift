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

final class ElementOrderViewController: AccessibilityViewController {

    // MARK: - Public Types

    enum ViewConfiguration {
        /// An accessible view at a given offset from the center of the screen.
        case element(UIOffset)

        /// An accessibility container with elements at the given offsets from the center of the screen.
        ///
        /// - `withSizeZero`: When the container has a zero size, the contained elements will not be included in the
        /// hierarchy.
        case container([UIOffset], withSizeZero: Bool)

        /// A view with accessible subviews at the given offsets from the center of the screen.
        case viewWithAccessibleSubviews([UIOffset], isAccessibilityElement: Bool, groupChildren: Bool)
    }

    // MARK: - Life Cycle

    init(configurations: [ViewConfiguration]) {
        views = configurations.enumerated().map { index, configuration in
            let view: UIView
            switch configuration {
            case .element:
                view = UIView()
                view.isAccessibilityElement = true
                view.accessibilityLabel = "Element \(index)"
                view.frame.size = CGSize(width: 32, height: 32)
                view.layer.cornerRadius = 16
                view.backgroundColor = .lightGray

            case let .container(elementOffsets, withSizeZero: withSizeZero):
                view = AccessibilityContainerView(elementOffsets: elementOffsets, containerIndex: index)

                view.frame.size = withSizeZero ? .zero : CGSize(width: 32, height: 32)

            case let .viewWithAccessibleSubviews(offsets, isAccessibilityElement: isAccessibilityElement, groupChildren: groupChildren):
                view = AccessibleGroupView(elementOffsets: offsets, groupIndex: index)
                view.isAccessibilityElement = isAccessibilityElement
                view.shouldGroupAccessibilityChildren = groupChildren
                view.frame.size = CGSize(width: 32, height: 32)

            }

            return (view, configuration)
        }

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Properties

    private let views: [(UIView, ViewConfiguration)]

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        views.forEach { view.addSubview($0.0) }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        views.forEach {
            let (view, configuration) = $0
            switch configuration {
            case let .element(offset):
                view.align(
                    .center,
                    withSuperviewPosition: .center,
                    horizontalOffset: offset.horizontal,
                    verticalOffset: offset.vertical
                )

            case .container, .viewWithAccessibleSubviews:
                view.alignToSuperview(.center)
            }
        }
    }

}

// MARK: -

extension ElementOrderViewController {

    static func makeConfigurationSelectionViewController(
        presentingViewController: UIViewController
    ) -> UIViewController {
        func selectConfigurations(_ configurations: [ViewConfiguration]) {
            let viewController = ElementOrderViewController(configurations: configurations)
            presentingViewController.present(viewController, animated: true, completion: nil)
        }

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alertController.addAction(.init(title: "Scatter", style: .default, handler: { _ in
            selectConfigurations(.scatter)
        }))

        alertController.addAction(.init(title: "Grid", style: .default, handler: { _ in
            selectConfigurations(.grid)
        }))

        alertController.addAction(.init(title: "Container in Element Stack", style: .default, handler: { _ in
            selectConfigurations(.containerInElementStack)
        }))

        alertController.addAction(.init(title: "Zero-Sized Container in Element Stack", style: .default, handler: { _ in
            selectConfigurations(.zeroSizedContainerInElementStack)
        }))

        alertController.addAction(.init(title: "Grouped Views in Element Stack", style: .default, handler: { _ in
            selectConfigurations(.groupedViewsInElementStack)
        }))

        alertController.addAction(.init(title: "Ungrouped Views in Element Stack", style: .default, handler: { _ in
            selectConfigurations(.ungroupedViewsInElementStack)
        }))

        alertController.addAction(.init(title: "Ungrouped Views in Accessible Parent", style: .default, handler: { _ in
            selectConfigurations(.ungroupedViewsInAccessibleParent)
        }))

        alertController.addAction(.init(title: "Cancel", style: .cancel, handler: nil))

        return alertController
    }

}

// MARK: -

extension Array where Element == ElementOrderViewController.ViewConfiguration {

    /// A set of 4 elements, scattered in each direction.
    ///
    /// The main intention of this element set is to differentiate between vertical and horizontal scanning.
    static let scatter: [ElementOrderViewController.ViewConfiguration] = [
        .element(.init(horizontal: -80, vertical: -80)),
        .element(.init(horizontal: 30, vertical: -30)),
        .element(.init(horizontal: -30, vertical: 30)),
        .element(.init(horizontal: 80, vertical: 80)),
    ]

    /// A 3x3 grid of elements.
    ///
    /// These are intentionally listed in a different order than VoiceOver is expected to read them in to ensure that
    /// the order they are added doesn't affect the test.
    static let grid: [ElementOrderViewController.ViewConfiguration] = [
        .element(.init(horizontal: 60, vertical: 60)),
        .element(.init(horizontal: -60, vertical: -60)),
        .element(.init(horizontal: 0, vertical: 60)),
        .element(.init(horizontal: 0, vertical: -60)),
        .element(.init(horizontal: -60, vertical: 60)),
        .element(.init(horizontal: 60, vertical: -60)),
        .element(.init(horizontal: 60, vertical: 0)),
        .element(.init(horizontal: -60, vertical: 0)),
        .element(.init(horizontal: 0, vertical: 0)),
    ]

    /// A container with elements interspersed in a stack of accessible views.
    ///
    /// The main intention of this element set is to determine how VoiceOver groups accesibility containers together.
    static let containerInElementStack: [ElementOrderViewController.ViewConfiguration] = [
        .element(.init(horizontal: 0, vertical: -120)),
        .element(.init(horizontal: 0, vertical: 0)),
        .element(.init(horizontal: 0, vertical: 120)),
        .container([
            .init(horizontal: 0, vertical: 60),
            .init(horizontal: 0, vertical: -60),
        ], withSizeZero: false),
    ]

    /// A zero-sized container with elements interspersed in a stack of accessible views.
    ///
    /// The main intention of this element set is to verify that VoiceOver skips accesibility containers with a zero
    /// size.
    static let zeroSizedContainerInElementStack: [ElementOrderViewController.ViewConfiguration] = [
        .element(.init(horizontal: 0, vertical: -120)),
        .element(.init(horizontal: 0, vertical: 0)),
        .element(.init(horizontal: 0, vertical: 120)),
        .container([
            .init(horizontal: 0, vertical: 60),
            .init(horizontal: 0, vertical: -60),
        ], withSizeZero: true),
    ]

    static let groupedViewsInElementStack: [ElementOrderViewController.ViewConfiguration] = [
        .element(.init(horizontal: 0, vertical: -120)),
        .element(.init(horizontal: 0, vertical: 0)),
        .element(.init(horizontal: 0, vertical: 120)),
        .viewWithAccessibleSubviews([
            .init(horizontal: 0, vertical: 60),
            .init(horizontal: 0, vertical: -60),
        ], isAccessibilityElement: false, groupChildren: true),
    ]

    static let ungroupedViewsInElementStack: [ElementOrderViewController.ViewConfiguration] = [
        .element(.init(horizontal: 0, vertical: -120)),
        .element(.init(horizontal: 0, vertical: 0)),
        .element(.init(horizontal: 0, vertical: 120)),
        .viewWithAccessibleSubviews([
            .init(horizontal: 0, vertical: 60),
            .init(horizontal: 0, vertical: -60),
        ], isAccessibilityElement: false, groupChildren: false),
    ]

    static let ungroupedViewsInAccessibleParent: [ElementOrderViewController.ViewConfiguration] = [
        .element(.init(horizontal: 0, vertical: -120)),
        .element(.init(horizontal: 0, vertical: 120)),
        .viewWithAccessibleSubviews([
            .init(horizontal: 0, vertical: 60),
            .init(horizontal: 0, vertical: -60),
        ], isAccessibilityElement: true, groupChildren: false),
    ]

}

// MARK: -

private final class AccessibilityContainerView: UIView {

    // MARK: - Life Cycle

    init(elementOffsets: [UIOffset], containerIndex: Int) {
        super.init(frame: .zero)

        accessibilityElements = elementOffsets.enumerated().map { index, offset in
            let element = UIAccessibilityElement(accessibilityContainer: self)

            element.accessibilityLabel = "Container \(containerIndex) Element \(index)"
            element.accessibilityFrameInContainerSpace = CGRect(
                x: offset.horizontal,
                y: offset.vertical,
                width: 32,
                height: 32
            )

            return element
        }

        // This accessibility label should never be read, but is set here to ensure that the container isn't being
        // skipped because there's no label.
        accessibilityLabel = "Container \(containerIndex) Parent"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: -

private final class AccessibleGroupView: UIView {

    // MARK: - Life Cycle

    init(elementOffsets: [UIOffset], groupIndex: Int) {
        super.init(frame: .zero)

        elementOffsets.enumerated().forEach { index, offset in
            let view = UIView()

            view.isAccessibilityElement = true
            view.accessibilityLabel = "Group \(groupIndex) Element \(index)"
            view.frame = CGRect(
                x: offset.horizontal,
                y: offset.vertical,
                width: 32,
                height: 32
            )
            view.layer.cornerRadius = 16
            view.backgroundColor = .lightGray

            addSubview(view)
        }

        accessibilityLabel = "Group \(groupIndex) Parent"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

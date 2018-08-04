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

final class ElementSelectionViewController: AccessibilityViewController {

    // MARK: - Public Types

    enum ViewConfiguration {

        /// An accessible view.
        ///
        /// - `accessibilityElementsHidden`: Whether or not the child elements should be seen by VoiceOver.
        /// - `isHidden`: Whether or not the container view is visible on the screen.
        case accessibilityElement(accessibilityElementsHidden: Bool, isHidden: Bool)

        case nonAccessibilityElement

        /// An accessibility container with four elements. Three elements are positioned relative to the container, and
        /// one is positioned at a fixed point on the screen.
        ///
        /// - `accessibilityElementsHidden`: Whether or not the child elements should be seen by VoiceOver.
        /// - `isHidden`: Whether or not the container view is visible on the screen.
        case accessibilityContainer(accessibilityElementsHidden: Bool, isHidden: Bool)

        // A view with three accessible elements.
        case viewWithAccessibleSubviews(accessibilityElementsHidden: Bool, isHidden: Bool)

    }

    // MARK: - Life Cycle

    init(configurations: [ViewConfiguration]) {
        views = configurations.map { configuration in
            let view: UIView
            switch configuration {
            case let .accessibilityElement(accessibilityElementsHidden: accessibilityElementsHidden, isHidden: isHidden):
                view = UIView()
                view.isAccessibilityElement = true
                view.accessibilityElementsHidden = accessibilityElementsHidden
                view.isHidden = isHidden

            case .nonAccessibilityElement:
                view = UIView()
                view.isAccessibilityElement = false

            case let .accessibilityContainer(accessibilityElementsHidden: accessibilityElementsHidden, isHidden: isHidden):
                view = AccessibilityContainerView()
                view.accessibilityElementsHidden = accessibilityElementsHidden
                view.isHidden = isHidden

            case let .viewWithAccessibleSubviews(accessibilityElementsHidden: accessibilityElementsHidden, isHidden: isHidden):
                view = AccessibleGroupView()
                view.accessibilityElementsHidden = accessibilityElementsHidden
                view.isHidden = isHidden
            }

            view.frame.size = CGSize(width: 64, height: 64)
            view.layer.cornerRadius = 32
            view.backgroundColor = .lightGray
            view.accessibilityLabel = "Lorem ipsum"

            return view
        }

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Properties

    private let views: [UIView]

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        views.forEach { view.addSubview($0) }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let statusBarHeight = UIApplication.shared.statusBarFrame.height

        var distributionSpecifiers: [ViewDistributionSpecifying] = [ statusBarHeight.fixed, 1.flexible ]
        for subview in views {
            distributionSpecifiers.append(subview)
            distributionSpecifiers.append(1.flexible)
        }
        view.applySubviewDistribution(distributionSpecifiers)
    }

}

// MARK: -

extension ElementSelectionViewController {

    static func makeConfigurationSelectionViewController(
        presentingViewController: UIViewController
    ) -> UIViewController {
        return makeAlertControllerForElementSelection(
            presentingViewController: presentingViewController,
            existingConfigurations: []
        )
    }

    private static func makeAlertControllerForElementSelection(
        presentingViewController: UIViewController,
        existingConfigurations: [ElementSelectionViewController.ViewConfiguration]
    ) -> UIAlertController {
        let nextHandler: (ElementSelectionViewController.ViewConfiguration?) -> Void = { configuration in
            if let configuration = configuration {
                presentingViewController.present(
                    makeAlertControllerForElementSelection(
                        presentingViewController: presentingViewController,
                        existingConfigurations: existingConfigurations + [configuration]
                    ),
                    animated: true,
                    completion: nil
                )

            } else {
                let elementSelectionViewController = ElementSelectionViewController(
                    configurations: existingConfigurations
                )
                presentingViewController.present(elementSelectionViewController, animated: true, completion: nil)
            }
        }

        let ordinal = NumberFormatter.localizedString(
            from: NSNumber(value: existingConfigurations.count + 1),
            number: .ordinal
        )
        let alertController = UIAlertController(
            title: "Select \(ordinal) View Configuration",
            message: nil,
            preferredStyle: .actionSheet
        )

        alertController.addAction(.init(title: "Accessibility Element", style: .default, handler: { _ in
            nextHandler(.accessibilityElement(accessibilityElementsHidden: false, isHidden: false))
        }))

        alertController.addAction(.init(title: "Accessibility Element with Elements Hidden", style: .default, handler: { _ in
            nextHandler(.accessibilityElement(accessibilityElementsHidden: true, isHidden: false))
        }))

        alertController.addAction(.init(title: "Accessibility Element (Hidden)", style: .default, handler: { _ in
            nextHandler(.accessibilityElement(accessibilityElementsHidden: false, isHidden: true))
        }))

        alertController.addAction(.init(title: "Non-Accessibility Element", style: .default, handler: { _ in
            nextHandler(.nonAccessibilityElement)
        }))

        alertController.addAction(.init(title: "Accessibility Container", style: .default, handler: { _ in
            nextHandler(.accessibilityContainer(accessibilityElementsHidden: false, isHidden: false))
        }))

        alertController.addAction(.init(title: "Accessibility Container with Elements Hidden", style: .default, handler: { _ in
            nextHandler(.accessibilityContainer(accessibilityElementsHidden: true, isHidden: false))
        }))

        alertController.addAction(.init(title: "Accessibility Container (Hidden)", style: .default, handler: { _ in
            nextHandler(.accessibilityContainer(accessibilityElementsHidden: false, isHidden: true))
        }))

        alertController.addAction(.init(title: "Grouped Views", style: .default, handler: { _ in
            nextHandler(.viewWithAccessibleSubviews(accessibilityElementsHidden: false, isHidden: false))
        }))

        alertController.addAction(.init(title: "Grouped Views in Parent that Hides Elements", style: .default, handler: { _ in
            nextHandler(.viewWithAccessibleSubviews(accessibilityElementsHidden: true, isHidden: false))
        }))

        alertController.addAction(.init(title: "Grouped Views in Hidden Parent", style: .default, handler: { _ in
            nextHandler(.viewWithAccessibleSubviews(accessibilityElementsHidden: false, isHidden: true))
        }))

        if !existingConfigurations.isEmpty {
            alertController.addAction(.init(title: "Done", style: .cancel, handler: { _ in
                nextHandler(nil)
            }))
        }

        return alertController
    }

}

// MARK: -

private final class AccessibilityContainerView: UIView {

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        accessibilityElements = (0..<3).map { index in
            let element = UIAccessibilityElement(accessibilityContainer: self)

            element.accessibilityLabel = "Element \(index)"
            element.accessibilityFrameInContainerSpace = CGRect(
                x: 16 + 60 * (index - 1),
                y: 16,
                width: 32,
                height: 32
            )

            return element
        }

        let fixedFrameElement = UIAccessibilityElement(accessibilityContainer: self)
        fixedFrameElement.accessibilityLabel = "Fixed Frame Element"
        fixedFrameElement.accessibilityFrame = CGRect(x: 20, y: 20, width: 32, height: 32)
        accessibilityElements?.append(fixedFrameElement)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: -

private final class AccessibleGroupView: UIView {

    // MARK: - Life Cycle

    init() {
        super.init(frame: .zero)

        (-1...1).forEach { index in
            let view = UIView()

            view.isAccessibilityElement = true
            view.accessibilityLabel = "Element \(index+1)"
            view.frame = CGRect(
                x: index * 80 + 16,
                y: 16,
                width: 32,
                height: 32
            )
            view.layer.cornerRadius = 16
            view.backgroundColor = .darkGray

            addSubview(view)
        }

        accessibilityLabel = "Accessibility Group"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

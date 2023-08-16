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

final class ModalAccessibilityViewController: AccessibilityViewController {

    // MARK: - Life Cycle

    init(topLevelCount: Int, containerCount: Int, modalAccessibilityMode: ModalAccessibilityMode) {
        super.init(nibName: nil, bundle: nil)

        rootView.modalViews = (0..<topLevelCount).map { ModalView(index: $0, accessibilityMode: modalAccessibilityMode) }
        rootView.modalContainerViews = (0..<containerCount).map { _ in ModalContainerView() }
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

    // MARK: - Public Types

    enum ModalAccessibilityMode {
        case viewIsAccessible
        case viewContainsAccessibleElement
        case viewIsInaccessible
    }

}

// MARK: -

private extension ModalAccessibilityViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            views.forEach { subview in
                subview.frame.size = CGSize(width: 64, height: 64)
                subview.layer.cornerRadius = 32
                subview.backgroundColor = .lightGray

                subview.isAccessibilityElement = true
                subview.accessibilityLabel = "Don't Read Me"

                addSubview(subview)
            }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Properties

        let views: [UIView] = (0..<4).map { _ in UIView() }

        var modalViews: [ModalView] = [] {
            didSet {
                oldValue.forEach { $0.removeFromSuperview() }
                modalViews.forEach { addSubview($0) }
            }
        }

        var modalContainerViews: [ModalContainerView] = [] {
            didSet {
                oldValue.forEach { $0.removeFromSuperview() }
                modalContainerViews.forEach { addSubview($0) }
            }
        }

        // MARK: - UIView

        override func layoutSubviews() {
            views[0].align(withSuperview: .topLeft, inset: 20)
            views[1].align(withSuperview: .topRight, inset: 20)
            views[2].align(withSuperview: .bottomRight, inset: 20)
            views[3].align(withSuperview: .bottomLeft, inset: 20)

            var distributionItems: [ViewDistributionSpecifying] = [1.flexible]

            modalViews.forEach { modal in
                modal.sizeToFit()
                distributionItems.append(modal)
                distributionItems.append((0.5).flexible)
            }

            modalContainerViews.forEach { container in
                container.sizeToFit()
                distributionItems.append(container)
                distributionItems.append((0.5).flexible)
            }

            _ = distributionItems.dropLast()
            distributionItems.append(1.flexible)
            applyVerticalSubviewDistribution(distributionItems)
        }

    }

}

// MARK: -

private extension ModalAccessibilityViewController {

    final class ModalView: UIView {

        // MARK: - Life Cycle

        init(index: Int, accessibilityMode: ModalAccessibilityMode) {
            self.accessibilityMode = accessibilityMode

            super.init(frame: .zero)

            accessibilityViewIsModal = true
            accessibilityLabel = "Modal View \(index)"

            backgroundColor = .lightGray
            layer.cornerRadius = 16

            label.text = "Modal \(index)"
            addSubview(label)

            switch accessibilityMode {
            case .viewIsAccessible:
                isAccessibilityElement = true
            case .viewContainsAccessibleElement,
                 .viewIsInaccessible:
                isAccessibilityElement = false
            }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let accessibilityMode: ModalAccessibilityMode

        private let label: UILabel = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            label.sizeToFit()
            label.align(withSuperview: .center)

            switch accessibilityMode {
            case .viewContainsAccessibleElement,
                 .viewIsAccessible:
                label.isAccessibilityElement = true
            case .viewIsInaccessible:
                label.isAccessibilityElement = false
            }
        }

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            let labelSize = label.sizeThatFits(size)
            return CGSize(width: labelSize.width + 32, height: labelSize.width + 20)
        }

    }

}

// MARK: -

private extension ModalAccessibilityViewController {

    final class ModalContainerView: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            modalViews.forEach(addSubview)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let modalViews: [ModalView] = (0..<2).map { index in
            ModalView(index: index, accessibilityMode: .viewContainsAccessibleElement)
        }

        // MARK: - UIView

        override func layoutSubviews() {
            modalViews.forEach { $0.sizeToFit() }
            applyVerticalSubviewDistribution(
                [
                    10.fixed,
                    modalViews[0],
                    10.fixed,
                    modalViews[1],
                    10.fixed,
                ]
            )
        }

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            let modalSizeThatFits = modalViews[0].sizeThatFits(size)
            return CGSize(width: modalSizeThatFits.width + 20, height: modalSizeThatFits.height + 30)
        }

    }

}

// MARK: -

extension ModalAccessibilityViewController {

    static func makeConfigurationSelectionViewController(
        presentingViewController: UIViewController
    ) -> UIViewController {
        func selectConfiguration(
            topLevelCount: Int,
            containerCount: Int,
            modalAccessibilityMode: ModalAccessibilityMode = .viewContainsAccessibleElement
        ) {
            let viewController = ModalAccessibilityViewController(
                topLevelCount: topLevelCount,
                containerCount: containerCount,
                modalAccessibilityMode: modalAccessibilityMode
            )
            presentingViewController.present(viewController, animated: true, completion: nil)
        }

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alertController.addAction(.init(title: "Single Modal", style: .default, handler: { _ in
            selectConfiguration(topLevelCount: 1, containerCount: 0)
        }))

        alertController.addAction(.init(title: "Single Directly Specified Modal", style: .default, handler: { _ in
            selectConfiguration(topLevelCount: 1, containerCount: 0, modalAccessibilityMode: .viewIsAccessible)
        }))

        alertController.addAction(.init(title: "Single Inaccessible Modal", style: .default, handler: { _ in
            selectConfiguration(topLevelCount: 1, containerCount: 0, modalAccessibilityMode: .viewIsInaccessible)
        }))

        alertController.addAction(.init(title: "Two Modals", style: .default, handler: { _ in
            selectConfiguration(topLevelCount: 2, containerCount: 0)
        }))

        alertController.addAction(.init(title: "Two Containers", style: .default, handler: { _ in
            selectConfiguration(topLevelCount: 0, containerCount: 2)
        }))

        alertController.addAction(.init(title: "One Modal, One Container", style: .default, handler: { _ in
            selectConfiguration(topLevelCount: 1, containerCount: 1)
        }))

        return alertController
    }

}

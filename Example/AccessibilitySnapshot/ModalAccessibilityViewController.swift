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

    init(topLevelCount: Int, containerCount: Int) {
        modalViews = (0..<topLevelCount).map { index in ModalView(index: index) }
        modalContainerViews = (0..<containerCount).map { _ in ModalContainerView() }

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Properties

    private let views: [UIView] = (0..<4).map { _ in UIView() }

    private let modalViews: [ModalView]

    private let modalContainerViews: [ModalContainerView]

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        views.forEach { subview in
            subview.frame.size = CGSize(width: 64, height: 64)
            subview.layer.cornerRadius = 32
            subview.backgroundColor = .lightGray

            subview.isAccessibilityElement = true
            subview.accessibilityLabel = "Don't Read Me"

            view.addSubview(subview)
        }

        modalViews.forEach { view.addSubview($0) }

        modalContainerViews.forEach { view.addSubview($0) }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        views[0].alignToSuperview(.topLeft, inset: 20)
        views[1].alignToSuperview(.topRight, inset: 20)
        views[2].alignToSuperview(.bottomRight, inset: 20)
        views[3].alignToSuperview(.bottomLeft, inset: 20)

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
        view.applySubviewDistribution(distributionItems)
    }

}

// MARK: -

private extension ModalAccessibilityViewController {

    final class ModalView: UIView {

        // MARK: - Life Cycle

        init(index: Int) {
            super.init(frame: .zero)

            accessibilityViewIsModal = true

            backgroundColor = .lightGray
            layer.cornerRadius = 16

            label.text = "Modal \(index)"
            addSubview(label)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let label: UILabel = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            label.sizeToFit()
            label.alignToSuperview(.center)
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

        private let modalViews: [ModalView] = (0..<2).map { index in ModalView(index: index) }

        // MARK: - UIView

        override func layoutSubviews() {
            modalViews.forEach { $0.sizeToFit() }
            applySubviewDistribution([
                10.fixed,
                modalViews[0],
                10.fixed,
                modalViews[1],
                10.fixed,
            ])
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
        func selectConfiguration(topLevelCount: Int, containerCount: Int) {
            let viewController = ModalAccessibilityViewController(
                topLevelCount: topLevelCount,
                containerCount: containerCount
            )
            presentingViewController.present(viewController, animated: true, completion: nil)
        }

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alertController.addAction(.init(title: "Single Modal", style: .default, handler: { _ in
            selectConfiguration(topLevelCount: 1, containerCount: 0)
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

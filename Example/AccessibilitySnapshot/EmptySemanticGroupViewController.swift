import UIKit

final class EmptySemanticGroupViewController: AccessibilityViewController {
    // MARK: - UIViewController

    override func loadView() {
        view = View(presentPopover: { [weak self] sourceView in self?.presentPopover(from: sourceView) })
    }

    // MARK: - Private Methods

    private func presentPopover(from sourceView: UIView) {
        let popover = PopoverContentViewController()
        popover.modalPresentationStyle = .popover
        popover.popoverPresentationController?.sourceView = sourceView
        popover.popoverPresentationController?.sourceRect = sourceView.bounds
        popover.popoverPresentationController?.delegate = popover
        present(popover, animated: true)
    }
}

// MARK: -

private extension EmptySemanticGroupViewController {
    final class View: UIView {
        // MARK: - Life Cycle

        init(presentPopover: @escaping (UIView) -> Void) {
            self.presentPopover = presentPopover

            super.init(frame: .zero)

            beforeButton.setTitle("Before", for: .normal)
            afterButton.setTitle("After", for: .normal)
            popoverButton.setTitle("Show Popover", for: .normal)
            popoverButton.addTarget(self, action: #selector(popoverButtonTapped), for: .touchUpInside)

            emptyGroup.accessibilityContainerType = .semanticGroup
            emptyGroup.accessibilityLabel = "Empty Group"
            emptyGroup.backgroundColor = .systemTeal

            identifierOnlyGroup.accessibilityContainerType = .semanticGroup
            identifierOnlyGroup.accessibilityIdentifier = "IdentifierOnlyGroup"
            identifierOnlyGroup.backgroundColor = .systemOrange

            filledGroup.accessibilityContainerType = .semanticGroup
            filledGroup.accessibilityLabel = "Filled Group"
            filledGroup.backgroundColor = .systemGreen
            childLabel.text = "Child"
            filledGroup.addSubview(childLabel)

            [beforeButton, emptyGroup, identifierOnlyGroup, filledGroup, popoverButton, afterButton].forEach(addSubview)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let presentPopover: (UIView) -> Void

        private let beforeButton = UIButton(type: .system)

        private let emptyGroup = UIView()

        private let identifierOnlyGroup = UIView()

        private let filledGroup = UIView()

        private let childLabel = UILabel()

        private let popoverButton = UIButton(type: .system)

        private let afterButton = UIButton(type: .system)

        // MARK: - UIView

        override func layoutSubviews() {
            var y = safeAreaInsets.top + 20
            for subview in [beforeButton, emptyGroup, identifierOnlyGroup, filledGroup, popoverButton, afterButton] {
                subview.frame = CGRect(x: 20, y: y, width: bounds.width - 40, height: 60)
                y += 80
            }
            childLabel.frame = filledGroup.bounds.insetBy(dx: 12, dy: 12)
        }

        // MARK: - Private Methods

        @objc private func popoverButtonTapped() {
            presentPopover(popoverButton)
        }
    }

    final class PopoverContentViewController: UIViewController, UIPopoverPresentationControllerDelegate {
        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .white
            let button = UIButton(type: .system)
            button.setTitle("Popover Action", for: .normal)
            button.frame = CGRect(x: 20, y: 20, width: 160, height: 44)
            view.addSubview(button)
            preferredContentSize = CGSize(width: 200, height: 100)
        }

        func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
            .none
        }
    }
}

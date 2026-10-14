import UIKit

final class EmptySemanticGroupViewController: AccessibilityViewController {
    // MARK: - Private Properties

    private let popoverButton = UIButton(type: .system)

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Empty Semantic Group"
        navigationController?.overrideUserInterfaceStyle = .light

        let beforeButton = UIButton(type: .system)
        beforeButton.setTitle("Before", for: .normal)

        let emptyGroup = UIView()
        emptyGroup.backgroundColor = .systemTeal
        emptyGroup.accessibilityContainerType = .semanticGroup
        emptyGroup.accessibilityLabel = "Empty Group"

        let identifierOnlyGroup = UIView()
        identifierOnlyGroup.backgroundColor = .systemOrange
        identifierOnlyGroup.accessibilityContainerType = .semanticGroup
        identifierOnlyGroup.accessibilityIdentifier = "IdentifierOnlyGroup"

        let filledGroup = UIView()
        filledGroup.backgroundColor = .systemGreen
        filledGroup.accessibilityContainerType = .semanticGroup
        filledGroup.accessibilityLabel = "Filled Group"
        let childLabel = UILabel()
        childLabel.text = "Child"
        childLabel.translatesAutoresizingMaskIntoConstraints = false
        filledGroup.addSubview(childLabel)

        popoverButton.setTitle("Show Popover", for: .normal)
        popoverButton.addTarget(self, action: #selector(presentPopover), for: .touchUpInside)

        let afterButton = UIButton(type: .system)
        afterButton.setTitle("After", for: .normal)

        [beforeButton, popoverButton, afterButton].forEach { $0.setTitleColor(.systemBlue, for: .normal) }
        childLabel.textColor = .black

        let rows = [beforeButton, emptyGroup, identifierOnlyGroup, filledGroup, popoverButton, afterButton]
        let stackView = UIStackView(arrangedSubviews: rows)
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate(rows.map { $0.heightAnchor.constraint(equalToConstant: 60) } + [
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            childLabel.leadingAnchor.constraint(equalTo: filledGroup.leadingAnchor, constant: 12),
            childLabel.centerYAnchor.constraint(equalTo: filledGroup.centerYAnchor),
        ])
    }

    // MARK: - Private Methods

    @objc private func presentPopover() {
        let popover = PopoverContentViewController()
        popover.modalPresentationStyle = .popover
        popover.popoverPresentationController?.sourceView = popoverButton
        popover.popoverPresentationController?.sourceRect = popoverButton.bounds
        popover.popoverPresentationController?.delegate = popover
        present(popover, animated: true)
    }
}

// MARK: -

private final class PopoverContentViewController: UIViewController, UIPopoverPresentationControllerDelegate {
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

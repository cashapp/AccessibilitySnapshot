import UIKit

/// A view controller that demonstrates keyboard shortcuts without categories.
final class KeyboardShortcutsWithoutCategoriesViewController: AccessibilityViewController {
    // MARK: - Private Properties

    private lazy var storedKeyCommands: [UIKeyCommand] = {
        let shortcuts: [(title: String, input: String, modifiers: UIKeyModifierFlags, hint: String)] = [
            ("New Document", "n", .command, "Create a new document"),
            ("Open", "o", .command, "Open an existing document"),
            ("Save", "s", .command, "Save the current document"),
            ("Find", "f", .command, "Find text in document"),
            ("Go Back", UIKeyCommand.inputLeftArrow, .command, "Navigate back"),
            ("Go Forward", UIKeyCommand.inputRightArrow, .command, "Navigate forward"),
        ]

        return shortcuts.map { shortcut in
            let command = UIKeyCommand(
                title: shortcut.title,
                action: #selector(handleKeyCommand),
                input: shortcut.input,
                modifierFlags: shortcut.modifiers
            )
            command.discoverabilityTitle = shortcut.hint
            return command
        }
    }()

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
    }

    // MARK: - UIResponder

    override var keyCommands: [UIKeyCommand]? {
        return storedKeyCommands
    }

    // MARK: - Private Methods

    private func setUpUI() {
        let titleLabel = UILabel()
        titleLabel.text = "UIKit Keyboard Shortcuts"
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)

        let instructionLabel = UILabel()
        instructionLabel.text = "Press ⌘ to see available shortcuts"
        instructionLabel.font = .preferredFont(forTextStyle: .subheadline)
        instructionLabel.textColor = .secondaryLabel
        instructionLabel.textAlignment = .center
        view.addSubview(instructionLabel)

        let iconLabel = UILabel()
        iconLabel.text = "⌨️"
        iconLabel.font = .systemFont(ofSize: 64)
        iconLabel.textAlignment = .center
        view.addSubview(iconLabel)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        iconLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),

            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),

            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            instructionLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
        ])
    }

    // MARK: - Action Handlers

    @objc private func handleKeyCommand(_ sender: UIKeyCommand) {
        print(sender.title)
    }
}

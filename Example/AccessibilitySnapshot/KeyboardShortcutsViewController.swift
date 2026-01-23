import Paralayout
import UIKit

/// A view controller that demonstrates keyboard shortcuts for testing keyboard annotation snapshots.
final class KeyboardShortcutsViewController: AccessibilityViewController, KeyboardShortcutProvider {
    // MARK: - Public Properties

    var keyboardShortcutsMenu: UIMenu {
        DemoKeyboardShortcuts.menu
    }

    // MARK: - KeyboardShortcutProvider

    var menuBarInsertions: [MenuController.MenuInsertion] {
        DemoKeyboardShortcuts.menuBarInsertions
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MenuController.shared.register(provider: self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MenuController.shared.unregister(provider: self)
    }

    // MARK: - Private Methods

    private func setUpUI() {
        let titleLabel = UILabel()
        titleLabel.text = "UIKit Keyboard Shortcuts"
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.text = "(With Categories)"
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        view.addSubview(subtitleLabel)

        let instructionLabel = UILabel()
        instructionLabel.text = "Press ⌘ to see available shortcuts"
        instructionLabel.font = .preferredFont(forTextStyle: .caption1)
        instructionLabel.textColor = .secondaryLabel
        instructionLabel.textAlignment = .center
        view.addSubview(instructionLabel)

        let iconLabel = UILabel()
        iconLabel.text = "⌨️"
        iconLabel.font = .systemFont(ofSize: 64)
        iconLabel.textAlignment = .center
        view.addSubview(iconLabel)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        iconLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),

            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),

            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),

            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 8),
            instructionLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
        ])
    }
}

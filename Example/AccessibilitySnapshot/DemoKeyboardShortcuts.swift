import UIKit

/// Demo keyboard shortcuts data for testing keyboard annotation snapshots.
enum DemoKeyboardShortcuts {
    // MARK: - Complete Menu

    static let menu: UIMenu = .init(title: "", children: [fileMenu, navigationMenu])

    // MARK: - Category Menus

    static let fileMenu: UIMenu = .init(
        title: "File",
        children: [
            makeKeyCommand(title: "New Document", input: "n", modifiers: .command, hint: "Create a new document"),
            makeKeyCommand(title: "Open", input: "o", modifiers: .command, hint: "Open an existing document"),
            makeKeyCommand(title: "Save", input: "s", modifiers: .command, hint: "Save the current document"),
        ]
    )

    static let navigationMenu: UIMenu = .init(
        title: "Navigation",
        children: [
            makeKeyCommand(title: "Go Back", input: UIKeyCommand.inputLeftArrow, modifiers: .command, hint: "Navigate back"),
            makeKeyCommand(title: "Go Forward", input: UIKeyCommand.inputRightArrow, modifiers: .command, hint: "Navigate forward"),
            makeKeyCommand(title: "Refresh", input: "r", modifiers: .command, hint: "Refresh content"),
        ]
    )

    // MARK: - Menu Bar Insertions

    static let menuBarInsertions: [MenuController.MenuInsertion] = [
        .init(menu: fileMenu, position: .inlineAtStart(of: .file)),
        .init(menu: navigationMenu, position: .siblingBefore(.window)),
    ]

    // MARK: - Private Helpers

    private static func makeKeyCommand(title: String, input: String, modifiers: UIKeyModifierFlags, hint: String) -> UIKeyCommand {
        // Each command needs a unique propertyList to avoid duplicate action errors
        let propertyList: [String: Any] = [
            "title": title,
            "input": input,
            "modifiers": modifiers.rawValue,
        ]
        let command = UIKeyCommand(
            title: title,
            action: #selector(AppDelegate.handleKeyboardShortcut(_:)),
            input: input,
            modifierFlags: modifiers,
            propertyList: propertyList
        )
        command.discoverabilityTitle = hint
        return command
    }
}

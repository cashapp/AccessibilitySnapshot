//
//  Copyright 2024 Block Inc.
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
        let propertyList = "\(title)-\(input)-\(modifiers.rawValue)"
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

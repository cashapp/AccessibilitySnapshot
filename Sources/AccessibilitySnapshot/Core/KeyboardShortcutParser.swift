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

// MARK: - KeyboardShortcut

/// Represents a keyboard shortcut extracted from a UIKeyCommand.
public struct KeyboardShortcut: Equatable {
    // MARK: - Public Properties

    /// The input key for the shortcut (e.g., "n", "s", arrow keys).
    public let input: String

    /// The modifier flags for the shortcut (e.g., .command, .shift).
    public let modifierFlags: UIKeyModifierFlags

    /// The title of the key command, if available.
    public let title: String?

    /// The discoverability title shown in the keyboard shortcuts HUD.
    public let discoverabilityTitle: String?

    /// The image associated with the key command, if any.
    public let image: UIImage?

    /// The title of the menu category this shortcut belongs to, if any.
    public let menuTitle: String?

    // MARK: - Life Cycle

    public init(
        input: String,
        modifierFlags: UIKeyModifierFlags,
        title: String? = nil,
        discoverabilityTitle: String? = nil,
        image: UIImage? = nil,
        menuTitle: String? = nil
    ) {
        self.input = input
        self.modifierFlags = modifierFlags
        self.title = title
        self.discoverabilityTitle = discoverabilityTitle
        self.image = image
        self.menuTitle = menuTitle
    }

    /// Creates a KeyboardShortcut from a UIKeyCommand.
    public init(from keyCommand: UIKeyCommand, menuTitle: String? = nil) {
        input = keyCommand.input ?? ""
        modifierFlags = keyCommand.modifierFlags
        title = keyCommand.title.isEmpty ? nil : keyCommand.title
        discoverabilityTitle = keyCommand.discoverabilityTitle
        image = keyCommand.image
        self.menuTitle = menuTitle
    }

    // MARK: - Display Symbols

    private static let modifierOrder: [(flag: UIKeyModifierFlags, symbol: String)] = [
        (.control, "⌃"),
        (.alternate, "⌥"),
        (.shift, "⇧"),
        (.command, "⌘"),
    ]

    private struct KeyMapping {
        let symbol: String
        let name: String
    }

    private static let keyMappings: [String: KeyMapping] = [
        UIKeyCommand.inputUpArrow: KeyMapping(symbol: "↑", name: "Up Arrow"),
        UIKeyCommand.inputDownArrow: KeyMapping(symbol: "↓", name: "Down Arrow"),
        UIKeyCommand.inputLeftArrow: KeyMapping(symbol: "←", name: "Left Arrow"),
        UIKeyCommand.inputRightArrow: KeyMapping(symbol: "→", name: "Right Arrow"),
        UIKeyCommand.inputEscape: KeyMapping(symbol: "esc", name: "Escape"),
        "\r": KeyMapping(symbol: "↩", name: "Return"),
        "\n": KeyMapping(symbol: "↩", name: "Return"),
        "\t": KeyMapping(symbol: "⇥", name: "Tab"),
        " ": KeyMapping(symbol: "Space", name: "Space"),
        "\u{8}": KeyMapping(symbol: "⌫", name: "Delete"),
        "\u{7F}": KeyMapping(symbol: "⌫", name: "Delete"),
    ]

    /// Returns individual modifier symbols as an array (e.g., ["⌃", "⌘"]).
    public var modifierSymbols: [String] {
        Self.modifierOrder
            .filter { modifierFlags.contains($0.flag) }
            .map { $0.symbol }
    }

    /// Returns a human-readable string representation of the shortcut (e.g., "⌘N").
    public var displayString: String {
        modifierSymbols.joined() + keySymbol
    }

    private var keyMapping: KeyMapping? {
        if let mapping = Self.keyMappings[input] {
            return mapping
        }
        if #available(iOS 15.0, *), input == UIKeyCommand.inputDelete {
            return KeyMapping(symbol: "⌫", name: "Delete")
        }
        return nil
    }

    /// Returns the key symbol for display in keycaps (e.g., "⎋" for Escape).
    public var keySymbol: String {
        keyMapping?.symbol ?? input.uppercased()
    }

    /// Returns a human-readable name for the key (e.g., "Escape" instead of "⎋").
    public var keyName: String {
        keyMapping?.name ?? input.uppercased()
    }

    /// Returns the best available description for the shortcut.
    public var displayTitle: String {
        discoverabilityTitle ?? title ?? keyName
    }
}

// MARK: - KeyboardShortcutParser

/// Parses UIKeyCommands from a view's responder chain or a UIMenu.
public enum KeyboardShortcutParser {
    // MARK: - Parsing from UIMenu

    /// Parses keyboard shortcuts from a UIMenu structure.
    ///
    /// This is the preferred way to get categorized shortcuts. The menu structure
    /// provides natural grouping of shortcuts into categories based on submenu titles.
    ///
    /// - Parameter menu: The UIMenu containing keyboard shortcuts organized by category.
    /// - Returns: An array of KeyboardShortcut objects with category information.
    public static func parseKeyCommands(from menu: UIMenu) -> [KeyboardShortcut] {
        extractShortcuts(from: menu, categoryTitle: nil)
    }

    /// Recursively extracts shortcuts from a UIMenu hierarchy.
    private static func extractShortcuts(from menu: UIMenu, categoryTitle: String?) -> [KeyboardShortcut] {
        var shortcuts: [KeyboardShortcut] = []

        // Determine the category for children of this menu
        let currentCategory: String?
        if !menu.title.isEmpty {
            currentCategory = menu.title
        } else {
            currentCategory = categoryTitle
        }

        for child in menu.children {
            if let keyCommand = child as? UIKeyCommand,
               let input = keyCommand.input, !input.isEmpty
            {
                shortcuts.append(KeyboardShortcut(from: keyCommand, menuTitle: currentCategory))
            } else if let submenu = child as? UIMenu {
                shortcuts.append(contentsOf: extractShortcuts(from: submenu, categoryTitle: currentCategory))
            }
        }

        return shortcuts
    }

    // MARK: - Parsing from Responder Chain

    /// Parses keyboard shortcuts from the responder chain starting at the given view.
    ///
    /// This method traverses the responder chain from the view upward, collecting
    /// UIKeyCommands from each responder. Use this for simple cases without categories.
    ///
    /// - Parameter view: The view from which to start parsing.
    /// - Returns: An array of KeyboardShortcut objects (without category information).
    public static func parseKeyCommands(from view: UIView) -> [KeyboardShortcut] {
        sequence(first: view as UIResponder?, next: { $0?.next })
            .compactMap { $0?.keyCommands }
            .flatMap { $0 }
            .filter { $0.input?.isEmpty == false }
            .map { KeyboardShortcut(from: $0, menuTitle: nil) }
    }

    /// Parses keyboard shortcuts from a view controller's responder chain.
    ///
    /// - Parameter viewController: The view controller from which to parse shortcuts.
    /// - Returns: An array of KeyboardShortcut objects.
    public static func parseKeyCommands(from viewController: UIViewController) -> [KeyboardShortcut] {
        parseKeyCommands(from: viewController.view)
    }
}

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

/// Protocol for view controllers that provide keyboard shortcuts for the menu bar.
protocol KeyboardShortcutProvider: AnyObject {
    /// The menu insertions to add to the system menu bar when this screen is active.
    var menuBarInsertions: [MenuController.MenuInsertion] { get }
}

/// Handles dynamic menu construction for the app.
///
/// View controllers conforming to `KeyboardShortcutProvider` can register their
/// keyboard shortcuts, which will appear in the menu bar when that screen is active.
final class MenuController {
    /// Configuration for how to insert a menu into the system menu bar.
    struct MenuInsertion {
        enum Position {
            /// Insert as inline children at the start of an existing system menu.
            case inlineAtStart(of: UIMenu.Identifier)
            /// Insert as inline children at the end of an existing system menu.
            case inlineAtEnd(of: UIMenu.Identifier)
            /// Insert as a new sibling menu before an existing menu.
            case siblingBefore(UIMenu.Identifier)
        }

        let menu: UIMenu
        let position: Position
    }

    // MARK: - Shared Instance

    static let shared = MenuController()

    // MARK: - Private Properties

    private weak var currentProvider: KeyboardShortcutProvider?

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    func register(provider: KeyboardShortcutProvider) {
        currentProvider = provider
        UIMenuSystem.main.setNeedsRebuild()
    }

    func unregister(provider: KeyboardShortcutProvider) {
        // Only unregister if this is the current provider
        if currentProvider === provider {
            currentProvider = nil
            UIMenuSystem.main.setNeedsRebuild()
        }
    }

    func buildMenu(with builder: UIMenuBuilder) {
        guard builder.system == .main else { return }

        guard let insertions = currentProvider?.menuBarInsertions else { return }

        for insertion in insertions {
            switch insertion.position {
            case let .inlineAtStart(of: targetMenu):
                let inlineMenu = UIMenu(title: "", options: .displayInline, children: insertion.menu.children)
                builder.insertChild(inlineMenu, atStartOfMenu: targetMenu)

            case let .inlineAtEnd(of: targetMenu):
                let inlineMenu = UIMenu(title: "", options: .displayInline, children: insertion.menu.children)
                builder.insertChild(inlineMenu, atEndOfMenu: targetMenu)

            case let .siblingBefore(targetMenu):
                builder.insertSibling(insertion.menu, beforeMenu: targetMenu)
            }
        }
    }
}

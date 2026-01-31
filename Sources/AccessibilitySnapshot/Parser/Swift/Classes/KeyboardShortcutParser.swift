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
        discoverabilityTitle = keyCommand.discoverabilityTitle?.isEmpty == true ? nil : keyCommand.discoverabilityTitle
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

    /// Returns the key symbol for display in keycaps (e.g., "⌘" for Command).
    public var keySymbol: String {
        SpecialKey(input: input)?.symbol ?? input.uppercased()
    }

    /// Returns a human-readable name for the key (e.g., "Up Arrow" instead of "↑").
    public var keyName: String {
        SpecialKey(input: input)?.name ?? input.uppercased()
    }

    /// Returns the best available description for the shortcut.
    public var displayTitle: String {
        discoverabilityTitle ?? title ?? keyName
    }
}

// MARK: - SpecialKey

/// Represents special keyboard keys with their display symbol and human-readable name.
enum SpecialKey {
    case upArrow
    case downArrow
    case leftArrow
    case rightArrow
    case escape
    case `return`
    case tab
    case space
    case delete

    // MARK: - Initialization

    init?(input: String) {
        switch input {
        case UIKeyCommand.inputUpArrow:
            self = .upArrow
        case UIKeyCommand.inputDownArrow:
            self = .downArrow
        case UIKeyCommand.inputLeftArrow:
            self = .leftArrow
        case UIKeyCommand.inputRightArrow:
            self = .rightArrow
        case UIKeyCommand.inputEscape:
            self = .escape
        case "\r", "\n":
            self = .return
        case "\t":
            self = .tab
        case " ":
            self = .space
        case "\u{8}", "\u{7F}":
            self = .delete
        default:
            if #available(iOS 15.0, *), input == UIKeyCommand.inputDelete {
                self = .delete
                return
            }
            return nil
        }
    }

    // MARK: - Properties

    var symbol: String {
        switch self {
        case .upArrow: return "↑"
        case .downArrow: return "↓"
        case .leftArrow: return "←"
        case .rightArrow: return "→"
        case .escape: return "esc"
        case .return: return "↩"
        case .tab: return "⇥"
        case .space: return "Space"
        case .delete: return "⌫"
        }
    }

    var name: String {
        switch self {
        case .upArrow: return "Up Arrow"
        case .downArrow: return "Down Arrow"
        case .leftArrow: return "Left Arrow"
        case .rightArrow: return "Right Arrow"
        case .escape: return "Escape"
        case .return: return "Return"
        case .tab: return "Tab"
        case .space: return "Space"
        case .delete: return "Delete"
        }
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

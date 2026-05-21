import AccessibilitySnapshotModel
import UIKit

// MARK: - UIAccessibilityTraits Codable

#if compiler(>=6.0)
    extension UIAccessibilityTraits: @retroactive Codable {}
#else
    extension UIAccessibilityTraits: Codable {}
#endif

public extension UIAccessibilityTraits {
    private static let knownTraits: [(trait: UIAccessibilityTraits, name: String)] = [
        (.button, "button"),
        (.link, "link"),
        (.image, "image"),
        (.selected, "selected"),
        (.playsSound, "playsSound"),
        (.keyboardKey, "keyboardKey"),
        (.staticText, "staticText"),
        (.summaryElement, "summaryElement"),
        (.notEnabled, "notEnabled"),
        (.updatesFrequently, "updatesFrequently"),
        (.searchField, "searchField"),
        (.startsMediaSession, "startsMediaSession"),
        (.adjustable, "adjustable"),
        (.allowsDirectInteraction, "allowsDirectInteraction"),
        (.causesPageTurn, "causesPageTurn"),
        (.header, "header"),
        (.tabBar, "tabBar"),
        (.textEntry, "textEntry"),
        (.isEditing, "isEditing"),
        (.secureTextField, "secureTextField"),
        (.backButton, "backButton"),
        (.tabBarItem, "tabBarItem"),
        (.textArea, "textArea"),
        (.switchButton, "switchButton"),
        (.alert, "alert"),
    ]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let traitNames = try container.decode([String].self)

        var traits = UIAccessibilityTraits()
        var unknownValues: UInt64 = 0

        for name in traitNames {
            if let known = Self.knownTraits.first(where: { $0.name == name }) {
                traits.insert(known.trait)
            } else if name.hasPrefix("unknown("), name.hasSuffix(")") {
                let startIndex = name.index(name.startIndex, offsetBy: 8)
                let endIndex = name.index(name.endIndex, offsetBy: -1)
                if let rawValue = UInt64(name[startIndex ..< endIndex]) {
                    unknownValues |= rawValue
                }
            }
        }

        self = UIAccessibilityTraits(rawValue: traits.rawValue | unknownValues)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        var traitNames: [String] = []
        var remainingRawValue = rawValue

        for (trait, name) in Self.knownTraits {
            if contains(trait) {
                traitNames.append(name)
                remainingRawValue &= ~trait.rawValue
            }
        }

        if remainingRawValue != 0 {
            traitNames.append("unknown(\(remainingRawValue))")
        }

        try container.encode(traitNames)
    }
}

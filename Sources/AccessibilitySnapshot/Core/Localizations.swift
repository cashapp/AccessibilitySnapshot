//
//  Localizations.swift
//  AccessibilitySnapshot
//
//  Created by Soroush Khanlou on 7/1/25.
//

#if SWIFT_PACKAGE
import AccessibilitySnapshotParser
#endif

enum Strings {

    static func actionsAvailableText(for locale: String?) -> String {
        return "Actions Available".as_localized(
            key: "custom_actions.description",
            comment: "Description for an accessibility element indicating that it has custom actions available",
            locale: locale
        )
    }

    static func moreContentAvailableText(for locale: String?) -> String {
        return "More Content Available".as_localized(
            key: "custom_content.description",
            comment: "Description for an accessibility element indicating that it has additional custom content available",
            locale: locale
        )
    }
    
    static func rotorsAvailableText(rotorNames: [String], for locale: String?) -> String {
        String(format: rotorsFormatString(for: locale), rotorNames.joined(separator: ", "))
    }
    
    private static func rotorsFormatString(for locale: String?) -> String {
        return "Use the rotor to access: %@".as_localized(
            key: "custom_Rotors.format",
            comment: "Format string for an accessibility element indicating that it has custom rotors available, the placeholder is a string representing the available rotors names.",
            locale: locale
        )
    }
    
    static func noResultsText(for locale: String?) -> String {
        return "<no results>".as_localized(
            key: "custom_rotors.no_results",
            comment: "Description for an accessibility rotor indicating that it has no results available",
            locale: locale
        )
    }
}

extension String {

    func as_localized(key: String, comment: String, locale: String?, file: StaticString = #file) -> String {
        let bundle = StringLocalization.preferredBundle(for: locale)

        return bundle.localizedString(forKey: key, value: self, table: nil)
    }

}

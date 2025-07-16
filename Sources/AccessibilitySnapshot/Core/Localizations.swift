//
//  Localizations.swift
//  AccessibilitySnapshot
//
//  Created by Soroush Khanlou on 7/1/25.
//

import AccessibilitySnapshotParser

enum Strings {

    static func actionsAvailableText(for locale: String?) -> String {
        return "Actions Available".localized(
            key: "custom_actions.description",
            comment: "Description for an accessibility element indicating that it has custom actions available",
            locale: locale
        )
    }

    static func moreContentAvailableText(for locale: String?) -> String {
        return "More Content Available".localized(
            key: "custom_content.description",
            comment: "Description for an accessibility element indicating that it has additional custom content available",
            locale: locale
        )
    }
}

extension String {

    func localized(key: String, comment: String, locale: String?, file: StaticString = #file) -> String {
        let bundle = StringLocalization.preferredBundle(for: locale)

        return bundle.localizedString(forKey: key, value: self, table: nil)
    }

}

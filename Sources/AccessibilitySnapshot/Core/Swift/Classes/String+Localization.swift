//
//  Copyright 2019 Square Inc.
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

import Foundation

extension String {

    func localized(key: String, comment: String, locale: String?, file: StaticString = #file) -> String {
        let bundle = StringLocalization.preferredBundle(for: locale)

        return bundle.localizedString(forKey: key, value: self, table: nil)
    }

}

// MARK: -

private enum StringLocalization {

    // MARK: - Private Static Properties

    private static var localeToBundleMap: [String: Bundle] = [:]

    private static let resourceBundle: Bundle = {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        let frameworkBundle = Bundle(for: AccessibilityHierarchyParser.self)

        guard let resourceBundlePath = frameworkBundle.path(forResource: "AccessibilitySnapshot", ofType: "bundle") else {
            fatalError("Resource bundle not found for AccessibilitySnapshot framework.")
        }

        guard let resourceBundle = Bundle(path: resourceBundlePath) else {
            fatalError("Failed to load resource bundle for AccessibilitySnapshot framework.")
        }

        return resourceBundle
        #endif
    }()

    // MARK: - Public Static Methods

    static func preferredBundle(for locale: String?) -> Bundle {
        guard let locale = locale else {
            return resourceBundle
        }

        if let cachedBundle = localeToBundleMap[locale] {
            return cachedBundle
        }

        guard let availableLocalizationBundles = resourceBundle.urls(forResourcesWithExtension: "lproj", subdirectory: nil) else {
            return resourceBundle
        }

        // Try to find an lproj for the exact locale.
        if let bundleURL = availableLocalizationBundles.first(where: { $0.lastPathComponent == "\(locale).lproj" }), let bundle = Bundle(url: bundleURL) {
            localeToBundleMap[locale] = bundle
            return bundle
        }

        // If the locale specifies a region, try to find an lproj for the same language.
        let language = locale.prefix(2)
        if let bundleURL = availableLocalizationBundles.first(where: { $0.lastPathComponent.prefix(2) == language }), let bundle = Bundle(url: bundleURL) {
            localeToBundleMap[locale] = bundle
            return bundle
        }

        return resourceBundle
    }

}

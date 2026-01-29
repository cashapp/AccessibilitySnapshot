import Foundation

extension String {
    func localized(key: String, comment: String, locale: String?, file: StaticString = #file) -> String {
        let bundle = StringLocalization.preferredBundle(for: locale)

        return bundle.localizedString(forKey: key, value: self, table: nil)
    }
}

// MARK: -

public extension Bundle {
    static var accessibilitySnapshotResources: Bundle = .module
}

// MARK: -

public enum StringLocalization {
    // MARK: - Private Static Properties

    private static var localeToBundleMap: [String: Bundle] = [:]

    private static let resourceBundle: Bundle = .module

    // MARK: - Public Static Methods

    public static func preferredBundle(for locale: String?) -> Bundle {
        guard let locale = locale else {
            return resourceBundle
        }

        if let cachedBundle = localeToBundleMap[locale] {
            return cachedBundle
        }

        guard let availableLocalizationBundles = resourceBundle.urls(forResourcesWithExtension: "lproj", subdirectory: "Assets") else {
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

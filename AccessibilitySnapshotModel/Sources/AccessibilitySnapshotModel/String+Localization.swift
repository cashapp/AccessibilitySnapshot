import Foundation

extension String {
    func localized(key: String, comment: String, locale: String?, file: StaticString = #file) -> String {
        StringLocalization.preferredBundle(for: locale).localizedString(forKey: key, value: self, table: nil)
    }
}

public enum StringLocalization {
    #if SWIFT_PACKAGE
        private static let resourceBundle = Bundle.module
    #else
        private static let resourceBundle = Bundle(for: ModelResources.self)
    #endif

    private static let availableLocalizationBundles =
        (resourceBundle.urls(forResourcesWithExtension: "lproj", subdirectory: "Assets") ?? [])
            + (resourceBundle.urls(forResourcesWithExtension: "lproj", subdirectory: nil) ?? [])

    public static func preferredBundle(for locale: String?) -> Bundle {
        guard let locale else {
            return resourceBundle
        }

        if let bundleURL = availableLocalizationBundles.first(where: { $0.lastPathComponent == "\(locale).lproj" }),
           let bundle = Bundle(url: bundleURL)
        {
            return bundle
        }

        let language = locale.prefix(2)
        if let bundleURL = availableLocalizationBundles.first(where: { $0.lastPathComponent.prefix(2) == language }),
           let bundle = Bundle(url: bundleURL)
        {
            return bundle
        }

        return resourceBundle
    }
}

private final class ModelResources {}

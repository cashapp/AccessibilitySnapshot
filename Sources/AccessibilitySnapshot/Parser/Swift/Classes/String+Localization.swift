import AccessibilitySnapshotModel

extension String {
    func localized(key: String, comment: String, locale: String?, file: StaticString = #file) -> String {
        let bundle = StringLocalization.preferredBundle(for: locale)
        return bundle.localizedString(forKey: key, value: self, table: nil)
    }
}

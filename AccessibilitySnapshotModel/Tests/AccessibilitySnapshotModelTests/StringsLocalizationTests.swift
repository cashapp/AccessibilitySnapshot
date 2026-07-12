@testable import AccessibilitySnapshotModel
import XCTest

/// Proves the localized `.lproj` resources bundled with the model target actually resolve at
/// runtime — not just that the code compiles. The German values differ from the English fallback,
/// so a passing `de` assertion means `Bundle.module`'s `.lproj` sub-bundle discovery worked
/// (the corelibs-foundation risk we accepted when moving localization into the agnostic model).
final class StringsLocalizationTests: XCTestCase {
    func testEnglishLocaleResolvesBundledStrings() {
        let strings = Strings(locale: "en")
        XCTAssertEqual(strings.buttonTraitName, "Button.")
        XCTAssertEqual(strings.headerTraitName, "Heading.")
        XCTAssertEqual(strings.listStartContext, "List Start.")
    }

    func testGermanLocaleResolvesLprojNotFallback() {
        let strings = Strings(locale: "de")
        // If .lproj discovery failed, these would fall back to the English default values.
        XCTAssertEqual(strings.buttonTraitName, "Taste.")
        XCTAssertEqual(strings.headerTraitName, "Überschrift.")
        XCTAssertEqual(strings.listStartContext, "Anfang der Liste.")
    }

    func testNilLocaleUsesDefaultBundle() {
        let strings = Strings(locale: nil)
        XCTAssertEqual(strings.buttonTraitName, "Button.")
    }
}

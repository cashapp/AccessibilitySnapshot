@testable import AccessibilitySnapshotModel
import XCTest

/// Pins the model-side description assembly ported from the parse-time path. `.verbose` must
/// reproduce the historical strings; the verbosity flags must gate each section; `traitPosition`
/// must mirror iOS 18.4's Controls verbosity (Speak Before / After / Don't Speak).
final class DescriptionAssemblyTests: XCTestCase {
    private func element(
        label: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = [],
        hint: String? = nil,
        customContent: [AccessibilityElement.CustomContent] = []
    ) -> AccessibilityElement {
        AccessibilityElement(
            description: "",
            label: label,
            value: value,
            traits: traits,
            identifier: nil,
            hint: hint,
            userInputLabels: nil,
            shape: .frame(.zero),
            activationPoint: .zero,
            usesDefaultActivationPoint: true,
            customActions: [],
            customContent: customContent,
            customRotors: [],
            accessibilityLanguage: nil,
            respondsToUserInteraction: true
        )
    }

    // MARK: - Trait position mirrors iOS Controls verbosity

    func testTraitPositionAfterIsHistoricalDefault() {
        let button = element(label: "Submit", traits: .button)
        XCTAssertEqual(button.description(context: nil).description, "Submit. Button.")
    }

    func testTraitPositionBeforeSpeaksTraitFirst() {
        var verbosity = VerbosityConfiguration.verbose
        verbosity.traitPosition = .before
        let button = element(label: "Submit", traits: .button)
        XCTAssertEqual(button.description(context: nil, verbosity: verbosity).description, "Button. Submit")
    }

    func testTraitPositionNoneOmitsTrait() {
        var verbosity = VerbosityConfiguration.verbose
        verbosity.traitPosition = .none
        let button = element(label: "Submit", traits: .button)
        XCTAssertEqual(button.description(context: nil, verbosity: verbosity).description, "Submit")
    }

    // MARK: - Verbosity gating

    func testMinimalIsLabelOnly() {
        let button = element(label: "Submit", value: "ready", traits: [.button, .header])
        XCTAssertEqual(button.description(context: nil, verbosity: .minimal).description, "Submit")
    }

    func testValueAppendedWithColonWhenVerbose() {
        let slider = element(label: "Volume", value: "50%")
        XCTAssertEqual(slider.description(context: nil).description, "Volume: 50%")
    }

    func testIncludesValueFalseDropsValue() {
        var verbosity = VerbosityConfiguration.verbose
        verbosity.includesValue = false
        let slider = element(label: "Volume", value: "50%")
        XCTAssertEqual(slider.description(context: nil, verbosity: verbosity).description, "Volume")
    }

    // MARK: - Container context

    func testSeriesContext() {
        let item = element(label: "Photo")
        // seriesContextFormat is "%@ %@ of %@." — no period between the label and the count.
        XCTAssertEqual(item.description(context: .series(index: 2, count: 5)).description, "Photo 2 of 5.")
    }

    func testListStartContext() {
        let item = element(label: "First")
        XCTAssertEqual(item.description(context: .listStart).description, "First. List Start.")
    }

    func testContainerContextGatedOff() {
        var verbosity = VerbosityConfiguration.verbose
        verbosity.includesContainerContext = false
        let item = element(label: "Photo")
        XCTAssertEqual(item.description(context: .series(index: 2, count: 5), verbosity: verbosity).description, "Photo")
    }

    // MARK: - Hints

    func testHintPassthroughAndGating() {
        let el = element(label: "Save", hint: "Saves your work")
        XCTAssertEqual(el.description(context: nil).hint, "Saves your work")

        var verbosity = VerbosityConfiguration.verbose
        verbosity.includesHints = false
        XCTAssertNil(el.description(context: nil, verbosity: verbosity).hint)
    }

    // MARK: - Hint decomposition: user fact vs state utterances vs spoken merge

    func testSwitchStateHintWrapsUserHint() {
        let sw = element(label: "Wi-Fi", value: "1", traits: [.button, .switchButton], hint: "Toggles Wi-Fi.")
        XCTAssertEqual(sw.hint, "Toggles Wi-Fi.")
        XCTAssertEqual(sw.stateHint(), "Double tap to toggle setting.")
        XCTAssertEqual(sw.description(context: nil).hint, "Toggles Wi-Fi. Double tap to toggle setting.")
    }

    func testTextEntryStateHintReplacesUserHint() {
        let field = element(label: "Email", traits: .textEntry, hint: "Enter your email.")
        XCTAssertEqual(field.hint, "Enter your email.")
        XCTAssertEqual(field.stateHint(), "Double tap to edit.")
        XCTAssertEqual(field.description(context: nil).hint, "Double tap to edit.")
    }

    func testAdjustableStateHintChainsOntoTextEntry() {
        let stepper = element(label: "Quantity", value: "3", traits: [.textEntry, .adjustable], hint: "Sets quantity.")
        let chained = "Double tap to edit. Swipe up or down with one finger to adjust the value."
        XCTAssertEqual(stepper.stateHint(), chained)
        XCTAssertEqual(stepper.description(context: nil).hint, chained)
    }

    func testStateHintNilForPlainElement() {
        let button = element(label: "Save", traits: .button, hint: "Saves your work")
        XCTAssertNil(button.stateHint())
        XCTAssertEqual(button.description(context: nil).hint, "Saves your work")
    }
}

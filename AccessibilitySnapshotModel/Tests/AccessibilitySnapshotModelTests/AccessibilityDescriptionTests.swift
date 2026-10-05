import AccessibilitySnapshotModel
import Foundation
import XCTest

final class AccessibilityDescriptionTests: XCTestCase {
    func testComputeSpeechFromCapturedFields() throws {
        let element = AccessibilityElement(
            label: "Volume", value: "50%", traits: [.selected, .adjustable], identifier: nil,
            hint: "Change volume.", userInputLabels: nil, shape: .frame(.zero),
            activationPoint: .zero, usesDefaultActivationPoint: true,
            customActions: [], customContent: [], customRotors: [],
            accessibilityLanguage: "en-US", respondsToUserInteraction: true,
            context: .series(index: 2, count: 3)
        )
        XCTAssertEqual(element.description, "Selected: Volume: 50%. Adjustable. 2 of 3.")
        XCTAssertEqual(element.hint, "Change volume. Swipe up or down with one finger to adjust the value.")

        let data = try JSONEncoder().encode(element)
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertNil(payload["description"])
        XCTAssertNil(payload["hint"])
        let decoded = try JSONDecoder().decode(AccessibilityElement.self, from: data)
        XCTAssertEqual(decoded, element)
        XCTAssertEqual(decoded.description, element.description)
        XCTAssertEqual(decoded.hint, element.hint)
    }

    func testComputeLocalizedTraitsAndContainerContext() {
        for (language, expected) in [
            ("en-US", "Item. Tab. 2 of 3."),
            ("de-DE", "Item. Tabulator. 2 von 3."),
            ("ru-RU", "Item. Вкладка. 2 из 3."),
        ] {
            let speech = AccessibilityElement.accessibilityDescription(
                label: "Item", value: nil, traits: .button, authoredHint: nil,
                accessibilityLanguage: language, context: .tab(index: 2, count: 3)
            )
            XCTAssertEqual(speech.description, expected)
            XCTAssertNil(speech.hint)
        }
    }

    func testComputeHintsAndHintOnlyDescriptions() {
        for (label, value, traits, authoredHint, expectedDescription, expectedHint) in [
            (nil as String?, nil as String?, AccessibilityTraits.adjustable, "Change volume." as String?, "Change volume. Adjustable.", nil as String?),
            ("Setting", "1", [.button, .switchButton], "Change setting.", "Setting. Switch Button. On.", "Change setting. Double tap to toggle setting."),
            ("Setting", "0", [.button, .switchButton, .notEnabled], "Change setting.", "Setting. Dimmed. Switch Button. Off.", "Change setting."),
            ("Password", nil, [.textEntry, .secureTextField], "Authored hint", "Password. Secure Text Field.", "Double tap to edit."),
            ("Back", nil, [.button, .backButton], nil, "Back Button.", nil),
        ] {
            let speech = AccessibilityElement.accessibilityDescription(
                label: label, value: value, traits: traits, authoredHint: authoredHint,
                accessibilityLanguage: "en-US", context: nil
            )
            XCTAssertEqual(speech.description, expectedDescription)
            XCTAssertEqual(speech.hint, expectedHint)
        }
    }

    func testComputeTableHeadersCoordinatesAndSpans() {
        let speech = AccessibilityElement.accessibilityDescription(
            label: "Cell", value: "42", traits: [], authoredHint: nil,
            accessibilityLanguage: "en-US",
            context: .dataTableCell(
                row: 2, column: 3, width: 2, height: 3, isFirstInRow: true,
                rowHeaders: [.init(label: "Quarter", value: "Q1")],
                columnHeaders: [.init(label: "Revenue", value: nil)]
            )
        )
        XCTAssertEqual(speech.description, "Quarter: Q1. Revenue. Cell. Spans 3 rows. Spans 2 columns. Row 3. Column 4. 42")
        XCTAssertNil(speech.hint)
    }
}

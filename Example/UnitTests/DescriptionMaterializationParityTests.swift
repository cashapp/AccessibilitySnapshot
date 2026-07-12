@testable import AccessibilitySnapshotCore
import AccessibilitySnapshotModel
@testable import AccessibilitySnapshotParser
import UIKit
import XCTest

/// Byte-identity gate for the 4c cutover: the materializing flatten
/// (`flattenToElements(verbosity: .verbose)`) must reproduce the historical VoiceOver-style
/// description and hint for every element, string-for-string, now that the parser stores only raw
/// facts (raw hint, un-contextualized) and the final spoken string is composed at delivery.
///
/// The historical string is the parser's own `accessibilityDescription(context:)` composer — the
/// exact function that used to bake the description at parse time — run per source object. Comparing
/// the materialized tree against it localizes any divergence to a specific element rather than a
/// pixel diff.
final class DescriptionMaterializationParityTests: XCTestCase {
    /// Asserts the materialized (description, hint) for every accessibility element under `rootView`
    /// equals what the historical parse-time composer produced for that same object.
    ///
    /// These fixtures deliberately use no container that lends context, so each element's historical
    /// string is `accessibilityDescription(context: nil)` — letting us compare without threading the
    /// source object through `flattenToElements`.
    private func assertParity(
        _ expected: [(object: NSObject, root: UIView)],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let root = expected.first?.root else { return XCTFail("no elements", file: file, line: line) }
        let parser = AccessibilityHierarchyParser()
        let materialized = parser
            .parseAccessibilityHierarchy(in: root)
            .flattenToElements(verbosity: .verbose)
            .map { ($0.description, $0.hint) }

        let historical = expected.map { $0.object.accessibilityDescription(context: nil) }

        XCTAssertEqual(
            materialized.map(\.0), historical.map(\.description),
            "descriptions diverged", file: file, line: line
        )
        XCTAssertEqual(
            materialized.map(\.1), historical.map(\.hint),
            "hints diverged", file: file, line: line
        )
    }

    /// Hosts `root` in a key window and lays it out so controls (slider/segmented) actually vend their
    /// accessibility elements — a detached view returns none.
    private func host(_ root: UIView) {
        let window = UIWindow(frame: root.frame)
        window.addSubview(root)
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
    }

    // MARK: - Series (segmented control)

    func testSegmentedControlParity() {
        // A segmented control DOES lend context; assert the materialized strings carry the series
        // position. Byte-identity against the historical path is covered by the snapshot suite
        // (context-bearing fixtures can't use the context-free `assertParity` helper).
        let root = UIView(frame: .init(x: 0, y: 0, width: 300, height: 100))
        let segmented = UISegmentedControl(items: ["One", "Two", "Three"])
        segmented.frame = .init(x: 0, y: 0, width: 300, height: 40)
        segmented.selectedSegmentIndex = 1
        root.addSubview(segmented)
        host(root)

        let parser = AccessibilityHierarchyParser()
        let elements = parser.parseAccessibilityHierarchy(in: root)
            .flattenToElements(verbosity: .verbose)
        XCTAssertEqual(elements.count, 3)
        XCTAssertTrue(elements.allSatisfy { $0.description.contains("of 3") }, "\(elements.map(\.description))")
    }

    // MARK: - Text entry (UIKit)

    func testUIKitTextFieldParity() {
        let root = UIView(frame: .init(x: 0, y: 0, width: 300, height: 100))
        let field = UITextField(frame: .init(x: 0, y: 0, width: 300, height: 40))
        field.text = "Bailey"
        field.placeholder = "Name"
        root.addSubview(field)
        assertParity([(field, root)])
    }

    // MARK: - Switch

    func testSwitchParity() {
        let root = UIView(frame: .init(x: 0, y: 0, width: 200, height: 100))
        let toggle = UISwitch(frame: .init(x: 0, y: 0, width: 60, height: 40))
        toggle.isOn = true
        toggle.accessibilityLabel = "Wi-Fi"
        root.addSubview(toggle)
        assertParity([(toggle, root)])
    }

    // MARK: - Slider (adjustable)

    func testSliderParity() {
        let root = UIView(frame: .init(x: 0, y: 0, width: 200, height: 100))
        let slider = UISlider(frame: .init(x: 0, y: 0, width: 200, height: 40))
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.value = 50
        slider.accessibilityLabel = "Volume"
        root.addSubview(slider)
        host(root)
        assertParity([(slider, root)])
    }

    // MARK: - Plain elements (no container -> nil context)

    func testPlainElementsParity() {
        let root = UIView(frame: .init(x: 0, y: 0, width: 200, height: 200))
        let button = UIButton(type: .system)
        button.setTitle("Submit", for: .normal)
        button.frame = .init(x: 0, y: 0, width: 100, height: 44)
        root.addSubview(button)

        let label = UILabel(frame: .init(x: 0, y: 60, width: 200, height: 20))
        label.text = "A plain label"
        label.isAccessibilityElement = true
        root.addSubview(label)

        // Elements sort in traversal order (button before label).
        assertParity([(button, root), (label, root)])
    }
}

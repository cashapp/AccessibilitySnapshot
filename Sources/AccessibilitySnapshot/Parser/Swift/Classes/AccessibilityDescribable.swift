import UIKit

// MARK: - Protocol

/// Internal protocol for types that can generate VoiceOver-style descriptions.
///
/// This protocol unifies description generation for both live UIKit objects (NSObject)
/// and parsed accessibility elements (AccessibilityElement), enabling shared logic
/// for computing what VoiceOver would announce.
///
/// ## Description Compilation Order
///
/// The description is built in this exact order to match VoiceOver behavior:
///
/// ```
/// 1. INITIALIZE BASE DESCRIPTION
///    - accessibilityLabelOverride(for: context) -> if non-nil, use it
///    - OR if hidesAccessibilityLabel() -> ""
///    - OR accessibilityLabel ?? ""
///
/// 2. INITIALIZE HINT
///    - accessibilityHint?.nonEmpty()
///
/// 3. DATA TABLE CONTEXT (if .dataTableCell)
///    - PREPEND: row headers + column headers (pre-formatted strings)
///    - description + trailing period
///    - APPEND: "Spans X rows." (if rowSpan > 1)
///    - APPEND: "Spans X columns." (if columnSpan > 1)
///    - APPEND: "Row X." (if isFirstInRow)
///    - APPEND: "Column X."
///    [Sets descriptionContainsContext = true]
///
/// 4. APPEND VALUE
///    - if accessibilityValue non-empty && !hidesAccessibilityValue:
///      - If descriptionContainsContext: " {value}"
///      - If has description: "{desc}: {value}"
///      - If no description: "{value}"
///
/// 4.5. APPEND HIGH-IMPORTANCE CUSTOM CONTENT
///    - for each content where isImportant == true:
///      - "{description}, {value}"
///      - OR "{description}, {label}" (if value is empty)
///
/// 5. SELECTED TRAIT
///    - if .selected:
///      - "Selected: {description}"
///      - OR "Selected." (if no description)
///
/// 6. BUILD TRAIT SPECIFIERS ARRAY (in this exact order)
///    - .notEnabled        -> "Dimmed."
///    - .button            -> "Button." (unless hidden by context/traits)
///    - .backButton        -> "Back Button."
///    - .switchButton      -> "Switch Button." + "On."/"Off."/"Mixed."/value
///    - .tabBarItem OR ctx -> "Tab."
///    - .textEntry         -> "Text Field." + "Is editing." (if editing)
///    - .header            -> "Heading."
///    - .link              -> "Link."
///    - .adjustable        -> "Adjustable."
///    - .image             -> "Image."
///    - .searchField       -> "Search Field."
///
/// 7. HINT AS DESCRIPTION FALLBACK
///    - if description is empty:
///      - description = hint
///      - hint = nil
///
/// 8. APPEND TRAIT SPECIFIERS
///    - if traitSpecifiers not empty:
///      - "{description}. {traits joined by space}"
///      - OR just traits if no description
///
/// 9. SERIES/TAB/LIST/LANDMARK CONTEXT
///    - .series/.tabBarItem/.tab  -> "{desc} X of Y."
///    - .listStart                -> "{desc}. List Start."
///    - .listEnd                  -> "{desc}. List End."
///    - .landmarkStart            -> "{desc}. Landmark."
///    - .landmarkEnd              -> "{desc}. End."
///
/// 10. MODIFY HINT FOR SWITCH BUTTON
///     - if .switchButton && enabled:
///       - "{hint}. Double tap to toggle setting."
///       - OR "Double tap to toggle setting."
///
/// 11. MODIFY HINT FOR TEXT ENTRY
///     - if .textEntry && enabled:
///       - If editing: "Use the rotor to access Misspelled Words"
///       - If scrollable: "Double tap to edit., Use the rotor..."
///       - Else: "Double tap to edit."
///
/// 12. MODIFY HINT FOR ADJUSTABLE
///     - if .adjustable && !hidesAdjustableHint:
///       - "{hint}. Swipe up or down with one finger to adjust the value."
///       - OR "Swipe up or down with one finger to adjust the value."
///
/// 13. RETURN (description, hint)
/// ```
protocol AccessibilityDescribable {
    var accessibilityLabel: String? { get }
    var accessibilityValue: String? { get }
    var accessibilityTraits: UIAccessibilityTraits { get }
    var accessibilityHint: String? { get }
    var accessibilityLanguage: String? { get }

    /// Custom content items for this element.
    /// High-importance items are included in the main description.
    var describableCustomContent: [AccessibilityElement.CustomContent] { get }
}

// MARK: - Default Implementation

extension AccessibilityDescribable {
    /// Generates the description and hint that VoiceOver would read for this element.
    ///
    /// - Parameter context: The context provided by the element's container, if any.
    /// - Returns: A tuple containing the description and optional hint.
    func buildAccessibilityDescription(
        context: AccessibilityElement.ContainerContext?
    ) -> (description: String, hint: String?) {
        let strings = Strings(locale: accessibilityLanguage)

        var accessibilityDescription =
            accessibilityLabelOverride(for: context) ??
            (hidesAccessibilityLabel(backDescriptor: strings.backDescriptor) ? "" :
                accessibilityLabel ?? "")

        var hintDescription = accessibilityHint?.nonEmpty()

        let numberFormatter = NumberFormatter()
        if let localeIdentifier = accessibilityLanguage {
            numberFormatter.locale = Locale(identifier: localeIdentifier)
        }

        let descriptionContainsContext: Bool
        if let context = context {
            switch context {
            case let .dataTableCell(row: row, column: column, rowSpan: rowSpan, columnSpan: columnSpan, isFirstInRow: isFirstInRow, rowHeaders: rowHeaders, columnHeaders: columnHeaders):
                // Headers are pre-formatted strings, just join them
                let headersDescription = (rowHeaders + columnHeaders).joined()

                let trailingPeriod = accessibilityDescription.hasSuffix(".") ? "" : "."

                let showsHeight = (rowSpan > 1 && row != NSNotFound)
                let showsWidth = (columnSpan > 1 && column != NSNotFound)
                let showsRow = (isFirstInRow && row != NSNotFound)
                let showsColumn = (column != NSNotFound)

                accessibilityDescription =
                    headersDescription
                        + accessibilityDescription
                        + trailingPeriod
                        + (showsHeight ? " " + String(format: strings.dataTableRowSpanFormat, numberFormatter.string(from: .init(value: rowSpan))!) : "")
                        + (showsWidth ? " " + String(format: strings.dataTableColumnSpanFormat, numberFormatter.string(from: .init(value: columnSpan))!) : "")
                        + (showsRow ? " " + String(format: strings.dataTableRowFormat, numberFormatter.string(from: .init(value: row + 1))!) : "")
                        + (showsColumn ? " " + String(format: strings.dataTableColumnFormat, numberFormatter.string(from: .init(value: column + 1))!) : "")

                descriptionContainsContext = true

            case .series, .tab, .tabBarItem, .listStart, .listEnd, .landmarkStart, .landmarkEnd:
                descriptionContainsContext = false
            }

        } else {
            descriptionContainsContext = false
        }

        if let accessibilityValue = accessibilityValue?.nonEmpty(), !hidesAccessibilityValue(for: context) {
            if let existingDescription = accessibilityDescription.nonEmpty() {
                if descriptionContainsContext {
                    accessibilityDescription += " \(accessibilityValue)"
                } else {
                    accessibilityDescription = "\(existingDescription): \(accessibilityValue)"
                }
            } else {
                accessibilityDescription = accessibilityValue
            }
        }

        // Append high-importance custom content (after value, before traits)
        // Per WWDC21: "Bailey, beagle, three years" - custom content follows value
        for content in describableCustomContent where content.isImportant {
            let contentDescription = content.value.isEmpty ? content.label : content.value

            if let existingDescription = accessibilityDescription.nonEmpty() {
                accessibilityDescription = "\(existingDescription), \(contentDescription)"
            } else {
                accessibilityDescription = contentDescription
            }
        }

        if accessibilityTraits.contains(.selected) {
            if let existingDescription = accessibilityDescription.nonEmpty() {
                accessibilityDescription = String(format: strings.selectedTraitFormat, existingDescription)
            } else {
                accessibilityDescription = strings.selectedTraitName
            }
        }

        var traitSpecifiers: [String] = []

        if accessibilityTraits.contains(.notEnabled) {
            traitSpecifiers.append(strings.notEnabledTraitName)
        }

        let hidesButtonTraitInContext = context?.hidesButtonTrait ?? false
        let hidesButtonTraitFromTraits = [UIAccessibilityTraits.keyboardKey, .switchButton, .tabBarItem, .backButton].contains(where: { accessibilityTraits.contains($0) })
        if accessibilityTraits.contains(.button) && !hidesButtonTraitFromTraits && !hidesButtonTraitInContext {
            traitSpecifiers.append(strings.buttonTraitName)
        }

        if accessibilityTraits.contains(.backButton) {
            traitSpecifiers.append(strings.backButtonTraitName)
        }

        if accessibilityTraits.contains(.switchButton) {
            if accessibilityTraits.contains(.button) {
                // An element can have the private switch button trait without being a UISwitch (for example, by passing
                // through the traits of a contained switch). In this case, VoiceOver will still read the "Switch
                // Button." trait, but only if the element's traits also include the `.button` trait.
                traitSpecifiers.append(strings.switchButtonTraitName)
            }

            switch accessibilityValue {
            case "1":
                traitSpecifiers.append(strings.switchButtonOnStateName)
            case "0":
                traitSpecifiers.append(strings.switchButtonOffStateName)
            case "2":
                traitSpecifiers.append(strings.switchButtonMixedStateName)
            default:
                // Prior to iOS 17 the then private trait would suppress any other accessibility values.
                // Once the trait became public in 17 values other than the above are announced with the trait specifiers.
                if #available(iOS 17.0, *), let accessibilityValue {
                    traitSpecifiers.append(accessibilityValue)
                }
            }
        }

        let showsTabTraitInContext = context?.showsTabTrait ?? false
        if accessibilityTraits.contains(.tabBarItem) || showsTabTraitInContext {
            traitSpecifiers.append(strings.tabTraitName)
        }

        if accessibilityTraits.contains(.textEntry) {
            if accessibilityTraits.contains(.scrollable) {
                // This is a UITextView/TextEditor
            } else {
                // This is a UITextField/TextField
            }

            traitSpecifiers.append(strings.textEntryTraitName)

            if accessibilityTraits.contains(.isEditing) {
                traitSpecifiers.append(strings.isEditingTraitName)
            }
        }

        if accessibilityTraits.contains(.header) {
            traitSpecifiers.append(strings.headerTraitName)
        }

        if accessibilityTraits.contains(.link) {
            traitSpecifiers.append(strings.linkTraitName)
        }

        if accessibilityTraits.contains(.adjustable) {
            traitSpecifiers.append(strings.adjustableTraitName)
        }

        if accessibilityTraits.contains(.image) {
            traitSpecifiers.append(strings.imageTraitName)
        }

        if accessibilityTraits.contains(.searchField) {
            traitSpecifiers.append(strings.searchFieldTraitName)
        }

        // If the description is empty, use the hint as the description.
        if accessibilityDescription.isEmpty {
            accessibilityDescription = hintDescription ?? ""
            hintDescription = nil
        }

        // Add trait specifiers to description.
        if !traitSpecifiers.isEmpty {
            if let existingDescription = accessibilityDescription.nonEmpty() {
                let trailingPeriod = existingDescription.hasSuffix(".") ? "" : "."
                accessibilityDescription = "\(existingDescription)\(trailingPeriod) \(traitSpecifiers.joined(separator: " "))"
            } else {
                accessibilityDescription = traitSpecifiers.joined(separator: " ")
            }
        }

        if let context = context {
            switch context {
            case let .series(index: index, count: count),
                 let .tabBarItem(index: index, count: count),
                 let .tab(index: index, count: count):
                accessibilityDescription = String(format:
                    strings.seriesContextFormat,
                    accessibilityDescription,
                    numberFormatter.string(from: .init(value: index))!,
                    numberFormatter.string(from: .init(value: count))!)

            case .listStart:
                let trailingPeriod = accessibilityDescription.hasSuffix(".") ? "" : "."
                accessibilityDescription = String(format:
                    "%@%@ %@",
                    accessibilityDescription,
                    trailingPeriod,
                    strings.listStartContext)

            case .listEnd:
                let trailingPeriod = accessibilityDescription.hasSuffix(".") ? "" : "."
                accessibilityDescription = String(format:
                    "%@%@ %@",
                    accessibilityDescription,
                    trailingPeriod,
                    strings.listEndContext)

            case .landmarkStart:
                let trailingPeriod = accessibilityDescription.hasSuffix(".") ? "" : "."
                accessibilityDescription = String(format:
                    "%@%@ %@",
                    accessibilityDescription,
                    trailingPeriod,
                    strings.landmarkStartContext)

            case .landmarkEnd:
                let trailingPeriod = accessibilityDescription.hasSuffix(".") ? "" : "."
                accessibilityDescription = String(format:
                    "%@%@ %@",
                    accessibilityDescription,
                    trailingPeriod,
                    strings.landmarkEndContext)

            case .dataTableCell:
                break
            }
        }

        if accessibilityTraits.contains(.switchButton) && !accessibilityTraits.contains(.notEnabled) {
            if let existingHintDescription = hintDescription?.nonEmpty()?.strippingTrailingPeriod() {
                hintDescription = String(format: strings.switchButtonTraitHintFormat, existingHintDescription)
            } else {
                hintDescription = strings.switchButtonTraitHint
            }
        }

        if accessibilityTraits.contains(.textEntry) && !accessibilityTraits.contains(.notEnabled) {
            if accessibilityTraits.contains(.isEditing) {
                hintDescription = strings.textEntryIsEditingTraitHint
            } else {
                if accessibilityTraits.contains(.scrollable) {
                    // This is a UITextView/TextEditor
                    hintDescription = strings.scrollableTextEntryTraitHint
                } else {
                    // This is a UITextField/TextField
                    hintDescription = strings.textEntryTraitHint
                }
            }
        }

        let hasHintOnly = (accessibilityHint?.nonEmpty() != nil) && (accessibilityLabel?.nonEmpty() == nil) && (accessibilityValue?.nonEmpty() == nil)
        let hidesAdjustableHint = accessibilityTraits.contains(.notEnabled) || accessibilityTraits.contains(.switchButton) || hasHintOnly
        if accessibilityTraits.contains(.adjustable), !hidesAdjustableHint {
            if let existingHintDescription = hintDescription?.nonEmpty()?.strippingTrailingPeriod() {
                hintDescription = String(format: strings.adjustableTraitHintFormat, existingHintDescription)
            } else {
                hintDescription = strings.adjustableTraitHint
            }
        }

        return (accessibilityDescription, hintDescription)
    }

    // MARK: - Private Methods

    private func accessibilityLabelOverride(for context: AccessibilityElement.ContainerContext?) -> String? {
        guard let context = context else {
            return nil
        }

        switch context {
        case .tabBarItem:
            return nil

        case .series, .tab, .dataTableCell, .listStart, .listEnd, .landmarkStart, .landmarkEnd:
            return nil
        }
    }

    private func hidesAccessibilityValue(for context: AccessibilityElement.ContainerContext?) -> Bool {
        if accessibilityTraits.contains(.switchButton) {
            return true
        }

        guard let context = context else {
            return false
        }

        switch context {
        case .tabBarItem:
            return false

        case .series, .tab, .dataTableCell, .listStart, .listEnd, .landmarkStart, .landmarkEnd:
            return false
        }
    }

    private func hidesAccessibilityLabel(backDescriptor: String) -> Bool {
        // To prevent duplication, Back Button elements omit their label if it matches the localized "Back" descriptor.
        guard accessibilityTraits.contains(.backButton),
              let label = accessibilityLabel else { return false }
        return label.lowercased() == backDescriptor.lowercased()
    }
}

// MARK: - Localization

/// Localized strings for VoiceOver description generation.
struct Strings {
    // MARK: - Public Properties

    let selectedTraitName: String

    let selectedTraitFormat: String

    let notEnabledTraitName: String

    let buttonTraitName: String

    let backButtonTraitName: String

    let backDescriptor: String

    let tabTraitName: String

    let headerTraitName: String

    let linkTraitName: String

    let adjustableTraitName: String

    let adjustableTraitHint: String

    let adjustableTraitHintFormat: String

    let imageTraitName: String

    let searchFieldTraitName: String

    let switchButtonTraitName: String

    let switchButtonOnStateName: String

    let switchButtonOffStateName: String

    let switchButtonMixedStateName: String

    let switchButtonTraitHint: String

    let switchButtonTraitHintFormat: String

    let seriesContextFormat: String

    let dataTableRowSpanFormat: String

    let dataTableColumnSpanFormat: String

    let dataTableRowFormat: String

    let dataTableColumnFormat: String

    let listStartContext: String

    let listEndContext: String

    let landmarkStartContext: String

    let landmarkEndContext: String

    let textEntryTraitName: String

    let textEntryTraitHint: String

    let textEntryIsEditingTraitHint: String

    let scrollableTextEntryTraitHint: String

    let isEditingTraitName: String

    // MARK: - Life Cycle

    init(locale: String?) {
        selectedTraitName = "Selected.".localized(
            key: "trait.selected.description",
            comment: "Description for the 'selected' accessibility trait",
            locale: locale
        )
        selectedTraitFormat = "Selected: %@".localized(
            key: "trait.selected.format",
            comment: "Format for the description of the selected element; param0: the description of the element",
            locale: locale
        )
        notEnabledTraitName = "Dimmed.".localized(
            key: "trait.not_enabled.description",
            comment: "Description for the 'not enabled' accessibility trait",
            locale: locale
        )
        buttonTraitName = "Button.".localized(
            key: "trait.button.description",
            comment: "Description for the 'button' accessibility trait",
            locale: locale
        )
        backButtonTraitName = "Back Button.".localized(
            key: "trait.backbutton.description",
            comment: "Description for the 'back button' accessibility trait",
            locale: locale
        )
        backDescriptor = "Back".localized(
            key: "back.descriptor",
            comment: "Descriptor for the 'back' portion of the 'back button' accessibility trait",
            locale: locale
        )
        tabTraitName = "Tab.".localized(
            key: "trait.tab.description",
            comment: "Description for the 'tab' accessibility trait",
            locale: locale
        )
        headerTraitName = "Heading.".localized(
            key: "trait.header.description",
            comment: "Description for the 'header' accessibility trait",
            locale: locale
        )
        linkTraitName = "Link.".localized(
            key: "trait.link.description",
            comment: "Description for the 'link' accessibility trait",
            locale: locale
        )
        adjustableTraitName = "Adjustable.".localized(
            key: "trait.adjustable.description",
            comment: "Description for the 'adjustable' accessibility trait",
            locale: locale
        )
        adjustableTraitHint = "Swipe up or down with one finger to adjust the value.".localized(
            key: "trait.adjustable.hint",
            comment: "Hint describing how to use elements with the 'adjustable' accessibility trait",
            locale: locale
        )
        adjustableTraitHintFormat = "%@. Swipe up or down with one finger to adjust the value.".localized(
            key: "trait.adjustable.hint_format",
            comment: "Format for hint describing how to use elements with the 'adjustable' accessibility trait; " +
                "param0: the existing hint",
            locale: locale
        )
        imageTraitName = "Image.".localized(
            key: "trait.image.description",
            comment: "Description for the 'image' accessibility trait",
            locale: locale
        )
        searchFieldTraitName = "Search Field.".localized(
            key: "trait.search_field.description",
            comment: "Description for the 'search field' accessibility trait",
            locale: locale
        )
        switchButtonTraitName = "Switch Button.".localized(
            key: "trait.switch_button.description",
            comment: "Description for the 'switch button' accessibility trait",
            locale: locale
        )
        switchButtonOnStateName = "On.".localized(
            key: "trait.switch_button.state_on.description",
            comment: "Description for the 'switch button' accessibility trait, when the switch is on",
            locale: locale
        )
        switchButtonOffStateName = "Off.".localized(
            key: "trait.switch_button.state_off.description",
            comment: "Description for the 'switch button' accessibility trait, when the switch is off",
            locale: locale
        )
        switchButtonMixedStateName = "Mixed.".localized(
            key: "trait.switch_button.state_mixed.description",
            comment: "Description for the 'switch button' accessibility trait, when the switch is in a mixed state",
            locale: locale
        )
        switchButtonTraitHint = "Double tap to toggle setting.".localized(
            key: "trait.switch_button.hint",
            comment: "Hint describing how to use elements with the 'switch button' accessibility trait",
            locale: locale
        )
        switchButtonTraitHintFormat = "%@. Double tap to toggle setting.".localized(
            key: "trait.switch_button.hint_format",
            comment: "Format for hint describing how to use elements with the 'switch button' accessibility trait; " +
                "param0: the existing hint",
            locale: locale
        )
        seriesContextFormat = "%@ %@ of %@.".localized(
            key: "context.series.description_format",
            comment: "Format for the description of an element in a series; param0: the description of the element, " +
                "param1: the index of the element in the series, param2: the number of elements in the series",
            locale: locale
        )
        dataTableRowSpanFormat = "Spans %@ rows.".localized(
            key: "context.data_table.row_span_format",
            comment: "Format for the description of the height of a cell in a table; param0: the number of rows the cell spans",
            locale: locale
        )
        dataTableColumnSpanFormat = "Spans %@ columns.".localized(
            key: "context.data_table.column_span_format",
            comment: "Format for the description of the width of a cell in a table; param0: the number of columns the cell spans",
            locale: locale
        )
        dataTableRowFormat = "Row %@.".localized(
            key: "context.data_table.row_format",
            comment: "Format for the description of the vertical location of a cell in a table; param0: the row in which the cell resides",
            locale: locale
        )
        dataTableColumnFormat = "Column %@.".localized(
            key: "context.data_table.column_format",
            comment: "Format for the description of the horizontal location of a cell in a table; param0: the column in which the cell resides",
            locale: locale
        )
        listStartContext = "List Start.".localized(
            key: "context.list_start.description",
            comment: "Description of the first element in a list",
            locale: locale
        )
        listEndContext = "List End.".localized(
            key: "context.list_end.description",
            comment: "Description of the last element in a list",
            locale: locale
        )
        landmarkStartContext = "Landmark.".localized(
            key: "context.landmark_start.description",
            comment: "Description of the first element in a landmark container",
            locale: locale
        )
        landmarkEndContext = "End.".localized(
            key: "context.landmark_end.description",
            comment: "Description of the last element in a landmark container",
            locale: locale
        )
        textEntryTraitName = "Text Field.".localized(
            key: "trait.text_field.description",
            comment: "Description for the 'text entry' accessibility trait",
            locale: locale
        )
        textEntryTraitHint = "Double tap to edit.".localized(
            key: "trait.text_field.hint",
            comment: "Hint describing how to use elements with the 'text entry' accessibility trait",
            locale: locale
        )
        textEntryIsEditingTraitHint = "Use the rotor to access Misspelled Words".localized(
            key: "trait.text_field_is_editing.hint",
            comment: "Hint describing how to use elements with the 'text entry' accessibility trait when they are being edited",
            locale: locale
        )
        scrollableTextEntryTraitHint = "Double tap to edit., Use the rotor to access Misspelled Words".localized(
            key: "trait.scrollable_text_field.hint",
            comment: "Hint describing how to use elements with the 'text entry' and 'scrollable' accessibility traits",
            locale: locale
        )
        isEditingTraitName = "Is editing.".localized(
            key: "trait.text_field_is_editing.description",
            comment: "Description for the 'is editing' accessibility trait",
            locale: locale
        )
    }
}

// MARK: - String Extensions

extension String {
    /// Returns the string if it is non-empty, otherwise nil.
    func nonEmpty() -> String? {
        return isEmpty ? nil : self
    }

    func strippingTrailingPeriod() -> String {
        if hasSuffix(".") {
            return String(dropLast())
        } else {
            return self
        }
    }
}

// MARK: - Private Accessibility Traits

extension UIAccessibilityTraits {
    static let textEntry = UIAccessibilityTraits(rawValue: 1 << 18) // 0x0000000000040000

    static let isEditing = UIAccessibilityTraits(rawValue: 1 << 21) // 0x0000000000200000

    static let backButton = UIAccessibilityTraits(rawValue: 1 << 27) // 0x0000000008000000

    static let tabBarItem = UIAccessibilityTraits(rawValue: 1 << 28) // 0x0000000010000000

    static let scrollable = UIAccessibilityTraits(rawValue: 1 << 47) // 0x0000800000000000

    static let switchButton = UIAccessibilityTraits(rawValue: 1 << 53) // 0x0020000000000000
}

// MARK: - ContainerContext Description Extensions

extension AccessibilityElement.ContainerContext {
    var hidesButtonTrait: Bool {
        switch self {
        case .series, .tabBarItem, .dataTableCell, .listStart, .listEnd, .landmarkStart, .landmarkEnd:
            return false

        case .tab:
            return true
        }
    }

    var showsTabTrait: Bool {
        switch self {
        case .series, .dataTableCell, .listStart, .listEnd, .landmarkStart, .landmarkEnd:
            return false

        case .tab, .tabBarItem:
            return true
        }
    }
}

// MARK: - NSObject Conformance

// NSObject already has accessibilityLabel, accessibilityValue, accessibilityTraits,
// accessibilityHint, and accessibilityLanguage - so conformance is nearly empty.
// All description logic is provided by the protocol's default implementation.
extension NSObject: AccessibilityDescribable {
    var describableCustomContent: [AccessibilityElement.CustomContent] {
        if #available(iOS 14.0, *) {
            if let provider = self as? AXCustomContentProvider {
                #if swift(>=5.9)
                    if #available(iOS 17.0, *) {
                        if let customContentBlock = provider.accessibilityCustomContentBlock {
                            if let content = customContentBlock?() {
                                return content.map { .init(from: $0) }
                            }
                        }
                    }
                #endif
                if let content = provider.accessibilityCustomContent {
                    return content.map { .init(from: $0) }
                }
            }
        }
        return []
    }
}

// MARK: - AccessibilityElement Conformance

extension AccessibilityElement: AccessibilityDescribable {
    // Map stored property names to protocol requirements.
    // All description logic is provided by the protocol's default implementation.
    var accessibilityLabel: String? { label }
    var accessibilityValue: String? { value }
    var accessibilityTraits: UIAccessibilityTraits { traits }
    var accessibilityHint: String? { hint }
    var describableCustomContent: [CustomContent] { customContent }
    // accessibilityLanguage already matches the protocol requirement name
}

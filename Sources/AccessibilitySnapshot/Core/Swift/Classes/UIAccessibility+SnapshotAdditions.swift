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

import UIKit

extension NSObject {

    /// Returns a tuple consisting of the `description` and (optionally) a `hint` that VoiceOver will read for the object.
    func accessibilityDescription(context: AccessibilityHierarchyParser.Context?) -> (description: String, hint: String?) {
        var accessibilityDescription = accessibilityLabelOverride(for: context) ?? accessibilityLabel ?? ""

        var hintDescription = accessibilityHint?.nonEmpty()

        let strings = Strings(locale: accessibilityLanguage)

        let numberFormatter = NumberFormatter()
        if let localeIdentifier = accessibilityLanguage {
            numberFormatter.locale = Locale(identifier: localeIdentifier)
        }

        let descriptionContainsContext: Bool
        if let context = context {
            switch context {
            case let .dataTableCell(row: row, column: column, width: width, height: height, isFirstInRow: isFirstInRow, rowHeaders: rowHeaders, columnHeaders: columnHeaders):
                let headersDescription = (rowHeaders + columnHeaders).map { header -> String in
                    switch (header.accessibilityLabel?.nonEmpty(), header.accessibilityValue?.nonEmpty()) {
                    case (nil, nil):
                        return ""
                    case let (.some(label), nil):
                        return "\(label). "
                    case let (nil, .some(value)):
                        return "\(value). "
                    case let (.some(label), .some(value)):
                        return "\(label): \(value). "
                    }
                }.reduce("", +)

                let trailingPeriod = accessibilityDescription.hasSuffix(".") ? "" : "."

                let showsHeight = (height > 1 && row != NSNotFound)
                let showsWidth = (width > 1 && column != NSNotFound)
                let showsRow = (isFirstInRow && row != NSNotFound)
                let showsColumn = (column != NSNotFound)

                accessibilityDescription =
                    headersDescription
                    + accessibilityDescription
                    + trailingPeriod
                    + (showsHeight ? " " + String(format: strings.dataTableRowSpanFormat, numberFormatter.string(from: .init(value: height))!) : "")
                    + (showsWidth ? " " + String(format: strings.dataTableColumnSpanFormat, numberFormatter.string(from: .init(value: width))!) : "")
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
        let hidesButtonTraitFromTraits = [UIAccessibilityTraits.keyboardKey, .switchButton, .tabBarItem].contains(where: { accessibilityTraits.contains($0) })
        if accessibilityTraits.contains(.button) && !hidesButtonTraitFromTraits && !hidesButtonTraitInContext {
            traitSpecifiers.append(strings.buttonTraitName)
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
                // When the switch button trait is set, unknown accessibility values are omitted from the description.
                break
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
                 let .tabBarItem(index: index, count: count, item: _),
                 let .tab(index: index, count: count):
                accessibilityDescription = String(format:
                    strings.seriesContextFormat,
                    accessibilityDescription,
                    numberFormatter.string(from: .init(value: index))!,
                    numberFormatter.string(from: .init(value: count))!
                )

            case .listStart:
                let trailingPeriod = accessibilityDescription.hasSuffix(".") ? "" : "."
                accessibilityDescription = String(format:
                    "%@%@ %@",
                    accessibilityDescription,
                    trailingPeriod,
                    strings.listStartContext
                )

            case .listEnd:
                let trailingPeriod = accessibilityDescription.hasSuffix(".") ? "" : "."
                accessibilityDescription = String(format:
                    "%@%@ %@",
                    accessibilityDescription,
                    trailingPeriod,
                    strings.listEndContext
                )

            case .landmarkStart:
                let trailingPeriod = accessibilityDescription.hasSuffix(".") ? "" : "."
                accessibilityDescription = String(format:
                    "%@%@ %@",
                    accessibilityDescription,
                    trailingPeriod,
                    strings.landmarkStartContext
                )

            case .landmarkEnd:
                let trailingPeriod = accessibilityDescription.hasSuffix(".") ? "" : "."
                accessibilityDescription = String(format:
                    "%@%@ %@",
                    accessibilityDescription,
                    trailingPeriod,
                    strings.landmarkEndContext
                )

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
        if accessibilityTraits.contains(.adjustable) && !hidesAdjustableHint {
            if let existingHintDescription = hintDescription?.nonEmpty()?.strippingTrailingPeriod() {
                hintDescription = String(format: strings.adjustableTraitHintFormat, existingHintDescription)
            } else {
                hintDescription = strings.adjustableTraitHint
            }
        }

        return (accessibilityDescription, hintDescription)
    }

    // MARK: - Private Methods

    private func accessibilityLabelOverride(for context: AccessibilityHierarchyParser.Context?) -> String? {
        guard let context = context else {
            return nil
        }

        switch context {
        case .tabBarItem(index: _, count: _, item: _):
            return nil

        case .series, .tab, .dataTableCell, .listStart, .listEnd, .landmarkStart, .landmarkEnd:
            return nil
        }
    }

    private func hidesAccessibilityValue(for context: AccessibilityHierarchyParser.Context?) -> Bool {
        if accessibilityTraits.contains(.switchButton) {
            return true
        }

        guard let context = context else {
            return false
        }

        switch context {
        case .tabBarItem(index: _, count: _, item: _):
            return false

        case .series, .tab, .dataTableCell, .listStart, .listEnd, .landmarkStart, .landmarkEnd:
            return false
        }
    }

    // MARK: - Private Static Properties

    // MARK: - Private

    private struct Strings {

        // MARK: - Public Properties

        let selectedTraitName: String

        let selectedTraitFormat: String

        let notEnabledTraitName: String

        let buttonTraitName: String

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
            self.selectedTraitName = "Selected.".localized(
                key: "trait.selected.description",
                comment: "Description for the 'selected' accessibility trait",
                locale: locale
            )
            self.selectedTraitFormat = "Selected: %@".localized(
                key: "trait.selected.format",
                comment: "Format for the description of the selected element; param0: the description of the element",
                locale: locale
            )
            self.notEnabledTraitName = "Dimmed.".localized(
                key: "trait.not_enabled.description",
                comment: "Description for the 'not enabled' accessibility trait",
                locale: locale
            )
            self.buttonTraitName = "Button.".localized(
                key: "trait.button.description",
                comment: "Description for the 'button' accessibility trait",
                locale: locale
            )
            self.tabTraitName = "Tab.".localized(
                key: "trait.tab.description",
                comment: "Description for the 'tab' accessibility trait",
                locale: locale
            )
            self.headerTraitName = "Heading.".localized(
                key: "trait.header.description",
                comment: "Description for the 'header' accessibility trait",
                locale: locale
            )
            self.linkTraitName = "Link.".localized(
                key: "trait.link.description",
                comment: "Description for the 'link' accessibility trait",
                locale: locale
            )
            self.adjustableTraitName = "Adjustable.".localized(
                key: "trait.adjustable.description",
                comment: "Description for the 'adjustable' accessibility trait",
                locale: locale
            )
            self.adjustableTraitHint = "Swipe up or down with one finger to adjust the value.".localized(
                key: "trait.adjustable.hint",
                comment: "Hint describing how to use elements with the 'adjustable' accessibility trait",
                locale: locale
            )
            self.adjustableTraitHintFormat = "%@. Swipe up or down with one finger to adjust the value.".localized(
                key: "trait.adjustable.hint_format",
                comment: "Format for hint describing how to use elements with the 'adjustable' accessibility trait; " +
                         "param0: the existing hint",
                locale: locale
            )
            self.imageTraitName = "Image.".localized(
                key: "trait.image.description",
                comment: "Description for the 'image' accessibility trait",
                locale: locale
            )
            self.searchFieldTraitName = "Search Field.".localized(
                key: "trait.search_field.description",
                comment: "Description for the 'search field' accessibility trait",
                locale: locale
            )
            self.switchButtonTraitName = "Switch Button.".localized(
                key: "trait.switch_button.description",
                comment: "Description for the 'switch button' accessibility trait",
                locale: locale
            )
            self.switchButtonOnStateName = "On.".localized(
                key: "trait.switch_button.state_on.description",
                comment: "Description for the 'switch button' accessibility trait, when the switch is on",
                locale: locale
            )
            self.switchButtonOffStateName = "Off.".localized(
                key: "trait.switch_button.state_off.description",
                comment: "Description for the 'switch button' accessibility trait, when the switch is off",
                locale: locale
            )
            self.switchButtonMixedStateName = "Mixed.".localized(
                key: "trait.switch_button.state_mixed.description",
                comment: "Description for the 'switch button' accessibility trait, when the switch is in a mixed state",
                locale: locale
            )
            self.switchButtonTraitHint = "Double tap to toggle setting.".localized(
                key: "trait.switch_button.hint",
                comment: "Hint describing how to use elements with the 'switch button' accessibility trait",
                locale: locale
            )
            self.switchButtonTraitHintFormat = "%@. Double tap to toggle setting.".localized(
                key: "trait.switch_button.hint_format",
                comment: "Format for hint describing how to use elements with the 'switch button' accessibility trait; " +
                         "param0: the existing hint",
                locale: locale
            )
            self.seriesContextFormat = "%@ %@ of %@.".localized(
                key: "context.series.description_format",
                comment: "Format for the description of an element in a series; param0: the description of the element, " +
                         "param1: the index of the element in the series, param2: the number of elements in the series",
                locale: locale
            )
            self.dataTableRowSpanFormat = "Spans %@ rows.".localized(
                key: "context.data_table.row_span_format",
                comment: "Format for the description of the height of a cell in a table; param0: the number of rows the cell spans",
                locale: locale
            )
            self.dataTableColumnSpanFormat = "Spans %@ columns.".localized(
                key: "context.data_table.column_span_format",
                comment: "Format for the description of the width of a cell in a table; param0: the number of columns the cell spans",
                locale: locale
            )
            self.dataTableRowFormat = "Row %@.".localized(
                key: "context.data_table.row_format",
                comment: "Format for the description of the vertical location of a cell in a table; param0: the row in which the cell resides",
                locale: locale
            )
            self.dataTableColumnFormat = "Column %@.".localized(
                key: "context.data_table.column_format",
                comment: "Format for the description of the horizontal location of a cell in a table; param0: the column in which the cell resides",
                locale: locale
            )
            self.listStartContext = "List Start.".localized(
                key: "context.list_start.description",
                comment: "Description of the first element in a list",
                locale: locale
            )
            self.listEndContext = "List End.".localized(
                key: "context.list_end.description",
                comment: "Description of the last element in a list",
                locale: locale
            )
            self.landmarkStartContext = "Landmark.".localized(
                key: "context.landmark_start.description",
                comment: "Description of the first element in a landmark container",
                locale: locale
            )
            self.landmarkEndContext = "End.".localized(
                key: "context.landmark_end.description",
                comment: "Description of the last element in a landmark container",
                locale: locale
            )
            self.textEntryTraitName = "Text Field.".localized(
                key: "trait.text_field.description",
                comment: "Description for the 'text entry' accessibility trait",
                locale: locale
            )
            self.textEntryTraitHint = "Double tap to edit.".localized(
                key: "trait.text_field.hint",
                comment: "Hint describing how to use elements with the 'text entry' accessibility trait",
                locale: locale
            )
            self.textEntryIsEditingTraitHint = "Use the rotor to access Misspelled Words".localized(
                key: "trait.text_field_is_editing.hint",
                comment: "Hint describing how to use elements with the 'text entry' accessibility trait when they are being edited",
                locale: locale
            )
            self.scrollableTextEntryTraitHint = "Double tap to edit., Use the rotor to access Misspelled Words".localized(
                key: "trait.scrollable_text_field.hint",
                comment: "Hint describing how to use elements with the 'text entry' and 'scrollable' accessibility traits",
                locale: locale
            )
            self.isEditingTraitName = "Is editing.".localized(
                key: "trait.text_field_is_editing.description",
                comment: "Description for the 'is editing' accessibility trait",
                locale: locale
            )
        }

    }

}

// MARK: -

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

// MARK: -

extension UIAccessibilityTraits {

    static let tabBarItem = UIAccessibilityTraits(rawValue: 0x0000000010000000)

    static let switchButton = UIAccessibilityTraits(rawValue: 0x0020000000000000)

    static let isEditing = UIAccessibilityTraits(rawValue: 0x0000000000200000)

    static let textEntry = UIAccessibilityTraits(rawValue: 0x0000000000040000)

    static let scrollable = UIAccessibilityTraits(rawValue: 0x0000800000000000)
}

// MARK: -

extension AccessibilityHierarchyParser.Context {

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

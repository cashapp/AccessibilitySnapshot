import Foundation

extension AccessibilityElement {
    /// Formats the VoiceOver description and hint from captured accessibility values.
    public static func accessibilityDescription(
        label: String?,
        value: String?,
        traits: AccessibilityTraits,
        authoredHint: String?,
        accessibilityLanguage: String?,
        context: AccessibilityContext?
    ) -> (description: String, hint: String?) {
        let strings = Strings(locale: accessibilityLanguage)

        var accessibilityDescription =
            (traits.contains(.backButton) && label?.lowercased() == strings.backDescriptor.lowercased())
                ? "" : label ?? ""

        var hintDescription = authoredHint?.nonEmpty()

        let numberFormatter = NumberFormatter()
        if let localeIdentifier = accessibilityLanguage {
            numberFormatter.locale = Locale(identifier: localeIdentifier)
        }

        let descriptionContainsContext: Bool
        if let context = context {
            switch context {
            case let .dataTableCell(row: row, column: column, width: width, height: height, isFirstInRow: isFirstInRow, rowHeaders: rowHeaders, columnHeaders: columnHeaders):
                let headersDescription = (rowHeaders + columnHeaders).map { header -> String in
                    switch (header.label?.nonEmpty(), header.value?.nonEmpty()) {
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

        if let value = value?.nonEmpty(), !traits.contains(.switchButton) {
            if let existingDescription = accessibilityDescription.nonEmpty() {
                if descriptionContainsContext {
                    accessibilityDescription += " \(value)"
                } else {
                    accessibilityDescription = "\(existingDescription): \(value)"
                }
            } else {
                accessibilityDescription = value
            }
        }

        if traits.contains(.selected) {
            if let existingDescription = accessibilityDescription.nonEmpty() {
                accessibilityDescription = String(format: strings.selectedTraitFormat, existingDescription)
            } else {
                accessibilityDescription = strings.selectedTraitName
            }
        }

        var traitSpecifiers: [String] = []

        if traits.contains(.notEnabled) {
            traitSpecifiers.append(strings.notEnabledTraitName)
        }

        let hidesButtonTraitInContext = context?.hidesButtonTrait ?? false
        let hidesButtonTraitFromTraits = [AccessibilityTraits.keyboardKey, .switchButton, .tabBarItem, .backButton].contains(where: { traits.contains($0) })
        if traits.contains(.button) && !hidesButtonTraitFromTraits && !hidesButtonTraitInContext {
            traitSpecifiers.append(strings.buttonTraitName)
        }

        if traits.contains(.backButton) {
            traitSpecifiers.append(strings.backButtonTraitName)
        }

        if traits.contains(.switchButton) {
            if traits.contains(.button) {
                // An element can have the private switch button trait without being a UISwitch (for example, by passing
                // through the traits of a contained switch). In this case, VoiceOver will still read the "Switch
                // Button." trait, but only if the element's traits also include the `.button` trait.
                traitSpecifiers.append(strings.switchButtonTraitName)
            }

            switch value {
            case "1":
                traitSpecifiers.append(strings.switchButtonOnStateName)
            case "0":
                traitSpecifiers.append(strings.switchButtonOffStateName)
            case "2":
                traitSpecifiers.append(strings.switchButtonMixedStateName)
            default:
                // Prior to iOS 17 the then private trait would suppress any other accessibility values.
                // Once the trait became public in 17 values other than the above are announced with the trait specifiers.
                if #available(iOS 17.0, *), let value {
                    traitSpecifiers.append(value)
                }
            }
        }

        let showsTabTraitInContext = context?.showsTabTrait ?? false
        if traits.contains(.tabBarItem) || showsTabTraitInContext {
            traitSpecifiers.append(strings.tabTraitName)
        }

        if traits.contains(.textEntry) {
            if traits.contains(.secureTextField) {
                traitSpecifiers.append(strings.secureTextFieldTraitName)
            } else {
                traitSpecifiers.append(strings.textEntryTraitName)
            }

            if traits.contains(.isEditing) {
                traitSpecifiers.append(strings.isEditingTraitName)
            }
        }

        if traits.contains(.header) {
            traitSpecifiers.append(strings.headerTraitName)
        }

        if traits.contains(.link) {
            traitSpecifiers.append(strings.linkTraitName)
        }

        if traits.contains(.adjustable) {
            traitSpecifiers.append(strings.adjustableTraitName)
        }

        if traits.contains(.image) {
            traitSpecifiers.append(strings.imageTraitName)
        }

        if traits.contains(.searchField) {
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

        if traits.contains(.switchButton) && !traits.contains(.notEnabled) {
            if let existingHintDescription = hintDescription?.nonEmpty()?.strippingTrailingPeriod() {
                hintDescription = String(format: strings.switchButtonTraitHintFormat, existingHintDescription)
            } else {
                hintDescription = strings.switchButtonTraitHint
            }
        }

        if traits.contains(.textEntry) && !traits.contains(.notEnabled) {
            if traits.contains(.isEditing) {
                hintDescription = strings.textEntryIsEditingTraitHint
            } else {
                if traits.contains(.textArea) {
                    // This is a UITextView/TextEditor
                    hintDescription = strings.textAreaTraitHint
                } else {
                    // This is a UITextField/TextField
                    hintDescription = strings.textEntryTraitHint
                }
            }
        }

        let hasHintOnly = (authoredHint?.nonEmpty() != nil) && (label?.nonEmpty() == nil) && (value?.nonEmpty() == nil)
        let hidesAdjustableHint = traits.contains(.notEnabled) || traits.contains(.switchButton) || hasHintOnly
        if traits.contains(.adjustable), !hidesAdjustableHint {
            if let existingHintDescription = hintDescription?.nonEmpty()?.strippingTrailingPeriod() {
                hintDescription = String(format: strings.adjustableTraitHintFormat, existingHintDescription)
            } else {
                hintDescription = strings.adjustableTraitHint
            }
        }

        return (accessibilityDescription, hintDescription)
    }

    private struct Strings {
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

        let secureTextFieldTraitName: String

        let textEntryTraitHint: String

        let textEntryIsEditingTraitHint: String

        let textAreaTraitHint: String

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
            secureTextFieldTraitName = "Secure Text Field.".localized(
                key: "trait.secure_text_field.description",
                comment: "Description for the 'secure text field' accessibility trait",
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
            textAreaTraitHint = "Double tap to edit., Use the rotor to access Misspelled Words".localized(
                key: "trait.text_area.hint",
                comment: "Hint describing how to use elements with the 'text entry' and 'text area' accessibility traits",
                locale: locale
            )
            isEditingTraitName = "Is editing.".localized(
                key: "trait.text_field_is_editing.description",
                comment: "Description for the 'is editing' accessibility trait",
                locale: locale
            )
        }
    }
}

// MARK: -

private extension String {
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

private extension AccessibilityContext {
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

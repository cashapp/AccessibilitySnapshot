import Foundation

/// Localized VoiceOver description strings, resolved for a given locale.
///
/// Lives in the model target so late description assembly (verbosity-driven) can run
/// on any platform. Backed by `.module` `.lproj` resources — see String+Localization.swift.
public struct Strings {
    // MARK: - Public Properties

    public let selectedTraitName: String

    public let selectedTraitFormat: String

    public let notEnabledTraitName: String

    public let buttonTraitName: String

    public let backButtonTraitName: String

    public let backDescriptor: String

    public let tabTraitName: String

    public let headerTraitName: String

    public let linkTraitName: String

    public let adjustableTraitName: String

    public let adjustableTraitHint: String

    public let adjustableTraitHintFormat: String

    public let imageTraitName: String

    public let searchFieldTraitName: String

    public let switchButtonTraitName: String

    public let switchButtonOnStateName: String

    public let switchButtonOffStateName: String

    public let switchButtonMixedStateName: String

    public let switchButtonTraitHint: String

    public let switchButtonTraitHintFormat: String

    public let seriesContextFormat: String

    public let dataTableRowSpanFormat: String

    public let dataTableColumnSpanFormat: String

    public let dataTableRowFormat: String

    public let dataTableColumnFormat: String

    public let listStartContext: String

    public let listEndContext: String

    public let landmarkStartContext: String

    public let landmarkEndContext: String

    public let textEntryTraitName: String

    public let secureTextFieldTraitName: String

    public let textEntryTraitHint: String

    public let textEntryIsEditingTraitHint: String

    public let textAreaTraitHint: String

    public let isEditingTraitName: String

    // MARK: - Life Cycle

    public init(locale: String?) {
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

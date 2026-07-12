import Foundation

/// Ref-free container context derived from an element's position in the graph at delivery time.
///
/// This is the model-side mirror of the Parser's `AccessibilityHierarchyParser.Context`, but it
/// carries no live UIKit references — data-table headers are resolved to their text (`HeaderText`)
/// at derivation, not held as `NSObject`s. That is what lets description assembly run late, on any
/// platform, and be re-gated by `VerbosityConfiguration`.
public enum DerivedContext: Hashable, Sendable {
    /// The element is part of a series. Reads as "`index` of `count`."
    case series(index: Int, count: Int)

    /// The element is a tab in a `UITabBar`. Reads as "Tab. `index` of `count`."
    case tabBarItem(index: Int, count: Int)

    /// The element is a tab in a `.tabBar`-trait container. Reads as "Tab. `index` of `count`."
    case tab(index: Int, count: Int)

    /// The element is a cell in a data table.
    ///
    /// - `row` / `column`: zero-based position, or `NSNotFound` when unknown.
    /// - `width` / `height`: number of columns / rows the cell spans.
    /// - `isFirstInRow`: whether VoiceOver reads this as the first cell in its row.
    /// - `rowHeaders` / `columnHeaders`: the resolved header text VoiceOver reads before the cell.
    case dataTableCell(
        row: Int,
        column: Int,
        width: Int,
        height: Int,
        isFirstInRow: Bool,
        rowHeaders: [HeaderText],
        columnHeaders: [HeaderText]
    )

    /// The element is the first element in a list.
    case listStart

    /// The element is the last element in a list. (A sole element gets only `listStart`.)
    case listEnd

    /// The element is the first element in a landmark container.
    case landmarkStart

    /// The element is the last element in a landmark container. (A sole element gets only `landmarkStart`.)
    case landmarkEnd

    /// A data-table header's resolved text, extracted from the header element's label/value.
    public struct HeaderText: Hashable, Sendable {
        public let label: String?
        public let value: String?

        public init(label: String?, value: String?) {
            self.label = label
            self.value = value
        }
    }
}

// MARK: - Trait-hiding rules keyed on context

extension DerivedContext {
    /// Whether the container context suppresses the element's own "Button." trait specifier.
    var hidesButtonTrait: Bool {
        switch self {
        case .series, .tabBarItem, .dataTableCell, .listStart, .listEnd, .landmarkStart, .landmarkEnd:
            return false
        case .tab:
            return true
        }
    }

    /// Whether the container context adds a "Tab." trait specifier the element itself doesn't carry.
    var showsTabTrait: Bool {
        switch self {
        case .series, .dataTableCell, .listStart, .listEnd, .landmarkStart, .landmarkEnd:
            return false
        case .tab, .tabBarItem:
            return true
        }
    }
}

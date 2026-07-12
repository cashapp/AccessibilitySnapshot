import Foundation

// MARK: - Deriving context from graph position

public extension AccessibilityContainer {
    /// Derives the `DerivedContext` a child at `childIndex` receives from this container, purely from
    /// graph position — the container's type and the child's ordinal among `children`.
    ///
    /// This is the model-side, UIKit-free mirror of the parser's live `derivedContext(for:parent:)`.
    /// Instead of re-querying a live `UISegmentedControl`/`UITabBar`/`UIAccessibilityContainerDataTable`,
    /// it reads the ordered graph the parser already captured: series/tab position is the child's
    /// ordinal + sibling count (the same `{index, count}` VoiceOver derives from `_accessibilityRowRange`,
    /// which for tab bars UIKit itself computes from sibling position); data-table headers are resolved
    /// from the stored `cells` payload by dereferencing header child-indices into `children`.
    ///
    /// Returns `nil` when the container lends no context to its children (semantic group, scrollable,
    /// tab bar as a plain group, `.none`) or when `childIndex` is out of range.
    ///
    /// - Parameters:
    ///   - childIndex: the child's position among `children` in traversal order.
    ///   - children: the container's ordered children (used to resolve data-table header text).
    func derivedContext(forChildAt childIndex: Int, in children: [AccessibilityHierarchy]) -> DerivedContext? {
        guard childIndex >= 0, childIndex < children.count else { return nil }
        let count = children.count

        switch type {
        case .series:
            return .series(index: childIndex + 1, count: count)

        case .tabBar:
            // Tab context is uniform whether the tab bar was a real `UITabBar` or a `.tabBar`-trait
            // view; both render "Tab. N of M." (research: `.tab` ≡ `.tabBarItem`).
            return .tab(index: childIndex + 1, count: count)

        case .list:
            // A sole child gets only `listStart` (mirrors the parser: no `listEnd` when count == 1).
            if childIndex == 0 {
                return .listStart
            } else if childIndex == count - 1 {
                return .listEnd
            }
            return nil

        case .landmark:
            if childIndex == 0 {
                return .landmarkStart
            } else if childIndex == count - 1 {
                return .landmarkEnd
            }
            return nil

        case let .dataTable(_, _, cells):
            guard childIndex < cells.count, let cell = cells[childIndex] else { return nil }
            return .dataTableCell(
                row: cell.row,
                column: cell.column,
                width: cell.columnSpan,
                height: cell.rowSpan,
                isFirstInRow: cell.isFirstInRow,
                rowHeaders: headerTexts(for: cell.rowHeaderChildIndices, in: children),
                columnHeaders: headerTexts(for: cell.columnHeaderChildIndices, in: children)
            )

        case .semanticGroup, .scrollable, .none:
            return nil
        }
    }

    /// Resolves stored header child-indices into their elements' `HeaderText`. Indices point into the
    /// container's own `children`; a non-element or out-of-range index is skipped. Resolved over the
    /// FULL child set at derivation, before any on-screen pruning, so a header that later scrolls
    /// off-screen still travels with the visible cell.
    private func headerTexts(
        for indices: [Int],
        in children: [AccessibilityHierarchy]
    ) -> [DerivedContext.HeaderText] {
        indices.compactMap { index -> DerivedContext.HeaderText? in
            guard index >= 0, index < children.count else { return nil }
            guard case let .element(element, _) = children[index] else { return nil }
            return DerivedContext.HeaderText(label: element.label, value: element.value)
        }
    }
}

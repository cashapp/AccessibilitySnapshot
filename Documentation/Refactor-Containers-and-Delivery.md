# Refactor: Graph-Derived Context, Full-Fidelity Parse, Trim at Delivery

This document describes the container/context refactor landed on top of 0.21.0. It changes how the
parser computes context and how off-screen elements are handled, while keeping the default rendered
snapshot output byte-identical to the previous fork behavior.

## Summary of behavior changes

1. **Context is derived from graph position, not from a re-entrant walk.** List/landmark start/end,
   series "X of N", tab "X of N", and data-table cell coordinates/headers are computed from each
   element's ordered position within its container in the parsed tree, rather than by looping back
   into the live UIKit hierarchy. The old `ContextProvider` machinery (`context(for:from:)`, the
   tab-bar re-walk + `tabBarCache`, `providesContext`, `providedContextAsSuperview/Container`) is
   gone. Rendered descriptions are unchanged.

2. **The parser always parses the full tree and flags visibility.** Every element carries
   `AccessibilityElement.visibility` (`.onscreen` / `.offscreen`). The parser no longer prunes
   off-screen elements during the walk — the visible-frame and scroll-clip gates now *mark*
   elements off-screen and keep descending (a descendant of an off-screen ancestor is off-screen).
   Existence gates (`accessibilityElementsHidden`, hidden/alpha, zero-frame+`clipsToBounds`,
   sub-1pt frame) are unchanged.

3. **Trimming moved to delivery.** `[AccessibilityHierarchy].deliver(options:)` turns the parsed
   tree into the flat element list a consumer renders. `DeliveryOptions.trimmed` (the fork default)
   drops `.offscreen` elements and tallies them into per-scroll-container `ScrollContainerSummary`
   values; `DeliveryOptions.untrimmed` keeps everything (equivalent to `flattenToElements()`).
   The snapshot views call `deliver(options: configuration.deliveryOptions)`.

4. **Opt-in off-screen counts legend.** With
   `AccessibilitySnapshotConfiguration.showsOffscreenElementCounts = true`, the snapshot renders one
   extra legend row per scroll container summarizing how many elements were trimmed above/below its
   viewport. Off by default; the default legend is unchanged.

## New / changed public API

### Model (`AccessibilitySnapshotModel`)

- `AccessibilityVisibility { onscreen, offscreen }` and `AccessibilityElement.visibility`
  (defaults to `.onscreen`; decodes as `.onscreen` for payloads written before the field existed).
- `AccessibilityContainer.ContainerType.dataTable(rowCount:columnCount:cells:)` now carries a
  `cells: [DataTableCellInfo?]` payload aligned to the container's ordered children. Wire-compatible:
  legacy payloads without `cells` decode to `[]`.
- `DeliveryOptions { trimsOffscreenElements }` (`.trimmed` / `.untrimmed`).
- `ScrollContainerSummary { container, trimmedAbove, trimmedBelow, trimmedElsewhere, isEmpty }`.
- `DeliveredAccessibility { elements, scrollContainerSummaries }`.
- `[AccessibilityHierarchy].deliver(options:) -> DeliveredAccessibility`. Invariant:
  `deliver(.untrimmed).elements == flattenToElements()`.
- `AccessibilityShape.boundingRect`.

### Configuration (`AccessibilitySnapshotConfiguration`)

- `deliveryOptions: DeliveryOptions = .trimmed`.
- `showsOffscreenElementCounts: Bool = false`.

### Parsed data (`ParsedAccessibilityData`)

- `containerSummaries: [ScrollContainerSummary]` (default `[]`), populated from delivery.

## Breaking changes (0.22.0)

- **`ParserOptions`, `ParserOptions.includeOffScreenElements`, and `ParserOptions.fullTree` are
  removed.** They were a fork-only API. The parser is now always a full parse; use
  `deliver(options:)` at the snapshot end to control trimming. Migration:
  - `AccessibilityHierarchyParser(options: .default).parseAccessibilityHierarchy(in:).flattenToElements()`
    (pruned) → `parseAccessibilityHierarchy(in:).deliver(options: .trimmed).elements`.
  - `AccessibilityHierarchyParser(options: .fullTree).parseAccessibilityHierarchy(in:).flattenToElements()`
    (full) → `AccessibilityHierarchyParser().parseAccessibilityHierarchy(in:).flattenToElements()`.

## Known limitation: UITableView index enumeration (not yet landed)

VoiceOver enumerates *all* table rows via the accessibility index API
(`UITableViewCellAccessibilityElement` vended through `accessibilityElement(at:)`), whereas this
fork still walks only the instantiated cell subviews. Switching the parser to index enumeration for
`UIScrollView` subclasses was attempted but produced an inconsistent visibility result: the
index-vended rows and the instantiated-cell subviews coexist with divergent coordinate spaces, so
`deliver(.trimmed)` did not reproduce the SPI's visible row set. This needs a cell-substitution
("Plan B": match the index-vended proxy to its instantiated cell by accessibility-frame overlap)
before it can land byte-safely, and is intentionally deferred. The 3 `UITableView` SPI parity cases
keep `skipFullTree: true`.

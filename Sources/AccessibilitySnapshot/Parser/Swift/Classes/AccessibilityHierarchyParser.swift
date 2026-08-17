import Accessibility
import os.log
import SwiftUI
import UIKit

private let parserLog = OSLog(
    subsystem: "com.cashapp.AccessibilitySnapshot",
    category: "Parser"
)

public protocol UserInterfaceLayoutDirectionProviding {
    var userInterfaceLayoutDirection: UIUserInterfaceLayoutDirection { get }
}

extension UIApplication: UserInterfaceLayoutDirectionProviding {}

public protocol UserInterfaceIdiomProviding {
    var userInterfaceIdiom: UIUserInterfaceIdiom { get }
}

extension UIDevice: UserInterfaceIdiomProviding {}

// MARK: -

public final class AccessibilityHierarchyParser {
    // MARK: - Public Types

    /// Represents a context in which elements are contained.
    public enum Context {
        /// Indicates the element is part of a series of elements.
        /// Reads as "`index` of `count`."
        ///
        /// - `index`: The index of the item in the series.
        /// - `count`: The total number of items in the series.
        case series(index: Int, count: Int)

        /// Indicates the element is part of a series of tab bar items.
        /// Reads as "Tab. `index` of `count`."
        ///
        /// This is used for the items of a `UITabBar`. There is a similar context for tab bar items in a container with
        /// the `.tabBar` trait which behaves slightly differently. See `Context.tab`.
        ///
        /// - `index`: The index of this tab in the tab bar.
        /// - `count`: The total number of tabs in the tab bar.
        /// - `item`: The `UITabBarItem` representing this tab.
        case tabBarItem(index: Int, count: Int, item: UITabBarItem)

        /// Indicates the element is part of a series of tab bar items.
        /// Reads as "Tab. `index` of `count`."
        ///
        /// This is used for tab bars that use the `.tabBar` trait, not `UITabBar`s, which use a different mechanism for
        /// distinguishing their tabs. See `Context.tabBarItem`.
        ///
        /// - `index`: The index of this tab in the tab bar.
        /// - `count`: The total number of tabs in the tab bar.
        case tab(index: Int, count: Int)

        /// Indicates the element is a cell in a data table.
        ///
        /// - `row`: The row of the cell in the table.
        /// - `column`: The column of the cell in the table.
        /// - `width`: The number of columns the cell spans.
        /// - `height`: The number of rows the cell spans.
        /// - `isFirstInRow`: Whether or not the cell is the first in its row that VoiceOver will read.
        /// - `rowHeaders`: The cells for which row header data will be read for this cell.
        /// - `columnHeaders`: The cells for which column header data will be read for this cell.
        case dataTableCell(
            row: Int,
            column: Int,
            width: Int,
            height: Int,
            isFirstInRow: Bool,
            rowHeaders: [NSObject],
            columnHeaders: [NSObject]
        )

        /// Indicates the element is the first element in a list.
        case listStart

        /// Indicates the element is the last element in a list.
        ///
        /// If an element is the only element in the list, it will only get a `listStart` context.
        case listEnd

        /// Indicates the element is the first element in a landmark container.
        case landmarkStart

        /// Indicates the element is the last element in a landmark container.
        ///
        /// If an element is the only element in the landmark container, it will only get a `landmarkStart` context.
        case landmarkEnd
    }

    // MARK: - Life Cycle

    public init() {}

    // MARK: - Public Methods

    /// Parses the accessibility hierarchy starting from the `root` view and returns markers for each element in the
    /// hierarchy, in the order VoiceOver will iterate through them when using flick navigation.
    ///
    /// The returned `AccessibilityElement` objects include user input labels that are displayed based on the
    /// `AccessibilityContentDisplayMode` configuration set in the snapshot testing methods:
    /// - `.always`: Always includes user input labels in the markers, including default (derived) labels.
    /// - `.whenOverridden`: Includes labels only when they differ from default values.
    /// - `.never`: Never includes user input labels in the markers
    ///
    /// - parameter root: The root view of the accessibility hierarchy. Coordinates in the returned markers will be
    /// relative to this view's coordinate space.
    /// - parameter rotorResultLimit: Maximum number of rotor results to collect in each direction.
    /// Values less than or equal to 0 include rotor names only and do not evaluate rotor result blocks.
    /// Defaults to 10.
    /// - parameter userInterfaceLayoutDirectionProvider: The provider of the device's user interface layout direction.
    /// In most cases, this should use the default value, `UIApplication.shared`.
    @available(*, deprecated, message: "Use parseAccessibilityHierarchy(in:) and flattenToElements() instead")
    public func parseAccessibilityElements(
        in root: UIView,
        rotorResultLimit: Int = AccessibilityElement.defaultRotorResultLimit,
        userInterfaceLayoutDirectionProvider: UserInterfaceLayoutDirectionProviding = UIApplication.shared,
        userInterfaceIdiomProvider: UserInterfaceIdiomProviding = UIDevice.current
    ) -> [AccessibilityElement] {
        return parseAccessibilityHierarchy(
            in: root,
            rotorResultLimit: rotorResultLimit,
            userInterfaceLayoutDirectionProvider: userInterfaceLayoutDirectionProvider,
            userInterfaceIdiomProvider: userInterfaceIdiomProvider
        ).flattenToElements()
    }

    /// Parses the accessibility hierarchy starting from the `root` view and returns a tree structure
    /// with containers grouping their child elements.
    ///
    /// This method uses the same element parsing logic as `parseAccessibilityElements` but additionally
    /// tracks containers (semanticGroup, list, landmark, dataTable, tabBar) and nests elements within them.
    ///
    /// Container inclusion rules based on captured facts:
    /// - A container must have at least one accessible descendant to form a navigable boundary.
    /// - Any non-`.none` container role is included when it has descendants.
    /// - A `.none` container is included when it has descendants and an identifier, scrollable
    ///   content, a modal boundary, custom actions, or a tab-bar trait.
    /// - A `.none` container without any captured facts is transparent.
    ///
    /// Each element node includes a `traversalIndex` indicating its position in VoiceOver's navigation order.
    /// Use `flattenToElements()` on the result to get the same output as `parseAccessibilityElements`.
    ///
    /// - parameter root: The root view of the accessibility hierarchy
    /// - parameter rotorResultLimit: Maximum number of rotor results to collect in each direction.
    /// Values less than or equal to 0 include rotor names only and do not evaluate rotor result blocks.
    /// Defaults to 10.
    /// - parameter userInterfaceLayoutDirectionProvider: Provider of the device's UI layout direction
    /// - parameter userInterfaceIdiomProvider: Provider of the device's interface idiom
    /// - returns: Array of root-level hierarchy nodes with containers grouping their children
    public func parseAccessibilityHierarchy(
        in root: UIView,
        rotorResultLimit: Int = AccessibilityElement.defaultRotorResultLimit,
        userInterfaceLayoutDirectionProvider: UserInterfaceLayoutDirectionProviding = UIApplication.shared,
        userInterfaceIdiomProvider: UserInterfaceIdiomProviding = UIDevice.current
    ) -> [AccessibilityHierarchy] {
        parseAccessibilityHierarchy(
            in: root,
            rotorResultLimit: rotorResultLimit,
            userInterfaceLayoutDirectionProvider: userInterfaceLayoutDirectionProvider,
            userInterfaceIdiomProvider: userInterfaceIdiomProvider,
            makeElement: { element, traversalIndex, _ in .element(element, traversalIndex: traversalIndex) },
            makeContainer: { container, children, _ in .container(container, children: children) }
        )
    }

    /// Parses the accessibility hierarchy and folds it into a caller-defined node type.
    ///
    /// Walks the accessibility tree once in VoiceOver traversal order and builds a tree of `Node`
    /// values bottom-up. `makeElement` constructs a leaf from its parsed `AccessibilityElement`, its
    /// `traversalIndex`, and the live accessibility object that produced it. `makeContainer`
    /// constructs an interior node from its `AccessibilityContainer`, its already-built child nodes
    /// in traversal order, and the source object backing the container.
    ///
    /// The `source` parameters expose the originating accessibility object so callers can correlate
    /// parsed markers back to their source views — useful for test harnesses, debugging overlays,
    /// and custom renderers. `parseAccessibilityHierarchy(in:)` is the default instantiation,
    /// producing `[AccessibilityHierarchy]` and ignoring the source.
    ///
    /// Both closures are invoked synchronously during the walk, on the caller's thread.
    ///
    /// - parameter makeElement: Builds a leaf node. Called once per element, in traversal order.
    /// - parameter makeContainer: Builds an interior node from its children. Called once per container.
    public func parseAccessibilityHierarchy<Node>(
        in root: UIView,
        rotorResultLimit: Int = AccessibilityElement.defaultRotorResultLimit,
        userInterfaceLayoutDirectionProvider: UserInterfaceLayoutDirectionProviding = UIApplication.shared,
        userInterfaceIdiomProvider: UserInterfaceIdiomProviding = UIDevice.current,
        makeElement: (AccessibilityElement, _ traversalIndex: Int, _ source: NSObject) -> Node,
        makeContainer: (AccessibilityContainer, _ children: [Node], _ source: NSObject) -> Node
    ) -> [Node] {
        let userInterfaceLayoutDirection = userInterfaceLayoutDirectionProvider.userInterfaceLayoutDirection
        let userInterfaceIdiom = userInterfaceIdiomProvider.userInterfaceIdiom

        let accessibilityNodes = root.recursiveAccessibilityHierarchy(
            isRoot: true
        )

        let uncontextualizedElements = sortedElements(
            for: accessibilityNodes,
            explicitlyOrdered: false,
            in: root,
            userInterfaceLayoutDirection: userInterfaceLayoutDirection,
            userInterfaceIdiom: userInterfaceIdiom
        )

        // Tab context for `.tabBar`-trait views is derived from graph position: an element's tab
        // index/count come from its ordered position among the siblings that share the same
        // tab-bar-trait superview in the already-sorted traversal, rather than from a re-entrant
        // re-walk of that view's subtree.
        let tabTraitPositions = tabTraitPositions(in: uncontextualizedElements)

        let contextualizedElements = uncontextualizedElements.map { element in
            ContextualElement(
                object: element.object,
                context: derivedContext(
                    for: element.object,
                    parent: element.contextParent,
                    tabTraitPosition: tabTraitPositions[ObjectIdentifier(element.object)]
                )
            )
        }

        let elements: [AccessibilityElement] = zip(contextualizedElements, uncontextualizedElements).map { contextualized, sorted in
            buildElement(
                from: contextualized.object,
                context: contextualized.context,
                in: root,
                rotorResultLimit: rotorResultLimit,
                visibility: sorted.visibility
            )
        }

        return foldNodes(
            accessibilityNodes,
            sortedElements: uncontextualizedElements,
            elements: elements,
            in: root,
            makeElement: makeElement,
            makeContainer: makeContainer
        )
    }

    // MARK: - Private Types

    /// Representation of an accessibility element, made up of the element `object` itself and the `context` in which it
    /// is contained.
    private struct ContextualElement {
        var object: NSObject

        var context: Context?
    }

    /// The nearest ancestor that lends context to an element, captured once during the downward walk.
    ///
    /// This replaces the old re-entrant `ContextProvider` machinery: rather than looping back into the
    /// UIKit tree to recover an element's position, the parent — and, for enumerated accessibility
    /// containers, the element's position within that parent — is captured at enumeration time and the
    /// `Context` is derived purely from graph position afterwards.
    fileprivate struct ContextParent {
        /// The context-providing ancestor object (a `UISegmentedControl`, `UITabBar`, a `.tabBar`-trait
        /// view, a `.list`/`.landmark` container, or a `UIAccessibilityContainerDataTable`).
        let object: NSObject

        /// The element's index/count within `object` when `object` vends its children through the
        /// accessibility-container API (`accessibilityElements` / `accessibilityElement(at:)`). `nil`
        /// for superview- and data-table-sourced parents, whose positions are derived elsewhere.
        let capturedIndex: Int?
        let capturedCount: Int?

        init(object: NSObject, capturedIndex: Int? = nil, capturedCount: Int? = nil) {
            self.object = object
            self.capturedIndex = capturedIndex
            self.capturedCount = capturedCount
        }
    }

    // MARK: - Private Methods

    private func buildElement(
        from object: NSObject,
        context: Context?,
        in root: UIView,
        rotorResultLimit: Int,
        visibility: AccessibilityVisibility
    ) -> AccessibilityElement {
        let (description, _) = object.accessibilityDescription(context: context)
        let activationPoint = object.accessibilityActivationPoint

        return AccessibilityElement(
            description: description,
            label: object.accessibilityLabel,
            value: object.accessibilityValue,
            traits: AccessibilityTraits(object.accessibilityTraits),
            identifier: object.identifier,
            // Store the RAW author hint, not the parse-time-composed one. The trait-derived hint suffix
            // ("Double tap to toggle setting.", "Text field.", "Adjustable. …") is composed at delivery
            // by `description(context:verbosity:)`; baking it here too would double it when materialized.
            hint: object.accessibilityHint?.nonEmpty(),
            userInputLabels: object.authoredUserInputLabels,
            shape: Self.accessibilityShape(for: object, in: root),
            activationPoint: AccessibilityPoint(root.convert(activationPoint, from: nil)),
            usesDefaultActivationPoint: Self.usesDefaultActivationPoint(
                element: object,
                activationPoint: activationPoint,
                screenScale: (root.window?.screen ?? UIScreen.main).scale
            ),
            customActions: (object.accessibilityCustomActions ?? []).map { $0.name },
            customContent: object.customContent,
            customRotors: object.customRotors(in: root, context: context, resultLimit: rotorResultLimit),
            accessibilityLanguage: object.accessibilityLanguage,
            respondsToUserInteraction: object.accessibilityRespondsToUserInteraction,
            visibility: visibility
        )
    }

    /// Returns the elements in the provided `nodes` tree in the order in which VoiceOver will iterate through them.
    ///
    /// - parameter nodes: The nodes to sort.
    /// - parameter explicitlyOrdered: Whether or not the `nodes` are already sorted. Used for recursion. On first run,
    /// this should typically be `false`.
    /// - parameter root: The root view to which the nodes' shapes are relative.
    /// - parameter userInterfaceLayoutDirection: The device's current user interface layout direction.
    /// - parameter userInterfaceIdiom: the device's interface idiom, used to calculate the sort order
    private func sortedElements(
        for nodes: [AccessibilityNode],
        explicitlyOrdered: Bool,
        in root: UIView,
        userInterfaceLayoutDirection: UIUserInterfaceLayoutDirection,
        userInterfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
    ) -> [(object: NSObject, contextParent: ContextParent?, visibility: AccessibilityVisibility)] {
        // VoiceOver flick navigation iterates through elements in a horizontal, then vertical order. The horizontal
        // ordering matches the application's user interface layout direction. The vertical ordering is always
        // top-to-bottom. There are a couple exceptions to the order of iteration:
        //
        // - Elements inside of an accessibility container are grouped together, in the order specified by the
        //   container.
        // - Elements inside a view are grouped together when `shouldGroupAccessibilityChildren` is true, ordered within
        //   the group following the same ordering rules as top-level elements.
        //
        // In most cases, for both types of grouping, the placement of the group in the parent group is based on the
        // first element in the group that would be selected. The exception is for specific containers that use their
        // own accessibility frame as the determining factor of the position in the parent group.

        let horizontalCompare: (CGFloat, CGFloat) -> Bool
        switch userInterfaceLayoutDirection {
        case .leftToRight:
            horizontalCompare = (<)
        case .rightToLeft:
            horizontalCompare = (>)
        @unknown default:
            os_log(
                "Unknown UIUserInterfaceLayoutDirection (%{public}d); falling back to left-to-right ordering.",
                log: parserLog,
                type: .error,
                userInterfaceLayoutDirection.rawValue
            )
            horizontalCompare = (<)
        }

        // Derived via experimentation, these magic numbers are the cutoff for VoiceOver to consider
        // an element to be vertically "above" other views.
        let minimumVerticalSeparation = userInterfaceIdiom == .phone ? 8.0 : 13.0

        let sortedNodes = explicitlyOrdered ? nodes : nodes
            .map { ($0, Self.accessibilitySortFrame(for: $0, in: root, horizontalCompare: horizontalCompare, minimumVerticalSeparation: minimumVerticalSeparation)) }
            .sorted { obj1, obj2 in
                let origin1 = obj1.1.origin
                let origin2 = obj2.1.origin

                if origin1.y != origin2.y, abs(origin1.y - origin2.y) >= minimumVerticalSeparation {
                    return origin1.y < origin2.y
                }

                return horizontalCompare(origin1.x, origin2.x)
            }
            .map { $0.0 }

        var sortedElements: [(object: NSObject, contextParent: ContextParent?, visibility: AccessibilityVisibility)] = []

        for node in sortedNodes {
            switch node {
            case let .element(element, contextParent, visibility):
                sortedElements.append((object: element, contextParent: contextParent, visibility: visibility))

            case let .group(elements, explicitlyOrdered, _, _):
                sortedElements.append(
                    contentsOf: self.sortedElements(
                        for: elements,
                        explicitlyOrdered: explicitlyOrdered,
                        in: root,
                        userInterfaceLayoutDirection: userInterfaceLayoutDirection,
                        userInterfaceIdiom: userInterfaceIdiom
                    )
                )
            }
        }

        return sortedElements
    }

    /// Position of an element within its `.tabBar`-trait ancestor, derived from the sorted
    /// traversal order (1-based index and total count of tab siblings).
    private struct TabTraitPosition {
        var index: Int
        var count: Int
    }

    /// Derives, for every element whose context parent is a `.tabBar`-trait view, its ordered
    /// position among the siblings that share that same parent. The sorted element list already
    /// reflects VoiceOver's flick order, so an element's index within its tab-bar group is simply its
    /// rank among the contiguous siblings sharing that parent — no re-walk of the view subtree.
    private func tabTraitPositions(
        in elements: [(object: NSObject, contextParent: ContextParent?, visibility: AccessibilityVisibility)]
    ) -> [ObjectIdentifier: TabTraitPosition] {
        // Group tab-trait elements by their providing view, preserving sorted order.
        var groups: [ObjectIdentifier: [NSObject]] = [:]
        for element in elements {
            guard let parent = element.contextParent?.object as? UIView,
                  parent.accessibilityTraits.contains(.tabBar),
                  !(parent is UITabBar)
            else {
                continue
            }
            groups[ObjectIdentifier(parent), default: []].append(element.object)
        }

        var positions: [ObjectIdentifier: TabTraitPosition] = [:]
        for (_, siblings) in groups {
            for (index, object) in siblings.enumerated() {
                positions[ObjectIdentifier(object)] = TabTraitPosition(index: index + 1, count: siblings.count)
            }
        }
        return positions
    }

    /// Derives an element's `Context` purely from its graph position: the role of its captured
    /// context parent plus its position within that parent. Replaces the old provider-driven
    /// `context(for:from:)`.
    private func derivedContext(
        for element: NSObject,
        parent: ContextParent?,
        tabTraitPosition: TabTraitPosition?
    ) -> Context? {
        guard let parent = parent else {
            return nil
        }

        let parentObject = parent.object

        // UITabBar: derive the tab index from the tab-bar button ordering and the item count.
        if let tabBar = parentObject as? UITabBar, let element = element as? UIView {
            let tabBarButtons = tabBar.allUITabBarButtons()
            let tabBarItems = tabBar.items ?? []

            // An unexpected tab bar shape — no items, a button count that isn't a multiple of the
            // item count, or a button that isn't in our list — should not crash the process. Skip
            // context for this element instead; it will still be parsed.
            //
            // Some UIKit tab bars expose multiple button sets at different levels in the view
            // hierarchy, so the total count may be a multiple of the item count.
            guard !tabBarItems.isEmpty,
                  tabBarButtons.count % tabBarItems.count == 0,
                  let index = tabBarButtons.firstIndex(of: element)
            else {
                os_log(
                    "UITabBar has an unexpected shape (buttons=%{public}d, items=%{public}d); dropping tab-bar context for element.",
                    log: parserLog,
                    type: .error,
                    tabBarButtons.count,
                    tabBarItems.count
                )
                return nil
            }

            let tabIndex = index % tabBarItems.count

            return .tabBarItem(
                index: tabIndex + 1,
                count: tabBarItems.count,
                item: tabBarItems[tabIndex]
            )
        }

        // A view that is not a `UITabBar` but carries the `.tabBar` trait treats every element in its
        // subtree as a tab. The index/count come from the element's ordered position among its
        // tab-bar-trait siblings in the sorted traversal.
        if let parentView = parentObject as? UIView,
           parentView.accessibilityTraits.contains(.tabBar),
           element is UIView
        {
            guard let tabTraitPosition = tabTraitPosition else {
                os_log(
                    "Tab-bar-trait view does not contain the element being parsed; dropping tab context.",
                    log: parserLog,
                    type: .error
                )
                return nil
            }
            return .tab(index: tabTraitPosition.index, count: tabTraitPosition.count)
        }

        // Data tables derive per-cell context from the same live-table facts the node payload stores.
        if let dataTable = parentObject as? UIAccessibilityContainerDataTable,
           parentObject.accessibilityContainerType == .dataTable
        {
            return dataTableCellContext(for: element, in: dataTable)
        }

        // Accessibility containers (segmented controls, lists, landmarks) vend their children through
        // the container API. The child's index/count were captured at enumeration time — i.e. its
        // ordered graph position — so no live re-query is needed.
        let elementIndex = parent.capturedIndex ?? parentObject.index(ofAccessibilityElement: element)
        let elementCount = parent.capturedCount ?? parentObject.accessibilityElementCount()

        // The container may not actually contain the element if its accessibility tree is in an
        // inconsistent state. Drop context for this element rather than crashing.
        guard elementIndex != NSNotFound,
              elementIndex >= 0,
              elementCount > 0,
              elementIndex < elementCount
        else {
            os_log(
                "Accessibility container reported NSNotFound for an element it advertises; dropping container context.",
                log: parserLog,
                type: .error
            )
            return nil
        }

        if parentObject is UISegmentedControl {
            return .series(index: elementIndex + 1, count: elementCount)
        }

        if parentObject.accessibilityTraits.contains(.tabBar) {
            return .tab(index: elementIndex + 1, count: elementCount)
        }

        if parentObject.accessibilityContainerType == .list {
            if elementIndex == 0 {
                return .listStart
            } else if elementIndex == elementCount - 1 {
                return .listEnd
            }
        }

        if parentObject.accessibilityContainerType == .landmark {
            if elementIndex == 0 {
                return .landmarkStart
            } else if elementIndex == elementCount - 1 {
                return .landmarkEnd
            }
        }

        return nil
    }

    /// Derives the `.dataTableCell` context for a cell from the live data table, using the same
    /// filtering rules as the stored node payload (see `dataTableCells(for:orderedSources:)`).
    private func dataTableCellContext(
        for element: NSObject,
        in dataTable: UIAccessibilityContainerDataTable
    ) -> Context? {
        guard let cell = element as? UIAccessibilityContainerDataTableCell else {
            return nil
        }

        let rowRange = cell.accessibilityRowRange()
        let row = rowRange.location

        let columnRange = cell.accessibilityColumnRange()
        let column = columnRange.location

        // TODO: Seems like it uses the actual position of the cell to figure out the first element, rather than
        // finding a cell with an earlier index. Specifically, this affects the case where a cell has a column
        // of `NSNotFound`, but may also apply to other situations.
        let isFirstInRow = column != NSNotFound
            && row != NSNotFound
            && !(0 ..< columnRange.location).contains {
                dataTable.accessibilityDataTableCellElement(forRow: rowRange.location, column: $0) != nil
            }

        let rowHeaders: [NSObject]
        if isFirstInRow, let allHeaders = dataTable.accessibilityHeaderElements?(forRow: row) {
            rowHeaders = allHeaders.filter { header in
                true
                    // The cell is not read as a header for itself.
                    && header !== cell
                    // The header is not read if it is not a cell in the table.
                    && dataTable.accessibilityDataTableCellElement(forRow: header.accessibilityRowRange().location, column: header.accessibilityColumnRange().location) === header
            }.compactMap { $0 as? NSObject }

        } else {
            rowHeaders = []
        }

        let columnHeaders: [NSObject]
        if let allHeaders = dataTable.accessibilityHeaderElements?(forColumn: column) {
            columnHeaders = allHeaders.filter { header in
                let headerRow = header.accessibilityRowRange().location
                let headerColumn = header.accessibilityColumnRange().location

                // The header is not read as a header for itself.
                if header === cell {
                    return false
                }

                // The header is not read if it is immediately preceding the cell if the cell is the first in
                // its row.
                if row != NSNotFound, headerRow == row - 1, headerColumn == column, isFirstInRow {
                    return false
                }

                return true
            }.compactMap { $0 as? NSObject }

        } else {
            columnHeaders = []
        }

        return .dataTableCell(
            row: row,
            column: column,
            width: columnRange.length,
            height: rowRange.length,
            isFirstInRow: isFirstInRow,
            rowHeaders: rowHeaders,
            columnHeaders: columnHeaders
        )
    }

    // MARK: - Private Hierarchy Methods

    /// Folds the structural accessibility tree into a caller-defined `Node` type, bottom-up.
    ///
    /// Each produced node is paired internally with a traversal-derived sort key so that a
    /// container can order its children without inspecting the opaque `Node`. This mirrors
    /// `AccessibilityHierarchy.sortIndex`: an element sorts by its `traversalIndex`, a container by
    /// the minimum sort key among its children.
    private func foldNodes<Node>(
        _ nodes: [AccessibilityNode],
        sortedElements: [(object: NSObject, contextParent: ContextParent?, visibility: AccessibilityVisibility)],
        elements: [AccessibilityElement],
        in root: UIView,
        makeElement: (AccessibilityElement, _ traversalIndex: Int, _ source: NSObject) -> Node,
        makeContainer: (AccessibilityContainer, _ children: [Node], _ source: NSObject) -> Node
    ) -> [Node] {
        var indexLookup: [ObjectIdentifier: Int] = [:]
        for (index, element) in sortedElements.enumerated() {
            indexLookup[ObjectIdentifier(element.object)] = index
        }

        func mapNode(_ node: AccessibilityNode) -> [(node: Node, sortIndex: Int, source: NSObject?)] {
            switch node {
            case let .element(object, _, _):
                guard let index = indexLookup[ObjectIdentifier(object)],
                      index < elements.count else { return [] }
                return [(makeElement(elements[index], index, object), index, object)]

            case let .group(children, _, _, containerInfo):
                let mappedChildren = children.flatMap { mapNode($0) }.sorted { lhs, rhs in
                    lhs.sortIndex < rhs.sortIndex
                }

                if let info = containerInfo {
                    let frame = AccessibilityRect(root.convert(info.view.bounds, from: info.view))

                    let childSources = mappedChildren.compactMap(\.source)
                    let hasTabBarItemChildren = childSources.contains {
                        $0.accessibilityTraits.contains(.tabBarItemTrait)
                    }

                    let containerType: AccessibilityContainer.ContainerType
                    if info.traits.contains(.tabBar) || hasTabBarItemChildren {
                        // A tab bar is identified class-free as a container whose children carry the
                        // private `.tabBarItem` trait (bit 28) — no `is UITabBar` check. A real
                        // `UITabBar` reports `accessibilityContainerType == .semanticGroup` and lacks
                        // the `.tabBar` trait, so the children-trait rule is what recognizes it; custom
                        // `.tabBar`-trait views are still matched by the trait.
                        containerType = .tabBar
                    } else if info.type == .segmentedControlContainerType {
                        // A `UISegmentedControl` reports the private container type 11 (outside the
                        // public 0–4 enum), read here via the public `accessibilityContainerType`
                        // property — no `is UISegmentedControl` class check. Its segments render as a
                        // `.series` ("Segment A. Button. 1 of 3."), keeping the Button trait.
                        containerType = .series
                    } else {
                        switch info.type {
                        case .semanticGroup:
                            containerType = .semanticGroup(label: info.label, value: info.value)
                        case .list:
                            containerType = .list
                        case .landmark:
                            containerType = .landmark
                        case .dataTable:
                            let cells = dataTableCells(
                                for: info.view as? UIAccessibilityContainerDataTable,
                                orderedSources: mappedChildren.map(\.source)
                            )
                            containerType = .dataTable(
                                rowCount: info.rowCount ?? 0,
                                columnCount: info.columnCount ?? 0,
                                cells: cells
                            )
                        case .none:
                            containerType = .none
                        @unknown default:
                            containerType = .none
                        }
                    }

                    let container = AccessibilityContainer(
                        type: containerType,
                        identifier: info.identifier,
                        scrollableContentSize: info.scrollableContentSize.map(AccessibilitySize.init),
                        frame: frame,
                        isModalBoundary: info.isModalBoundary,
                        customActions: info.customActions
                    )
                    let sortIndex = mappedChildren.map(\.sortIndex).min() ?? Int.max
                    return [(makeContainer(container, mappedChildren.map(\.node), info.view), sortIndex, info.view)]
                }

                return mappedChildren
            }
        }

        return nodes.flatMap { mapNode($0) }.map(\.node)
    }

    /// Captures the per-cell grid facts for a data table once, at node-emission time, aligned to the
    /// container node's ordered children. `orderedSources` is the source object backing each child in
    /// traversal order (the same order the node's `children` are stored in); a `nil` source (or a
    /// source that is not a data-table cell) yields a `nil` entry.
    ///
    /// The `isFirstInRow` flag and the header lists are computed here using the exact filtering rules
    /// the description path uses (the `NSNotFound` rule and the immediately-preceding-header rule),
    /// then stored on the node so cell context can be derived at delivery from the graph alone. Header
    /// references are resolved to indices into `orderedSources` so that no live table object is
    /// retained.
    private func dataTableCells(
        for dataTable: UIAccessibilityContainerDataTable?,
        orderedSources: [NSObject?]
    ) -> [AccessibilityContainer.DataTableCellInfo?] {
        guard let dataTable else {
            return Array(repeating: nil, count: orderedSources.count)
        }

        // Map each cell source object to its index among the ordered children so header references
        // can be stored as child indices.
        var indexBySource: [ObjectIdentifier: Int] = [:]
        for (index, source) in orderedSources.enumerated() {
            if let source {
                indexBySource[ObjectIdentifier(source)] = index
            }
        }

        func childIndices(of headers: [NSObject]) -> [Int] {
            headers.compactMap { indexBySource[ObjectIdentifier($0)] }
        }

        return orderedSources.map { source -> AccessibilityContainer.DataTableCellInfo? in
            guard let cell = source as? UIAccessibilityContainerDataTableCell else {
                return nil
            }

            let rowRange = cell.accessibilityRowRange()
            let row = rowRange.location

            let columnRange = cell.accessibilityColumnRange()
            let column = columnRange.location

            // Mirrors the description path: the first cell in a row is the earliest-columned cell
            // VoiceOver will read. A cell with a column of `NSNotFound` is never first-in-row.
            let isFirstInRow = column != NSNotFound
                && row != NSNotFound
                && !(0 ..< columnRange.location).contains {
                    dataTable.accessibilityDataTableCellElement(forRow: rowRange.location, column: $0) != nil
                }

            let rowHeaders: [NSObject]
            if isFirstInRow, let allHeaders = dataTable.accessibilityHeaderElements?(forRow: row) {
                rowHeaders = allHeaders.filter { header in
                    true
                        // The cell is not read as a header for itself.
                        && header !== cell
                        // The header is not read if it is not a cell in the table.
                        && dataTable.accessibilityDataTableCellElement(forRow: header.accessibilityRowRange().location, column: header.accessibilityColumnRange().location) === header
                }.compactMap { $0 as? NSObject }
            } else {
                rowHeaders = []
            }

            let columnHeaders: [NSObject]
            if let allHeaders = dataTable.accessibilityHeaderElements?(forColumn: column) {
                columnHeaders = allHeaders.filter { header in
                    let headerRow = header.accessibilityRowRange().location
                    let headerColumn = header.accessibilityColumnRange().location

                    // The header is not read as a header for itself.
                    if header === cell {
                        return false
                    }

                    // The header is not read if it is immediately preceding the cell when the cell is
                    // the first in its row.
                    if row != NSNotFound, headerRow == row - 1, headerColumn == column, isFirstInRow {
                        return false
                    }

                    return true
                }.compactMap { $0 as? NSObject }
            } else {
                columnHeaders = []
            }

            return AccessibilityContainer.DataTableCellInfo(
                row: row,
                column: column,
                rowSpan: rowRange.length,
                columnSpan: columnRange.length,
                isFirstInRow: isFirstInRow,
                rowHeaderChildIndices: childIndices(of: rowHeaders),
                columnHeaderChildIndices: childIndices(of: columnHeaders)
            )
        }
    }
}

// MARK: - Internal Helpers

extension AccessibilityHierarchyParser {
    /// Returns the shape of the accessibility element in the root view's coordinate space.
    /// VoiceOver prefers an accessibilityPath if available when drawing the bounding box, but the accessibilityFrame is always used for sort order.
    static func accessibilityShape(for element: NSObject, in root: UIView, preferPath: Bool = true) -> AccessibilityShape {
        if let accessibilityPath = element.accessibilityPath, preferPath, accessibilityPath.hasFiniteBounds {
            let converted = root.convert(accessibilityPath, from: nil)
            return .path(AccessibilityPathElement.elements(from: converted.cgPath))

        } else if let element = element as? UIAccessibilityElement, let container = element.accessibilityContainer, !element.accessibilityFrameInContainerSpace.isNull {
            return .frame(finiteAccessibilityRect(container.convert(element.accessibilityFrameInContainerSpace, to: root)))

        } else {
            return .frame(finiteAccessibilityRect(root.convert(element.accessibilityFrame, from: nil)))
        }
    }

    /// Determines whether an element is using its default activation point.
    ///
    /// When both the activation point and frame are zero, the element hasn't set a custom activation
    /// point — it's just reporting the default for a zero frame. This can happen with SwiftUI elements
    /// whose `accessibilityFrame` is `.zero`.
    static func usesDefaultActivationPoint(
        element: NSObject,
        activationPoint: CGPoint,
        screenScale: CGFloat
    ) -> Bool {
        if activationPoint == .zero && element.accessibilityFrame == .zero {
            return true
        }

        return activationPoint.approximatelyEquals(
            defaultActivationPoint(for: element),
            tolerance: 1 / screenScale
        )
    }

    /// Returns the effective screen-coordinate frame for an accessibility element.
    ///
    /// Some SwiftUI elements provide an `accessibilityPath` but report a zero `accessibilityFrame`.
    /// In those cases, the path bounds (which are already in screen coordinates) are used instead.
    static func effectiveAccessibilityFrame(for element: NSObject) -> CGRect {
        let frame = element.accessibilityFrame
        if frame.hasFiniteGeometry, !frame.isEmpty {
            return frame
        }

        if let path = element.accessibilityPath, path.hasFiniteBounds {
            return path.cgPath.boundingBoxOfPath
        }

        if let view = element as? UIView,
           view.window == nil,
           view.frame.hasFiniteGeometry,
           !view.frame.isEmpty
        {
            return view.frame
        }

        return frame.hasFiniteGeometry ? frame : .zero
    }

    static func finiteAccessibilityRect(_ rect: CGRect) -> AccessibilityRect {
        rect.hasFiniteGeometry ? AccessibilityRect(rect) : .zero
    }

    /// Returns the default value for an element's `accessibilityActivationPoint`.
    static func defaultActivationPoint(for element: NSObject) -> CGPoint {
        if let element = element as? UISlider {
            let bounds = element.bounds
            let trackRect = element.trackRect(forBounds: bounds)
            let thumbRect = element.thumbRect(forBounds: bounds, trackRect: trackRect, value: element.value)
            let thumbAccessibilityFrame = UIAccessibility.convertToScreenCoordinates(thumbRect, in: element)

            return CGPoint(x: thumbAccessibilityFrame.midX, y: thumbAccessibilityFrame.midY)
        }

        // By default, an element's activation point is the center of its accessibility frame, regardless of whether it
        // uses an accessibility path or frame as its shape.
        let frame = effectiveAccessibilityFrame(for: element)
        return CGPoint(x: frame.midX, y: frame.midY)
    }
}

// MARK: - Fileprivate Helpers

private extension AccessibilityHierarchyParser {
    /// Returns a CGRect that can be used for sorting by position.
    static func accessibilitySortFrame(
        for node: AccessibilityNode,
        in root: UIView,
        horizontalCompare: @escaping (CGFloat, CGFloat) -> Bool,
        minimumVerticalSeparation: CGFloat
    ) -> CGRect {
        switch node {
        case let .element(frameProvider, _, _),
             let .group(_, _, frameProvider?, _):
            switch accessibilityShape(for: frameProvider, in: root, preferPath: false) {
            case let .frame(rect):
                return rect.cgRect
            default:
                return frameProvider.accessibilityFrame
            }

        case let .group(elements, _, _, _):
            // Matches VoiceOver behavior: groups sort by their first-selected child
            // using the same thresholded comparator as sortedElements.
            return elements
                .map { accessibilitySortFrame(for: $0, in: root, horizontalCompare: horizontalCompare, minimumVerticalSeparation: minimumVerticalSeparation) }
                .min { f1, f2 in
                    if f1.origin.y != f2.origin.y, abs(f1.origin.y - f2.origin.y) >= minimumVerticalSeparation {
                        return f1.origin.y < f2.origin.y
                    }
                    return horizontalCompare(f1.origin.x, f2.origin.x)
                } ?? .null
        }
    }
}

// MARK: -

extension UIBezierPath {
    /// True when the path is non-empty and its CGPath bounding box has finite
    /// origin and size.
    ///
    /// `UIBezierPath.bounds` calls `CGPathGetPathBoundingBox`, which returns
    /// `CGRect.null` (origin `.infinity`) for empty paths and may carry
    /// non-finite values when callers feed in `.nan`/`.infinity`. Storing
    /// such a path in `Shape.path` lets those values flow into downstream
    /// `Int(_:)` conversions and trap with a Swift runtime SIGTRAP. Callers
    /// gate `.path(...)` on this check and fall back to `.frame(...)`.
    var hasFiniteBounds: Bool {
        guard !isEmpty else { return false }
        let rect = cgPath.boundingBoxOfPath
        return !rect.isNull
            && rect.origin.x.isFinite
            && rect.origin.y.isFinite
            && rect.size.width.isFinite
            && rect.size.height.isFinite
    }
}

private extension CGSize {
    func isScrollableContentSize(for containerSize: CGSize, tolerance: CGFloat = 0.5) -> Bool {
        guard isFinite, containerSize.isFinite else {
            return false
        }

        return width > containerSize.width + tolerance
            || height > containerSize.height + tolerance
    }

    var isFinite: Bool {
        width.isFinite && height.isFinite
    }
}

private extension CGRect {
    var hasFiniteGeometry: Bool {
        !isNull
            && origin.x.isFinite
            && origin.y.isFinite
            && size.width.isFinite
            && size.height.isFinite
    }
}

/// Captures container information at node creation time, avoiding the need to re-derive it later.
private struct ContainerInfo {
    let view: UIView
    let type: UIAccessibilityContainerType
    let label: String?
    let value: String?
    let identifier: String?
    let traits: UIAccessibilityTraits
    let scrollableContentSize: CGSize?
    let rowCount: Int?
    let columnCount: Int?
    let isModalBoundary: Bool
    let customActions: [AccessibilityElement.CustomAction]
}

private enum AccessibilityNode {
    /// Represents a single accessibility element.
    ///
    /// `visibility` records whether the element's frame intersects the visible region of its
    /// scrollable ancestors at parse time. The parser always walks the full tree and stamps this
    /// flag rather than pruning off-screen elements, so trimming becomes a delivery-time decision.
    case element(NSObject, contextParent: AccessibilityHierarchyParser.ContextParent?, visibility: AccessibilityVisibility)

    /// Represents a group of accessibility elements (or nested groups) that should be iterated through together,
    /// without interspersing other elements.
    ///
    /// - `explicitlyOrdered`: Whether the order of the elements in the group has already been established. When false,
    /// the elements will be sorted by their bounding box.
    /// - `frameOverrideProvider`: The object whose accessibility frame is used to determine the group's ordering in the
    /// accessibility hierarchy. When `nil`, the group is ordered according to the first element in the group that would
    /// be selected.
    /// - `container`: Container info if this group represents a meaningful accessibility container.
    case group([AccessibilityNode], explicitlyOrdered: Bool, frameOverrideProvider: NSObject?, container: ContainerInfo?)

    /// Whether this node contains at least one parsed accessibility element below it.
    var containsAccessibleElement: Bool {
        switch self {
        case .element:
            return true
        case let .group(children, _, _, _):
            return children.contains { $0.containsAccessibleElement }
        }
    }
}

// MARK: -

private extension NSObject {
    /// Recursively parses the accessibility elements/containers on the screen.
    ///
    /// Note that the order the nodes are returned in does not reflect the order that VoiceOver will iterate through
    /// them.
    func recursiveAccessibilityHierarchy(
        contextParent: AccessibilityHierarchyParser.ContextParent? = nil,
        isRoot: Bool = false,
        inheritsOffscreen: Bool = false
    ) -> [AccessibilityNode] {
        guard !accessibilityElementsHidden else {
            return []
        }

        // Off-screen-ness is metadata, not a prune: the parser keeps descending and stamps each
        // element with a visibility flag. `inheritsOffscreen` carries an ancestor's off-screen state
        // down so descendants of an off-screen view are themselves off-screen — reproducing today's
        // descent-gating as a flag instead of a `return []`.
        var isOffscreen = inheritsOffscreen

        if let `self` = self as? UIView {
            if self.isHidden || self.alpha <= 0 {
                return []
            }

            if !isRoot, self.frame.size == .zero, self.clipsToBounds {
                return []
            }

            let accessibilityFrame = AccessibilityHierarchyParser.effectiveAccessibilityFrame(for: self)
            if !isRoot, shouldGateOnAccessibilityFrame, accessibilityFrame.width < 1, accessibilityFrame.height < 1 {
                return []
            }

            if !isRoot, !self.hasVisibleFrame() {
                isOffscreen = true
            }
        }

        var recursiveAccessibilityHierarchy: [AccessibilityNode] = []

        if isAccessibilityElement, !hasTableBoundary {
            if !isOffscreen, !(self is UIView) {
                // A framed non-UIView element clipped out by a scrollable ancestor is marked
                // off-screen rather than pruned.
                let frame = accessibilityFrame
                if frame.width > 0, frame.height > 0 {
                    if let containerView = nearestContainerView(for: self),
                       containerView.window != nil
                    {
                        let clipped = clipFrameAgainstAncestors(frame, startingFrom: containerView)
                        if clipped.isNull || clipped.width <= visibleFrameMinDimension || clipped.height <= visibleFrameMinDimension {
                            isOffscreen = true
                        }
                    }
                } else {
                    // A non-UIView *leaf* that reports no frame during the walk has no visible
                    // presence, so it is off-screen. (An off-screen UITableViewCellAccessibilityElement
                    // whose cell isn't instantiated reports a zero frame here.) This branch is reached
                    // only for leaves — a zero-frame *container* wrapper is `!isAccessibilityElement`
                    // and passes its visible children through elsewhere, unaffected.
                    isOffscreen = true
                }
            }
            recursiveAccessibilityHierarchy.append(
                .element(self, contextParent: contextParent, visibility: isOffscreen ? .offscreen : .onscreen)
            )

        } else if let accessibilityElements = resolvedAccessibilityElements(
            allowContainerFallback: shouldUseAccessibilityContainerElements
        ) {
            var accessibilityHierarchyOfElements: [AccessibilityNode] = []
            let tableView = self as? UITableView
            let headerView = tableView?.tableHeaderView
            let footerView = tableView?.tableFooterView
            let boundaryContextParent = contextParent ?? superviewContextParent()

            let vendedElements = accessibilityElements.filter { element in
                element !== headerView && element !== footerView
            }
            for (index, element) in vendedElements.enumerated() {
                // The enumeration index/count are the child's ordered graph position, captured here so
                // context can be derived without re-querying the live container later.
                let childContextParent = contextParent ?? (
                    providesContext
                        ? AccessibilityHierarchyParser.ContextParent(
                            object: self,
                            capturedIndex: index,
                            capturedCount: vendedElements.count
                        )
                        : nil
                )
                accessibilityHierarchyOfElements.append(
                    contentsOf: element.recursiveAccessibilityHierarchy(
                        contextParent: childContextParent,
                        isRoot: false,
                        inheritsOffscreen: isOffscreen
                    )
                )
            }
            let vendedContainer = (self as? UIView).flatMap {
                containerInfo(
                    for: $0,
                    hasAccessibleDescendants: accessibilityHierarchyOfElements.contains { $0.containsAccessibleElement }
                )
            }
            let vendedGroup = AccessibilityNode.group(
                accessibilityHierarchyOfElements,
                explicitlyOrdered: true,
                frameOverrideProvider: nil,
                container: vendedContainer
            )
            var tableHierarchy: [AccessibilityNode] = []
            if let headerView {
                tableHierarchy.append(
                    contentsOf: headerView.recursiveAccessibilityHierarchy(
                        contextParent: boundaryContextParent,
                        isRoot: false,
                        inheritsOffscreen: isOffscreen
                    )
                )
            }
            tableHierarchy.append(vendedGroup)
            if let footerView {
                tableHierarchy.append(
                    contentsOf: footerView.recursiveAccessibilityHierarchy(
                        contextParent: boundaryContextParent,
                        isRoot: false,
                        inheritsOffscreen: isOffscreen
                    )
                )
            }

            recursiveAccessibilityHierarchy.append(.group(
                tableHierarchy,
                explicitlyOrdered: true,
                frameOverrideProvider: overridesElementFrame(with: contextParent) ? self : nil,
                container: nil
            ))

        } else if let `self` = self as? UIView {
            // If there is at least one modal subview, parse from the last modal
            // subview forward. UIKit popovers can expose an empty modal dismiss
            // region as a sibling before the actual popover controls; limiting
            // traversal to only that dismiss region drops the presented content.
            // Siblings before the modal marker remain background content.
            let subviewsToParse: [UIView]
            if let lastModalIndex = self.subviews.lastIndex(where: { $0.accessibilityViewIsModal }) {
                subviewsToParse = Array(self.subviews[lastModalIndex...])
            } else {
                subviewsToParse = self.subviews
            }

            var accessibilityHierarchyOfSubviews: [AccessibilityNode] = []
            for subview in subviewsToParse {
                accessibilityHierarchyOfSubviews.append(
                    contentsOf: subview.recursiveAccessibilityHierarchy(
                        contextParent: contextParent ?? superviewContextParent(),
                        isRoot: false,
                        inheritsOffscreen: isOffscreen
                    )
                )
            }

            let container = containerInfo(
                for: self,
                hasAccessibleDescendants: accessibilityHierarchyOfSubviews.contains { $0.containsAccessibleElement }
            )

            if shouldGroupAccessibilityChildren || container != nil {
                recursiveAccessibilityHierarchy.append(
                    .group(accessibilityHierarchyOfSubviews, explicitlyOrdered: false, frameOverrideProvider: nil, container: container)
                )
            } else {
                recursiveAccessibilityHierarchy.append(contentsOf: accessibilityHierarchyOfSubviews)
            }
        }

        return recursiveAccessibilityHierarchy
    }

    private func resolvedAccessibilityElements(allowContainerFallback: Bool = true) -> [NSObject]? {
        if let elements = accessibilityElements as? [NSObject] {
            return elements
        }

        guard allowContainerFallback else {
            return nil
        }

        let count = accessibilityElementCount()
        guard count != NSNotFound else {
            return nil
        }

        if count == 0 {
            return hasTableBoundary ? [] : nil
        }

        var elements: [NSObject] = []
        elements.reserveCapacity(count)
        for index in 0 ..< count {
            if let element = accessibilityElement(at: index) as? NSObject {
                elements.append(element)
            }
        }
        return elements.isEmpty ? nil : elements
    }

    private var shouldUseAccessibilityContainerElements: Bool {
        if self is UIView {
            // Scroll views (UITableView/UICollectionView) vend all their rows — including
            // off-screen ones — through the index API, the way VoiceOver enumerates them.
            // Plain UIViews are walked via subviews (their index API is a no-op).
            if self is UIScrollView, !isAccessibilityElement || hasTableBoundary {
                let count = accessibilityElementCount()
                return count != NSNotFound && (count > 0 || hasTableBoundary)
            }
            return false
        }
        if isAccessibilityElement {
            return false
        }
        return accessibilityElementCount() != NSNotFound
    }

    private var hasTableBoundary: Bool {
        guard let tableView = self as? UITableView else {
            return false
        }
        return tableView.tableHeaderView != nil || tableView.tableFooterView != nil
    }

    private var shouldGateOnAccessibilityFrame: Bool {
        isAccessibilityElement || accessibilityElements != nil
    }

    private func containerInfo(for view: UIView, hasAccessibleDescendants: Bool) -> ContainerInfo? {
        let containerType = view.accessibilityContainerType
        let traits = view.accessibilityTraits
        let label = view.accessibilityLabel
        let value = view.accessibilityValue
        let identifier = (view as UIAccessibilityIdentification).accessibilityIdentifier
        let isModalBoundary = view.accessibilityViewIsModal

        let (rowCount, columnCount): (Int?, Int?) = {
            guard containerType == .dataTable,
                  let dataTable = view as? UIAccessibilityContainerDataTable
            else {
                return (nil, nil)
            }
            return (dataTable.accessibilityRowCount(), dataTable.accessibilityColumnCount())
        }()

        let scrollableContentSize = scrollableContentSize(for: view)
        let customActions = view.accessibilityCustomActions?.map { $0.name } ?? []
        let hasContainerRole = containerType != .none
        let hasContainerFacts = identifier?.isEmpty == false
            || scrollableContentSize != nil
            || isModalBoundary
            || !customActions.isEmpty
            || traits.contains(.tabBar)
        let shouldEmitContainer = hasAccessibleDescendants && (hasContainerRole || hasContainerFacts)

        guard shouldEmitContainer else {
            return nil
        }

        return ContainerInfo(
            view: view,
            type: containerType,
            label: label,
            value: value,
            identifier: identifier,
            traits: traits,
            scrollableContentSize: scrollableContentSize,
            rowCount: rowCount,
            columnCount: columnCount,
            isModalBoundary: isModalBoundary,
            customActions: customActions
        )
    }

    /// Returns scrollable content size only when the content exceeds the view's bounds.
    ///
    /// UIKit and SwiftUI can expose nested scroll wrappers that are marked scrollable even when
    /// their content cannot move. Treating those wrappers as transparent preserves their children
    /// without creating duplicate scrollable containers for the same visual frame.
    private func scrollableContentSize(for view: UIView) -> CGSize? {
        if let scrollView = view as? UIScrollView {
            guard scrollView.isScrollEnabled else {
                return nil
            }
            return scrollView.contentSize.isScrollableContentSize(for: view.bounds.size) ? scrollView.contentSize : nil
        }

        guard let scrollView = view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView else {
            return nil
        }
        guard scrollView.isScrollEnabled else {
            return nil
        }

        return scrollView.contentSize.isScrollableContentSize(for: view.bounds.size) ? scrollView.contentSize : nil
    }

    /// Whether or not the object provides context to elements beneath it in the hierarchy.
    private var providesContext: Bool {
        return self is UISegmentedControl
            || self is UITabBar
            || accessibilityTraits.contains(.tabBar)
            || accessibilityContainerType == .list
            || accessibilityContainerType == .landmark
            || (self is UIAccessibilityContainerDataTable && accessibilityContainerType == .dataTable)
    }

    /// The context parent this object lends to elements beneath it in the *view* hierarchy (i.e. when
    /// it vends its children as subviews rather than through the accessibility-container API).
    ///
    /// Only `UITabBar`s, `.tabBar`-trait views, and data tables derive context this way. Other
    /// context providers (segmented controls, lists, landmarks) vend their children through
    /// `accessibilityElements`/`accessibilityElement(at:)` and are captured on the container path with
    /// an explicit index/count instead. Returning `nil` here for those preserves today's behavior of
    /// not deriving list/landmark context from subview position.
    private func superviewContextParent() -> AccessibilityHierarchyParser.ContextParent? {
        if self is UITabBar
            || accessibilityTraits.contains(.tabBar)
            || (self is UIAccessibilityContainerDataTable && accessibilityContainerType == .dataTable)
        {
            return AccessibilityHierarchyParser.ContextParent(object: self)
        }
        return nil
    }

    /// Whether elements beneath `contextParent` should use their parent's frame to determine group
    /// ordering. This is a sort concern: `.tabBar`-trait containers anchor their tabs by the
    /// container's own frame rather than the first-selected child.
    private func overridesElementFrame(with contextParent: AccessibilityHierarchyParser.ContextParent?) -> Bool {
        guard let parent = contextParent?.object as? UIView else {
            return false
        }
        // A `.tabBar`-trait container anchors its tabs by its own frame (mirrors the old `.superview`
        // provider behavior). `UITabBar` lacks the `.tabBar` trait, so it is naturally excluded.
        return parent.accessibilityTraits.contains(.tabBar)
    }
}

// MARK: -

extension UIAccessibilityTraits {
    /// The private trait bit (1 << 28) UIKit sets on tab bar buttons (`UITabBarButton` / `_UITabButton`).
    /// A container whose children carry this trait is a tab bar — a class-free signal that identifies a
    /// real `UITabBar` (which reports `accessibilityContainerType == .semanticGroup` and no `.tabBar`
    /// trait). Confirmed live byte-identical on iOS 18.5 and 26.3.
    static let tabBarItemTrait = UIAccessibilityTraits(rawValue: 1 << 28)
}

extension UIAccessibilityContainerType {
    /// The private `accessibilityContainerType` value a `UISegmentedControl` reports (outside the
    /// public `.none`…`.semanticGroup` range, 0–4). Read via the public property, this is a
    /// class-free discriminator for segmented controls — the same private-value idiom the model uses
    /// for private trait bits. Confirmed live on plain and SwiftUI-backed segmented controls
    /// (iOS 18.5, 26.3); UIStepper/UISlider/UIDatePicker return 0, so this does not over-match.
    static let segmentedControlContainerType = UIAccessibilityContainerType(rawValue: 11)!
}

extension UIView {
    func convert(_ path: UIBezierPath, from source: UIView?) -> UIBezierPath {
        let offset = convert(CGPoint.zero, from: source)
        let transform = CGAffineTransform(translationX: offset.x, y: offset.y)

        let newPath = path.copy() as! UIBezierPath
        newPath.apply(transform)
        return newPath
    }
}

private extension UIView {
    /// Recursively searches the entire subview hierarchy and returns all views
    /// whose class is "UITabBarButton" or "_UITabButton".
    func allUITabBarButtons() -> [UIView] {
        let tabBarButtonClasses: [AnyClass] = [
            NSClassFromString("UITabBarButton"),
            NSClassFromString("_UITabButton"),
        ].compactMap { $0 }

        func collect(from view: UIView) -> [UIView] {
            var result: [UIView] = []
            for subview in view.subviews {
                if tabBarButtonClasses.contains(where: { subview.isKind(of: $0) }) {
                    result.append(subview)
                }
                result.append(contentsOf: collect(from: subview))
            }
            return result
        }

        return collect(from: self)
    }
}

private extension NSObject {
    var customContent: [AccessibilityElement.CustomContent] {
        // Github runs tests on specific iOS versions against specific versions of Xcode in CI.
        // Forward deployment on old versions of Xcode require a compile time check which require differentiation by swift version rather than iOS SDK.
        // See https://swiftversion.net/ for mapping swift version to Xcode versions.

        if #available(iOS 14.0, *) {
            if let provider = self as? AXCustomContentProvider {
                // Swift 5.9 ships with Xcode 15 and the iOS 17 SDK.
                #if swift(>=5.9)
                    if #available(iOS 17.0, *) {
                        if let customContentBlock = provider.accessibilityCustomContentBlock {
                            if let content = customContentBlock?() {
                                return content.map { .init(from: $0) }
                            }
                        }
                    }
                #endif // swift(>=5.9)
                if let content = provider.accessibilityCustomContent {
                    return content.map { .init(from: $0) }
                }
            }

            // SwiftUI creates internal accessibility proxy nodes that don't explicitly conform to AXCustomContentProvider
            // but do expose accessibilityCustomContent via KVC
            if responds(to: Selector(("accessibilityCustomContent"))),
               let content = value(forKey: "accessibilityCustomContent") as? [AXCustomContent]
            {
                return content.map { .init(from: $0) }
            }
        }
        return []
    }

    func customRotors(in root: UIView, context: AccessibilityHierarchyParser.Context?, resultLimit: Int) -> [AccessibilityElement.CustomRotor] {
        accessibilityCustomRotors?.compactMap {
            .init(from: $0, parentElement: self, root: root, context: context, resultLimit: resultLimit)
        } ?? []
    }

    /// The Voice Control input labels the app *authored*, excluding UIKit's derived label echo.
    ///
    /// When an element has no explicitly-set input labels, UIKit's Voice Control fallback synthesizes
    /// `[accessibilityLabel]` — an echo that is byte-identical, for targeting purposes, to setting
    /// nothing (you can already target the element by speaking its label). Some classes (e.g.
    /// `UITableViewCell` via its axbundle) surface this echo even through the private "raw" attributed
    /// getter, so the only reliable signal that input labels are a real authorial override is that
    /// they differ from the label itself. Suppress the single-element `[label]` echo; keep anything
    /// that adds alternative phrasings.
    var authoredUserInputLabels: [String]? {
        guard let labels = accessibilityUserInputLabels, !labels.isEmpty else {
            return nil
        }
        if labels.count == 1, labels.first == accessibilityLabel {
            return nil
        }
        return labels
    }

    var identifier: String? {
        // The `accessibilityIdentifier` property is part of the `UIAccessibilityIdentification` protocol,
        // distinct from other accessibility properties in UIKit.
        if let idProtocol = self as? UIAccessibilityIdentification {
            return idProtocol.accessibilityIdentifier
        }

        // Swift occasionally fails to recognize Objective-C subclasses conforming to `UIAccessibilityIdentification`.
        // This is likely due to a Swift bug where Objective-C classes lose their protocol conformance
        // when converted to `Any` types for use in accessibility APIs.
        // See https://github.com/swiftlang/swift/issues/46456 for details.

        // Explicitly check UIKit types that conform to `UIAccessibilityIdentification`:
        if let view = self as? UIView {
            return view.accessibilityIdentifier
        }
        if let barItem = self as? UIBarItem {
            return barItem.accessibilityIdentifier
        }
        if let alertAction = self as? UIAlertAction {
            return alertAction.accessibilityIdentifier
        }
        if let menuElement = self as? UIMenuElement {
            return menuElement.accessibilityIdentifier
        }
        if let image = self as? UIImage {
            return image.accessibilityIdentifier
        }

        // Use key-value coding as a fallback to access the `accessibilityIdentifier`.
        // This is necessary for SwiftUI views, which are wrapped in a `UIHostingController`
        // and don't directly expose an `accessibilityIdentifier`.
        if let accessibilityIdentifier = value(forKey: "accessibilityIdentifier") as? String {
            return accessibilityIdentifier
        }

        return nil
    }
}

// MARK: -

private extension UIHostingController {
    /// Provides access to the `accessibilityIdentifier` of the hosted SwiftUI view.
    /// This is necessary because SwiftUI views are wrapped in a `UIHostingController`,
    /// and don't directly expose an `accessibilityIdentifier`.
    var accessibilityIdentifier: String? {
        get {
            return view.accessibilityIdentifier
        }
        set {
            view.accessibilityIdentifier = newValue
        }
    }
}

// MARK: - Visible Frame

private let visibleFrameMinDimension: CGFloat = 2.0

/// Clips `frame` (in screen coordinates) against each scrollable ancestor's
/// visible content rect and the window bounds, starting from `startView` and
/// walking up the superview chain. Returns the clipped rect, or `.null` if
/// fully occluded.
private func clipFrameAgainstAncestors(_ frame: CGRect, startingFrom startView: UIView) -> CGRect {
    var visibleRect = frame
    var ancestor: UIView? = startView
    while let view = ancestor {
        if let scrollView = view as? UIScrollView,
           scrollView.contentSize.isScrollableContentSize(for: scrollView.bounds.size)
        {
            let insets = scrollView.adjustedContentInset
            let contentRect = CGRect(
                x: scrollView.contentOffset.x + insets.left,
                y: scrollView.contentOffset.y + insets.top,
                width: scrollView.bounds.width - insets.left - insets.right,
                height: scrollView.bounds.height - insets.top - insets.bottom
            )
            let scrollScreenRect = UIAccessibility.convertToScreenCoordinates(contentRect, in: scrollView)
            visibleRect = visibleRect.intersection(scrollScreenRect)
            guard !visibleRect.isNull else { return .null }
        }
        ancestor = view.superview
    }

    return visibleRect
}

/// Walks the `accessibilityContainer` chain to find the nearest UIView.
private func nearestContainerView(for object: NSObject) -> UIView? {
    let containerSel = NSSelectorFromString("accessibilityContainer")
    var current: AnyObject? = object
    while let obj = current {
        if let view = obj as? UIView {
            return view
        }
        if let nsObj = obj as? NSObject, nsObj.responds(to: containerSel) {
            current = nsObj.perform(containerSel)?.takeUnretainedValue()
        } else {
            break
        }
    }
    return nil
}

private extension UIView {
    func hasVisibleFrame() -> Bool {
        guard window != nil else {
            return true
        }

        let frame = AccessibilityHierarchyParser.effectiveAccessibilityFrame(for: self)
        guard frame.width > 0, frame.height > 0 else {
            if !isAccessibilityElement, !clipsToBounds {
                return true
            }
            return false
        }

        let clipped = clipFrameAgainstAncestors(frame, startingFrom: self)
        guard !clipped.isNull else { return false }
        return clipped.width > visibleFrameMinDimension
            && clipped.height > visibleFrameMinDimension
    }
}

private extension NSObject {
    func hasVisibleAccessibilityFrame() -> Bool {
        if let view = self as? UIView {
            return view.hasVisibleFrame()
        }

        let frame = accessibilityFrame
        guard frame.width > 0, frame.height > 0 else {
            return false
        }

        guard let containerView = nearestContainerView(for: self) else {
            return true
        }
        guard containerView.window != nil else {
            return true
        }

        let clipped = clipFrameAgainstAncestors(frame, startingFrom: containerView)
        guard !clipped.isNull else { return false }
        return clipped.width > visibleFrameMinDimension
            && clipped.height > visibleFrameMinDimension
    }
}

// MARK: -

private extension CGPoint {
    func approximatelyEquals(_ other: CGPoint, tolerance: CGFloat) -> Bool {
        return abs(x - other.x) < tolerance && abs(y - other.y) < tolerance
    }
}

extension UITextRange {
    func formatted(in input: UITextInput?) -> String {
        guard let input else { return "\(self)" }

        let start = input.offset(from: input.beginningOfDocument, to: start)
        let end = input.offset(from: input.beginningOfDocument, to: end)
        return "[\(start)..<\(end)]"
    }
}

extension UITextInput {
    func accessibilityPath(for range: UITextRange) -> UIBezierPath? {
        return selectionRects(for: range).reduce(into: UIBezierPath()) { path, rect in
            // selectionRects(for:) returns rects that contain no glyphs and are empty space used for text wrapping.
            // We don't want to include these as they look like they are a separate unexpected element.
            // Fortunately these extra rects can only occur in the middle of the range so we can safely accept many without question.
            if !rect.containsEnd, !rect.containsStart, !rect.isVertical {
                // Check that this rect contains actual glyphs by comparing the closest glyph position to the leading and trailing edges of the rect.
                let leading = CGPoint(x: rect.writingDirection == .leftToRight ? rect.rect.minX : rect.rect.maxX, y: rect.rect.midY)
                let trailing = CGPoint(x: rect.writingDirection == .leftToRight ? rect.rect.maxX : rect.rect.minX, y: rect.rect.midY)
                guard closestPosition(to: leading, within: range) != closestPosition(to: trailing, within: range) else { return }
            }
            path.append(UIBezierPath(roundedRect: rect.rect, cornerRadius: 8.0))
        }
    }
}

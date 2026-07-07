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

public struct ParserOptions {
    /// When `false` (the default), elements whose accessibility frame does not
    /// visibly intersect the viewport are pruned during the tree walk — mirroring
    /// the SPI's `shouldOnlyIncludeElementsWithVisibleFrame` behavior. Set to
    /// `true` to capture every element that exists in the subview hierarchy,
    /// including off-screen prefetched cells and lazily-loaded SwiftUI content.
    public var includeOffScreenElements: Bool

    public init(includeOffScreenElements: Bool = false) {
        self.includeOffScreenElements = includeOffScreenElements
    }

    public static let `default` = ParserOptions()
    public static let fullTree = ParserOptions(includeOffScreenElements: true)
}

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

    public let options: ParserOptions

    public init(options: ParserOptions = .default) {
        self.options = options
    }

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
    /// Container inclusion rules based on VoiceOver behavior:
    /// - `.semanticGroup` with label/value/identifier: INCLUDE (label is announced)
    /// - `.list`, `.landmark`, `.dataTable`: INCLUDE (affects rotor navigation)
    /// - Views with `.tabBar` trait: INCLUDE (affects tab navigation)
    /// - `.semanticGroup` without properties: EXCLUDE (no announcement)
    /// - `.none` containers: EXCLUDE (no special behavior)
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
            isRoot: true,
            options: options
        )

        let uncontextualizedElements = sortedElements(
            for: accessibilityNodes,
            explicitlyOrdered: false,
            in: root,
            userInterfaceLayoutDirection: userInterfaceLayoutDirection,
            userInterfaceIdiom: userInterfaceIdiom
        )

        var tabBarCache: [UIView: [NSObject]] = [:]
        let contextualizedElements = uncontextualizedElements.map { element in
            ContextualElement(
                object: element.object,
                context: context(
                    for: element.object,
                    from: element.contextProvider,
                    userInterfaceLayoutDirection: userInterfaceLayoutDirection,
                    userInterfaceIdiom: userInterfaceIdiom,
                    tabBarCache: &tabBarCache
                )
            )
        }

        let elements: [AccessibilityElement] = contextualizedElements.map { element in
            buildElement(from: element.object, context: element.context, in: root, rotorResultLimit: rotorResultLimit)
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

    fileprivate enum ContextProvider {
        case superview(UIView)

        case accessibilityContainer(NSObject, elementIndex: Int?, elementCount: Int?)

        case dataTable(UIAccessibilityContainerDataTable)
    }

    // MARK: - Private Methods

    private func buildElement(
        from object: NSObject,
        context: Context?,
        in root: UIView,
        rotorResultLimit: Int
    ) -> AccessibilityElement {
        let (description, hint) = object.accessibilityDescription(context: context)
        let activationPoint = object.accessibilityActivationPoint

        return AccessibilityElement(
            description: description,
            label: object.accessibilityLabel,
            value: object.accessibilityValue,
            traits: AccessibilityTraits(object.accessibilityTraits),
            identifier: object.identifier,
            hint: hint,
            userInputLabels: object.accessibilityUserInputLabels,
            shape: Self.accessibilityShape(for: object, in: root),
            activationPoint: AccessibilityPoint(root.convert(activationPoint, from: nil)),
            usesDefaultActivationPoint: Self.usesDefaultActivationPoint(
                element: object,
                activationPoint: activationPoint,
                screenScale: (root.window?.screen ?? UIScreen.main).scale
            ),
            customActions: (object.accessibilityCustomActions ?? []).map { .init(name: $0.name) },
            customContent: object.customContent,
            customRotors: object.customRotors(in: root, context: context, resultLimit: rotorResultLimit),
            accessibilityLanguage: object.accessibilityLanguage,
            respondsToUserInteraction: object.accessibilityRespondsToUserInteraction
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
    ) -> [(object: NSObject, contextProvider: ContextProvider?)] {
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

        var sortedElements: [(object: NSObject, contextProvider: ContextProvider?)] = []

        for node in sortedNodes {
            switch node {
            case let .element(element, contextProvider):
                sortedElements.append((object: element, contextProvider: contextProvider))

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

    /// Returns the context for an `element` provided by the `contextProvider`.
    private func context(
        for element: NSObject,
        from contextProvider: ContextProvider?,
        userInterfaceLayoutDirection: UIUserInterfaceLayoutDirection,
        userInterfaceIdiom: UIUserInterfaceIdiom,
        tabBarCache: inout [UIView: [NSObject]]
    ) -> Context? {
        guard let contextProvider = contextProvider else {
            return nil
        }

        switch contextProvider {
        case let .superview(view):
            if let tabBar = view as? UITabBar, let element = element as? UIView {
                let tabBarButtons = view.allUITabBarButtons()
                let tabBarItems = tabBar.items ?? []

                // An unexpected tab bar shape — no items, a button count that isn't a multiple
                // of the item count, or a button that isn't in our list — should not crash the
                // process. Skip context for this element instead; it will still be parsed.
                //
                // Some UIKit tab bars expose multiple button sets at different levels in the
                // view hierarchy, so the total count may be a multiple of the item count.
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

            // Views that are not `UITabBar`s can use the `.tabBar` accessibility trait to have their elements treated
            // similarly to a `UITabBar`'s tabs (with a few differences). Unlike `UITabBar`s, all elements in the
            // hierarchy under the view are treated as tabs.
            if view.accessibilityTraits.contains(.tabBar), let element = element as? UIView {
                let accessibleElements: [NSObject]
                if let elements = tabBarCache[view] {
                    accessibleElements = elements
                } else {
                    let hierarchy = view.recursiveAccessibilityHierarchy(isRoot: true, options: options)
                    accessibleElements = sortedElements(
                        for: hierarchy,
                        explicitlyOrdered: false,
                        in: view,
                        userInterfaceLayoutDirection: userInterfaceLayoutDirection,
                        userInterfaceIdiom: userInterfaceIdiom
                    ).map { $0.object }
                    tabBarCache[view] = accessibleElements
                }

                guard let index = accessibleElements.firstIndex(of: element) else {
                    os_log(
                        "Tab-bar-trait view does not contain the element being parsed; dropping tab context.",
                        log: parserLog,
                        type: .error
                    )
                    return nil
                }
                return .tab(
                    index: index + 1,
                    count: accessibleElements.count
                )
            }

        case let .accessibilityContainer(container, capturedElementIndex, capturedElementCount):
            let elementIndex = capturedElementIndex ?? container.index(ofAccessibilityElement: element)
            let elementCount = capturedElementCount ?? container.accessibilityElementCount()

            // The container may not actually contain the element if its accessibility tree is in
            // an inconsistent state. Drop context for this element rather than crashing.
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

            if container is UISegmentedControl {
                return .series(
                    index: elementIndex + 1,
                    count: elementCount
                )
            }

            if container.accessibilityTraits.contains(.tabBar) {
                return .tab(
                    index: elementIndex + 1,
                    count: elementCount
                )
            }

            if container.accessibilityContainerType == .list {
                if elementIndex == 0 {
                    return .listStart
                } else if elementIndex == elementCount - 1 {
                    return .listEnd
                }
            }

            if container.accessibilityContainerType == .landmark {
                if elementIndex == 0 {
                    return .landmarkStart
                } else if elementIndex == elementCount - 1 {
                    return .landmarkEnd
                }
            }

        case let .dataTable(dataTable):
            if let cell = element as? UIAccessibilityContainerDataTableCell {
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

                        // The is header not read as a header for itself.
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
        }

        return nil
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
        sortedElements: [(object: NSObject, contextProvider: ContextProvider?)],
        elements: [AccessibilityElement],
        in root: UIView,
        makeElement: (AccessibilityElement, _ traversalIndex: Int, _ source: NSObject) -> Node,
        makeContainer: (AccessibilityContainer, _ children: [Node], _ source: NSObject) -> Node
    ) -> [Node] {
        var indexLookup: [ObjectIdentifier: Int] = [:]
        for (index, element) in sortedElements.enumerated() {
            indexLookup[ObjectIdentifier(element.object)] = index
        }

        func mapNode(_ node: AccessibilityNode) -> [(node: Node, sortIndex: Int)] {
            switch node {
            case let .element(object, _):
                guard let index = indexLookup[ObjectIdentifier(object)],
                      index < elements.count else { return [] }
                return [(makeElement(elements[index], index, object), index)]

            case let .group(children, _, _, containerInfo):
                let mappedChildren = children.flatMap { mapNode($0) }.sorted { lhs, rhs in
                    lhs.sortIndex < rhs.sortIndex
                }

                if let info = containerInfo {
                    let frame = AccessibilityRect(root.convert(info.view.bounds, from: info.view))

                    let containerType: AccessibilityContainer.ContainerType
                    if let contentSize = info.scrollableContentSize {
                        containerType = .scrollable(contentSize: AccessibilitySize(contentSize))
                    } else if info.traits.contains(.tabBar) {
                        containerType = .tabBar
                    } else {
                        switch info.type {
                        case .semanticGroup:
                            containerType = .semanticGroup(label: info.label, value: info.value, identifier: info.identifier)
                        case .list:
                            containerType = .list
                        case .landmark:
                            containerType = .landmark
                        case .dataTable:
                            containerType = .dataTable(rowCount: info.rowCount ?? 0, columnCount: info.columnCount ?? 0)
                        case .none:
                            containerType = .semanticGroup(label: info.label, value: info.value, identifier: info.identifier)
                        @unknown default:
                            containerType = .semanticGroup(label: info.label, value: info.value, identifier: info.identifier)
                        }
                    }

                    let container = AccessibilityContainer(
                        type: containerType,
                        frame: frame,
                        isModalBoundary: info.isModalBoundary,
                        customActions: info.customActions
                    )
                    let sortIndex = mappedChildren.map(\.sortIndex).min() ?? Int.max
                    return [(makeContainer(container, mappedChildren.map(\.node), info.view), sortIndex)]
                }

                return mappedChildren
            }
        }

        return nodes.flatMap { mapNode($0) }.map(\.node)
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
        case let .element(frameProvider, _),
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
    case element(NSObject, contextProvider: AccessibilityHierarchyParser.ContextProvider?)

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
}

// MARK: -

private extension NSObject {
    /// Recursively parses the accessibility elements/containers on the screen.
    ///
    /// Note that the order the nodes are returned in does not reflect the order that VoiceOver will iterate through
    /// them.
    func recursiveAccessibilityHierarchy(
        contextProvider: AccessibilityHierarchyParser.ContextProvider? = nil,
        isRoot: Bool = false,
        options: ParserOptions = .default
    ) -> [AccessibilityNode] {
        guard !accessibilityElementsHidden else {
            return []
        }

        let explicitAccessibilityElements = resolvedAccessibilityElements(
            allowContainerFallback: shouldUseAccessibilityContainerElements
        )

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

            if !isRoot, !options.includeOffScreenElements, !self.hasVisibleFrame() {
                return []
            }
        }

        var recursiveAccessibilityHierarchy: [AccessibilityNode] = []

        if isAccessibilityElement {
            recursiveAccessibilityHierarchy.append(.element(self, contextProvider: contextProvider))

        } else if let accessibilityElements = resolvedAccessibilityElements(
            allowContainerFallback: shouldUseAccessibilityContainerElements
        ) {
            var accessibilityHierarchyOfElements: [AccessibilityNode] = []
            for (index, element) in accessibilityElements.enumerated() {
                let childContextProvider = contextProvider ?? (
                    providesContext ? providedContextAsContainer(
                        elementIndex: index,
                        elementCount: accessibilityElements.count
                    ) : nil
                )
                accessibilityHierarchyOfElements.append(
                    contentsOf: element.recursiveAccessibilityHierarchy(
                        contextProvider: childContextProvider,
                        isRoot: false,
                        options: options
                    )
                )
            }
            let container = (self as? UIView).flatMap { containerInfo(for: $0) }

            recursiveAccessibilityHierarchy.append(.group(
                accessibilityHierarchyOfElements,
                explicitlyOrdered: true,
                frameOverrideProvider: overridesElementFrame(with: contextProvider) ? self : nil,
                container: container
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
                        contextProvider: contextProvider ?? (providesContext ? providedContextAsSuperview() : nil),
                        isRoot: false,
                        options: options
                    )
                )
            }

            let container = containerInfo(for: self)

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
        guard count > 0 else {
            return nil
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
            return false
        }
        if isAccessibilityElement {
            return false
        }
        return accessibilityElementCount() != NSNotFound
    }

    private var shouldGateOnAccessibilityFrame: Bool {
        isAccessibilityElement || accessibilityElements != nil
    }

    private func containerInfo(for view: UIView) -> ContainerInfo? {
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
        let isSemanticGroup = containerType == .semanticGroup
            && (label != nil || value != nil || identifier != nil)
        let customActions = view.accessibilityCustomActions?.map { AccessibilityElement.CustomAction(name: $0.name) } ?? []
        let shouldEmitContainer = traits.contains(.tabBar)
            || containerType == .list
            || containerType == .landmark
            || containerType == .dataTable
            || isSemanticGroup
            || scrollableContentSize != nil
            || isModalBoundary
            || !customActions.isEmpty

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
    ///
    /// Some elements can provide context in multiple roles, which can be differentiated using the
    /// `providedContextAsSuperview()` and `providedContextAsContainer()` methods.
    private var providesContext: Bool {
        return self is UISegmentedControl
            || self is UITabBar
            || accessibilityTraits.contains(.tabBar)
            || accessibilityContainerType == .list
            || accessibilityContainerType == .landmark
            || (self is UIAccessibilityContainerDataTable && accessibilityContainerType == .dataTable)
    }

    /// The form of context provider the object acts as for elements beneath it in the hierarchy when the elements
    /// beneath it are part of the view hierarchy and the object is not an accessibility container.
    private func providedContextAsSuperview() -> AccessibilityHierarchyParser.ContextProvider? {
        if accessibilityContainerType == .dataTable, let self = self as? UIAccessibilityContainerDataTable {
            return .dataTable(self)
        }

        guard let view = self as? UIView else {
            os_log(
                "Non-UIView object %{public}@ reports providesContext=true but cannot supply superview context; skipping.",
                log: parserLog,
                type: .error,
                String(describing: type(of: self))
            )
            return nil
        }

        return .superview(view)
    }

    /// The form of context provider the object acts as for elements beneath it in the hierarchy when the object is
    /// being used as an accessibility container.
    private func providedContextAsContainer(
        elementIndex: Int? = nil,
        elementCount: Int? = nil
    ) -> AccessibilityHierarchyParser.ContextProvider {
        if accessibilityContainerType == .dataTable, let self = self as? UIAccessibilityContainerDataTable {
            return .dataTable(self)
        }

        return .accessibilityContainer(self, elementIndex: elementIndex, elementCount: elementCount)
    }

    private func overridesElementFrame(with contextProvider: AccessibilityHierarchyParser.ContextProvider?) -> Bool {
        guard let contextProvider = contextProvider else {
            return false
        }

        switch contextProvider {
        case let .superview(view):
            return view.accessibilityTraits.contains(.tabBar)

        case .accessibilityContainer, .dataTable:
            return false
        }
    }
}

// MARK: -

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

private extension UIView {
    /// Returns `true` when the view's accessibility frame visibly intersects
    /// the viewport, mirroring the SPI's `_accessibilityHasVisibleFrame` check.
    ///
    /// Clips the element's screen-space accessibility frame through three
    /// stages: (1) the element's window frame, (2) keyboard subtraction, and
    /// (3) each scroll-view ancestor's visible content rect. The result must
    /// exceed 2 pt in both dimensions to count as visible.
    func hasVisibleFrame() -> Bool {
        guard window != nil else {
            return true
        }

        let frame = AccessibilityHierarchyParser.effectiveAccessibilityFrame(for: self)
        guard frame.width > 0, frame.height > 0 else {
            // Zero-frame non-clipping containers can have visible children that
            // overflow — let the existing clipsToBounds guard handle pruning.
            if !isAccessibilityElement, !clipsToBounds {
                return true
            }
            return false
        }

        // Clip against each scrollable ancestor's visible content rect. Only
        // clip against scroll views whose content actually exceeds their bounds
        // — SwiftUI wraps content in internal UIScrollView subclasses that don't
        // scroll, and clipping against those drops visible elements.
        var visibleRect = frame
        var ancestor = superview
        while let view = ancestor {
            if let scrollView = view as? UIScrollView,
               scrollView.contentSize.isScrollableContentSize(for: scrollView.bounds.size)
            {
                let contentRect = CGRect(
                    origin: scrollView.contentOffset,
                    size: scrollView.bounds.size
                )
                let scrollScreenRect = UIAccessibility.convertToScreenCoordinates(contentRect, in: scrollView)
                visibleRect = visibleRect.intersection(scrollScreenRect)
                guard !visibleRect.isNull else { return false }
            }
            ancestor = view.superview
        }

        return visibleRect.width > visibleFrameMinDimension
            && visibleRect.height > visibleFrameMinDimension
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

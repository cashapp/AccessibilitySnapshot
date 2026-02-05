import Accessibility
import SwiftUI
import UIKit

// MARK: - Providing Protocols

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
    /// - parameter rotorResultLimit: Maximum number of rotor results to collect in each direction. Defaults to 10.
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
    /// - parameter rotorResultLimit: Maximum number of rotor results to collect in each direction. Defaults to 10.
    /// - parameter userInterfaceLayoutDirectionProvider: Provider of the device's UI layout direction
    /// - parameter userInterfaceIdiomProvider: Provider of the device's interface idiom
    /// - returns: Array of root-level hierarchy nodes with containers grouping their children
    public func parseAccessibilityHierarchy(
        in root: UIView,
        rotorResultLimit: Int = AccessibilityElement.defaultRotorResultLimit,
        userInterfaceLayoutDirectionProvider: UserInterfaceLayoutDirectionProviding = UIApplication.shared,
        userInterfaceIdiomProvider: UserInterfaceIdiomProviding = UIDevice.current
    ) -> [AccessibilityHierarchy] {
        let userInterfaceLayoutDirection = userInterfaceLayoutDirectionProvider.userInterfaceLayoutDirection
        let userInterfaceIdiom = userInterfaceIdiomProvider.userInterfaceIdiom

        // Parse elements using the same logic as parseAccessibilityElements
        let accessibilityNodes = root.recursiveAccessibilityHierarchy()

        let uncontextualizedElements = sortedElements(
            for: accessibilityNodes,
            explicitlyOrdered: false,
            in: root,
            userInterfaceLayoutDirection: userInterfaceLayoutDirection,
            userInterfaceIdiom: userInterfaceIdiom
        )

        let contextualizedElements = uncontextualizedElements.map { element in
            ContextualElement(
                object: element.object,
                context: context(
                    for: element.object,
                    from: element.contextProvider,
                    userInterfaceLayoutDirection: userInterfaceLayoutDirection,
                    userInterfaceIdiom: userInterfaceIdiom
                )
            )
        }

        let elements: [AccessibilityElement] = contextualizedElements.map { element in
            buildElement(from: element.object, context: element.context, in: root, rotorResultLimit: rotorResultLimit)
        }

        // Map AccessibilityNode tree to AccessibilityHierarchy tree
        return mapNodesToHierarchy(accessibilityNodes, sortedElements: uncontextualizedElements, elements: elements, in: root)
    }

    // MARK: - Private Types

    /// Representation of an accessibility element, made up of the element `object` itself and the `context` in which it
    /// is contained.
    private struct ContextualElement {
        var object: NSObject

        var context: AccessibilityElement.ContainerContext?
    }

    fileprivate enum ContextProvider {
        case superview(UIView)

        case accessibilityContainer(NSObject)

        case dataTable(UIAccessibilityContainerDataTable)
    }

    // MARK: - Private Methods

    /// Builds an AccessibilityElement from an NSObject and its context
    private func buildElement(
        from object: NSObject,
        context: AccessibilityElement.ContainerContext?,
        in root: UIView,
        rotorResultLimit: Int
    ) -> AccessibilityElement {
        let (description, hint) = object.buildAccessibilityDescription(context: context)
        let activationPoint = object.accessibilityActivationPoint

        return AccessibilityElement(
            description: description,
            label: object.accessibilityLabel,
            value: object.accessibilityValue,
            traits: object.accessibilityTraits,
            identifier: object.identifier,
            hint: hint,
            userInputLabels: object.accessibilityUserInputLabels,
            shape: Self.accessibilityShape(for: object, in: root),
            activationPoint: root.convert(activationPoint, from: nil),
            usesDefaultActivationPoint: activationPoint.approximatelyEquals(
                Self.defaultActivationPoint(for: object),
                tolerance: 1 / (root.window?.screen ?? UIScreen.main).scale
            ),
            customActions: object.accessibilityCustomActions?.map { AccessibilityElement.CustomAction(name: $0.name, image: $0.image) } ?? [],
            customContent: object.customContent,
            customRotors: object.customRotors(in: root, resultLimit: rotorResultLimit),
            accessibilityLanguage: object.accessibilityLanguage,
            respondsToUserInteraction: object.accessibilityRespondsToUserInteraction,
            containerContext: context
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
            fatalError("Unknown user interface layout direction: \(userInterfaceLayoutDirection)")
        }

        // Derived via experimentation, these magic numbers are the cutoff for VoiceOver to consider
        // an element to be vertically "above" other views.
        let minimumVerticalSeparation = userInterfaceIdiom == .phone ? 8.0 : 13.0

        let sortedNodes = explicitlyOrdered ? nodes : nodes
            .map { ($0, Self.accessibilitySortFrame(for: $0, in: root)) }
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
        userInterfaceIdiom: UIUserInterfaceIdiom
    ) -> AccessibilityElement.ContainerContext? {
        guard let contextProvider = contextProvider else {
            return nil
        }

        switch contextProvider {
        case let .superview(view):
            if let tabBar = view as? UITabBar, let element = element as? UIView {
                let tabBarButtons = view.allUITabBarButtons()
                let tabBarItems = tabBar.items ?? []

                // This logic assumes that the UITabBar has the same number of buttons as it does items, and that they
                // are in the same order. From testing, this seems to always be true, but there may be some cases that
                // aren't handled properly here.
                //
                // We use modulo instead of equality because iOS 26 tab bars have multiple sets of tab buttons at
                // different levels in the view hierarchy, so the total count may be a multiple of the item count.
                precondition(
                    tabBarButtons.count % tabBarItems.count == 0,
                    "UITabBar does not have the same number of tab views as tab items."
                )

                guard let index = tabBarButtons.firstIndex(of: element) else {
                    fatalError("Can't find tab bar button in UITabBar")
                }

                // Use modulo to get the tab item index since there may be multiple sets of buttons
                let tabIndex = index % tabBarItems.count

                return .tabBarItem(
                    index: tabIndex + 1,
                    count: tabBarItems.count
                )
            }

            // Views that are not `UITabBar`s can use the `.tabBar` accessibility trait to have their elements treated
            // similarly to a `UITabBar`'s tabs (with a few differences). Unlike `UITabBar`s, all elements in the
            // hierarchy under the view are treated as tabs.
            if view.accessibilityTraits.contains(.tabBar), let element = element as? UIView {
                let accessibleElements: [NSObject]
                if let elements = viewToElementsMap[view] {
                    accessibleElements = elements
                } else {
                    let hierarchy = view.recursiveAccessibilityHierarchy()
                    accessibleElements = sortedElements(
                        for: hierarchy,
                        explicitlyOrdered: false,
                        in: view,
                        userInterfaceLayoutDirection: userInterfaceLayoutDirection,
                        userInterfaceIdiom: userInterfaceIdiom
                    ).map { $0.object }
                    viewToElementsMap[view] = accessibleElements
                }

                return .tab(
                    index: accessibleElements.firstIndex(of: element)! + 1,
                    count: accessibleElements.count
                )
            }

        case let .accessibilityContainer(container):
            let elementIndex = container.index(ofAccessibilityElement: element)

            assert(
                elementIndex != NSNotFound,
                "Element should not have a container as a context provider if it is not an element in that container"
            )

            if container is UISegmentedControl {
                return .series(
                    index: elementIndex + 1,
                    count: container.accessibilityElementCount()
                )
            }

            if container.accessibilityTraits.contains(.tabBar) {
                return .tab(
                    index: elementIndex + 1,
                    count: container.accessibilityElementCount()
                )
            }

            if container.accessibilityContainerType == .list {
                if elementIndex == 0 {
                    return .listStart
                } else if elementIndex == container.accessibilityElementCount() - 1 {
                    return .listEnd
                }
            }

            if container.accessibilityContainerType == .landmark {
                if elementIndex == 0 {
                    return .landmarkStart
                } else if elementIndex == container.accessibilityElementCount() - 1 {
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

                let rowHeaderObjects: [NSObject]
                if isFirstInRow, let allHeaders = dataTable.accessibilityHeaderElements?(forRow: row) {
                    rowHeaderObjects = allHeaders.filter { header in
                        true
                            // The cell is not read as a header for itself.
                            && header !== cell
                            // The header is not read if it is not a cell in the table.
                            && dataTable.accessibilityDataTableCellElement(forRow: header.accessibilityRowRange().location, column: header.accessibilityColumnRange().location) === header
                    } as! [NSObject]

                } else {
                    rowHeaderObjects = []
                }

                let columnHeaderObjects: [NSObject]
                if let allHeaders = dataTable.accessibilityHeaderElements?(forColumn: column) {
                    columnHeaderObjects = allHeaders.filter { header in
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
                    } as! [NSObject]

                } else {
                    columnHeaderObjects = []
                }

                // Pre-format header strings
                func formatHeader(_ header: NSObject) -> String {
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
                }

                return .dataTableCell(
                    row: row,
                    column: column,
                    rowSpan: rowRange.length,
                    columnSpan: columnRange.length,
                    isFirstInRow: isFirstInRow,
                    rowHeaders: rowHeaderObjects.map(formatHeader),
                    columnHeaders: columnHeaderObjects.map(formatHeader)
                )
            }
        }

        return nil
    }

    // MARK: - Private Properties

    /// Used for memoization of accessibility hierarchy parsing when determining element contexts.
    private var viewToElementsMap: [UIView: [NSObject]] = [:]

    // MARK: - Private Hierarchy Methods

    /// Maps AccessibilityNode tree to AccessibilityHierarchy tree
    private func mapNodesToHierarchy(
        _ nodes: [AccessibilityNode],
        sortedElements: [(object: NSObject, contextProvider: ContextProvider?)],
        elements: [AccessibilityElement],
        in root: UIView
    ) -> [AccessibilityHierarchy] {
        // Build lookup: object identity → traversal index
        var indexLookup: [ObjectIdentifier: Int] = [:]
        for (index, element) in sortedElements.enumerated() {
            indexLookup[ObjectIdentifier(element.object)] = index
        }

        func mapNode(_ node: AccessibilityNode) -> [AccessibilityHierarchy] {
            switch node {
            case let .element(object, _):
                guard let index = indexLookup[ObjectIdentifier(object)],
                      index < elements.count else { return [] }
                return [.element(elements[index], traversalIndex: index)]

            case let .group(children, _, _, containerInfo):
                let mappedChildren = children.flatMap { mapNode($0) }.sorted { lhs, rhs in
                    lhs.sortIndex < rhs.sortIndex
                }

                if let info = containerInfo {
                    let frame = root.convert(info.view.bounds, from: info.view)

                    // Convert UIAccessibilityContainerType + associated data to our ContainerType
                    let containerType: AccessibilityContainer.ContainerType
                    if info.traits.contains(.tabBar) {
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
                            // Should not reach here since containerInfo(for:) returns nil for .none
                            containerType = .semanticGroup(label: info.label, value: info.value, identifier: info.identifier)
                        @unknown default:
                            containerType = .semanticGroup(label: info.label, value: info.value, identifier: info.identifier)
                        }
                    }

                    let container = AccessibilityContainer(
                        type: containerType,
                        frame: frame
                    )
                    return [.container(container, children: mappedChildren)]
                }

                // Not a meaningful container - flatten children
                return mappedChildren
            }
        }

        return nodes.flatMap { mapNode($0) }
    }
}

// MARK: - Internal Helpers

extension AccessibilityHierarchyParser {
    /// Returns the shape of the accessibility element in the root view's coordinate space.
    /// Voiceover prefers an accessibilityPath if available when drawing the bounding box, but the accessibilityFrame is always used for sort order.
    static func accessibilityShape(for element: NSObject, in root: UIView, preferPath: Bool = true) -> AccessibilityElement.Shape {
        if let accessibilityPath = element.accessibilityPath, preferPath {
            return .path(root.convert(accessibilityPath, from: nil))

        } else if let element = element as? UIAccessibilityElement, let container = element.accessibilityContainer, !element.accessibilityFrameInContainerSpace.isNull {
            return .frame(container.convert(element.accessibilityFrameInContainerSpace, to: root))

        } else {
            return .frame(root.convert(element.accessibilityFrame, from: nil))
        }
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
        let accessibilityFrame = element.accessibilityFrame
        return CGPoint(x: accessibilityFrame.midX, y: accessibilityFrame.midY)
    }
}

// MARK: - Fileprivate Helpers

private extension AccessibilityHierarchyParser {
    /// Returns a CGRect that can be used for sorting by position.
    static func accessibilitySortFrame(for node: AccessibilityNode, in root: UIView) -> CGRect {
        switch node {
        case let .element(frameProvider, _),
             let .group(_, _, frameProvider?, _):
            switch accessibilityShape(for: frameProvider, in: root, preferPath: false) {
            case let .frame(rect):
                return rect
            default:
                return frameProvider.accessibilityFrame
            }

        case let .group(elements, _, _, _):
            return elements.reduce(CGRect.null) { $0.union(accessibilitySortFrame(for: $1, in: root)) }
        }
    }
}

// MARK: -

/// Captures container information at node creation time, avoiding the need to re-derive it later.
private struct ContainerInfo {
    let view: UIView
    let type: UIAccessibilityContainerType
    let label: String?
    let value: String?
    let identifier: String?
    let traits: UIAccessibilityTraits
    let rowCount: Int?
    let columnCount: Int?
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
        contextProvider: AccessibilityHierarchyParser.ContextProvider? = nil
    ) -> [AccessibilityNode] {
        guard !accessibilityElementsHidden else {
            return []
        }

        // Ignore elements that are views if they are not visible on the screen, either due to visibility, size, or
        // alpha. VoiceOver actually has some very low alpha threshold at which it will still display an element
        // (presumably to account for animations and/or rounding error). We use an alpha threshold of zero since that
        // should fulfill the intent.
        if let `self` = self as? UIView, self.isHidden || self.frame.size == .zero || self.alpha <= 0 {
            return []
        }

        var recursiveAccessibilityHierarchy: [AccessibilityNode] = []

        if isAccessibilityElement {
            recursiveAccessibilityHierarchy.append(.element(self, contextProvider: contextProvider))

        } else if let accessibilityElements = accessibilityElements as? [NSObject] {
            var accessibilityHierarchyOfElements: [AccessibilityNode] = []
            for element in accessibilityElements {
                accessibilityHierarchyOfElements.append(
                    contentsOf: element.recursiveAccessibilityHierarchy(
                        contextProvider: contextProvider ?? (providesContext ? providedContextAsContainer() : nil)
                    )
                )
            }
            // Capture container info - this path always creates a group, so just capture for metadata
            let container = (self as? UIView).flatMap { containerInfo(for: $0) }
            recursiveAccessibilityHierarchy.append(.group(
                accessibilityHierarchyOfElements,
                explicitlyOrdered: true,
                frameOverrideProvider: overridesElementFrame(with: contextProvider) ? self : nil,
                container: container
            ))

        } else if let `self` = self as? UIView {
            // If there is at least one modal subview, the last modal is the only subview parsed in the accessibility
            // hierarchy. Otherwise, parse all of the subviews.
            let subviewsToParse: [UIView]
            if let lastModalView = self.subviews.last(where: { $0.accessibilityViewIsModal }) {
                subviewsToParse = [lastModalView]
            } else {
                subviewsToParse = self.subviews
            }

            var accessibilityHierarchyOfSubviews: [AccessibilityNode] = []
            for subview in subviewsToParse {
                accessibilityHierarchyOfSubviews.append(
                    contentsOf: subview.recursiveAccessibilityHierarchy(
                        contextProvider: contextProvider ?? (providesContext ? providedContextAsSuperview() : nil)
                    )
                )
            }

            // Capture container info if this is a meaningful container
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

    /// Creates ContainerInfo for a view if it represents a meaningful accessibility container.
    /// Returns nil if the view is not a container worth visualizing.
    private func containerInfo(for view: UIView) -> ContainerInfo? {
        let containerType = view.accessibilityContainerType
        let traits = view.accessibilityTraits
        let label = view.accessibilityLabel
        let value = view.accessibilityValue
        let identifier = (view as UIAccessibilityIdentification).accessibilityIdentifier

        // Extract data table dimensions if applicable
        let (rowCount, columnCount): (Int?, Int?) = {
            guard containerType == .dataTable,
                  let dataTable = view as? UIAccessibilityContainerDataTable
            else {
                return (nil, nil)
            }
            return (dataTable.accessibilityRowCount(), dataTable.accessibilityColumnCount())
        }()

        // tabBar trait always creates container
        if traits.contains(.tabBar) {
            return ContainerInfo(view: view, type: containerType, label: label, value: value, identifier: identifier, traits: traits, rowCount: nil, columnCount: nil)
        }

        // list, landmark, dataTable always create container
        if containerType == .list || containerType == .landmark || containerType == .dataTable {
            return ContainerInfo(view: view, type: containerType, label: label, value: value, identifier: identifier, traits: traits, rowCount: rowCount, columnCount: columnCount)
        }

        // semanticGroup only if has label/value/identifier
        if containerType == .semanticGroup, label != nil || value != nil || identifier != nil {
            return ContainerInfo(view: view, type: containerType, label: label, value: value, identifier: identifier, traits: traits, rowCount: nil, columnCount: nil)
        }

        return nil
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
    private func providedContextAsSuperview() -> AccessibilityHierarchyParser.ContextProvider {
        if accessibilityContainerType == .dataTable, let self = self as? UIAccessibilityContainerDataTable {
            return .dataTable(self)
        }

        return .superview(self as! UIView)
    }

    /// The form of context provider the object acts as for elements beneath it in the hierarchy when the object is
    /// being used as an accessibility container.
    private func providedContextAsContainer() -> AccessibilityHierarchyParser.ContextProvider {
        if accessibilityContainerType == .dataTable, let self = self as? UIAccessibilityContainerDataTable {
            return .dataTable(self)
        }

        return .accessibilityContainer(self)
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
            if let content = value(forKey: "accessibilityCustomContent") as? [AXCustomContent] {
                return content.map { .init(from: $0) }
            }
        }
        return []
    }

    func customRotors(in root: UIView, resultLimit: Int) -> [AccessibilityElement.CustomRotor] {
        accessibilityCustomRotors?.compactMap {
            .init(from: $0, parentElement: self, root: root, resultLimit: resultLimit)
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

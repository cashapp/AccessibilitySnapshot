import Accessibility
import SwiftUI
import UIKit

public struct AccessibilityMarker: Equatable {
    /// Default number of rotor results to collect in each direction.
    public static let defaultRotorResultLimit: Int = 10

    // MARK: - Public Types

    public enum Shape: Equatable {
        /// Accessibility frame, in the coordinate space of the view being snapshotted.
        case frame(CGRect)

        /// Accessibility path, in the coordinate space of the view being snapshotted.
        case path(UIBezierPath)
    }

    public struct CustomRotor: Equatable, CustomStringConvertible {
        public struct ResultMarker: Equatable, CustomStringConvertible {
            public let elementDescription: String
            public let rangeDescription: String?
            public let shape: Shape?

            public var description: String {
                guard let rangeDescription else {
                    return elementDescription
                }
                return "\(elementDescription) \(rangeDescription)"
            }
        }

        public var name: String
        public var resultMarkers: [AccessibilityMarker.CustomRotor.ResultMarker] = []
        public let limit: UIAccessibilityCustomRotor.CollectedRotorResults.Limit

        init?(from: UIAccessibilityCustomRotor, parentElement: NSObject, root: UIView, context: AccessibilityHierarchyParser.Context? = nil, resultLimit: Int) {
            guard from.isKnownRotorType else { return nil }
            name = from.displayName(locale: parentElement.accessibilityLanguage)
            let collected = from.collectAllResults(nextLimit: resultLimit, previousLimit: resultLimit)
            limit = collected.limit
            resultMarkers = collected.results.compactMap { result in
                guard let element = result.targetElement as? NSObject else { return nil }
                var description = element.accessibilityDescription(context: context).description
                var shape: Shape? = AccessibilityHierarchyParser.accessibilityShape(for: element, in: root)

                if let range = result.targetRange,
                   let input = element as? UITextInput
                {
                    if let path = input.accessibilityPath(for: range) {
                        let converted = root.convert(path, from: input as? UIView)
                        shape = .path(converted)
                    }
                    if let substring = input.text(in: range) {
                        description = substring
                    }
                    return ResultMarker(elementDescription: description, rangeDescription: range.formatted(in: input), shape: shape)
                }
                return ResultMarker(elementDescription: description, rangeDescription: nil, shape: shape)
            }
        }

        public var description: String {
            return name + ": " + resultMarkers.map { $0.description }.joined(separator: "\n")
        }
    }

    public struct CustomContent: Codable, Equatable {
        public var label: String
        public var value: String
        public var isImportant: Bool

        @available(iOS 14.0, *)
        init(from: AXCustomContent) {
            label = from.label
            value = from.value
            isImportant = from.importance == .high
        }
    }

    public struct CustomAction: Equatable {
        public var name: String
        public var image: UIImage?

        init(name: String, image: UIImage?) {
            self.name = name
            self.image = image
        }

        @available(iOS 14.0, *)
        init(from: UIAccessibilityCustomAction) {
            name = from.name
            image = from.image
        }
    }

    // MARK: - Public Properties

    /// The description of the accessibility element that will be read by VoiceOver when the element is brought into
    /// focus.
    public var description: String

    public var label: String?

    public var value: String?

    public var traits: UIAccessibilityTraits

    /// A unique identifier for the element, primarily used in UI tests for locating and interacting with elements.
    /// This identifier is not visible to users.
    public var identifier: String?

    /// A hint that will be read by VoiceOver if focus remains on the element after the `description` is read.
    public var hint: String?

    /// The labels that will be used by Voice Control for user input.
    /// These labels are displayed based on the `AccessibilityContentDisplayMode` configuration:
    /// - `.always`: Always shows user input labels
    /// - `.whenOverridden`: Shows labels only when they differ from default values (future enhancement)
    /// - `.never`: Never shows user input labels
    public var userInputLabels: [String]?

    /// The shape that will be highlighted on screen while the element is in focus.
    public var shape: Shape

    /// The accessibility activation point, in the coordinate space of the view being snapshotted.
    public var activationPoint: CGPoint

    /// Whether or not the `activationPoint` is the default activation point for the object.
    ///
    /// For most elements, the default activation point is the midpoint of the element's accessibility frame. Certain
    /// elements have distinct defaults - for example, a `UISlider` puts its activation point at the center of its thumb
    /// by default.
    public var usesDefaultActivationPoint: Bool

    /// The names of the custom actions supported by the element.
    public var customActions: [CustomAction]

    /// Any custom content included by the element.
    public var customContent: [CustomContent]

    /// Any custom rotors included by the element.
    public var customRotors: [CustomRotor]

    /// The language code of the language used to localize strings in the description.
    public var accessibilityLanguage: String?

    /// whether the element performs an action based on user interaction.
    public var respondsToUserInteraction: Bool
}

// MARK: -

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
    /// The returned `AccessibilityMarker` objects include user input labels that are displayed based on the
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
    public func parseAccessibilityElements(
        in root: UIView,
        rotorResultLimit: Int = AccessibilityMarker.defaultRotorResultLimit,
        userInterfaceLayoutDirectionProvider: UserInterfaceLayoutDirectionProviding = UIApplication.shared,
        userInterfaceIdiomProvider: UserInterfaceIdiomProviding = UIDevice.current
    ) -> [AccessibilityMarker] {
        let userInterfaceLayoutDirection = userInterfaceLayoutDirectionProvider.userInterfaceLayoutDirection
        let userInterfaceIdiom = userInterfaceIdiomProvider.userInterfaceIdiom

        let accessibilityNodes = root.recursiveAccessibilityHierarchy()

        let uncontextualizedElements = sortedElements(
            for: accessibilityNodes,
            explicitlyOrdered: false,
            in: root,
            userInterfaceLayoutDirection: userInterfaceLayoutDirection,
            userInterfaceIdiom: userInterfaceIdiom
        )

        let accessibilityElements = uncontextualizedElements.map { element in
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

        return accessibilityElements.map { element in
            let (description, hint) = element.object.accessibilityDescription(context: element.context)

            let activationPoint = element.object.accessibilityActivationPoint

            return AccessibilityMarker(
                description: description,
                label: element.object.accessibilityLabel,
                value: element.object.accessibilityValue,
                traits: element.object.accessibilityTraits,
                identifier: element.object.identifier,
                hint: hint,
                userInputLabels: element.object.accessibilityUserInputLabels,
                shape: Self.accessibilityShape(for: element.object, in: root),
                activationPoint: root.convert(activationPoint, from: nil),
                usesDefaultActivationPoint: activationPoint.approximatelyEquals(
                    Self.defaultActivationPoint(for: element.object),
                    tolerance: 1 / (root.window?.screen ?? UIScreen.main).scale
                ),
                customActions: element.object.accessibilityCustomActions?.map { AccessibilityMarker.CustomAction(name: $0.name, image: $0.image) } ?? [],
                customContent: element.object.customContent,
                customRotors: element.object.customRotors(in: root, context: element.context, resultLimit: rotorResultLimit),
                accessibilityLanguage: element.object.accessibilityLanguage,
                respondsToUserInteraction: element.object.accessibilityRespondsToUserInteraction
            )
        }
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

        case accessibilityContainer(NSObject)

        case dataTable(UIAccessibilityContainerDataTable)
    }

    /// Representation of an accessibility element, made up of the element `object` itself and the `contextProvider`
    /// that will provide its context, if applicable.
    private struct Element {
        var object: NSObject

        var contextProvider: ContextProvider?
    }

    // MARK: - Private Methods

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
    ) -> [Element] {
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

        var sortedElements: [Element] = []

        for node in sortedNodes {
            switch node {
            case let .element(element, contextProvider):
                sortedElements.append(.init(object: element, contextProvider: contextProvider))

            case let .group(elements, explicitlyOrdered, _):
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
    ) -> Context? {
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
                    count: tabBarItems.count,
                    item: tabBarItems[tabIndex]
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

                let rowHeaders: [NSObject]
                if isFirstInRow, let allHeaders = dataTable.accessibilityHeaderElements?(forRow: row) {
                    rowHeaders = allHeaders.filter { header in
                        true
                            // The cell is not read as a header for itself.
                            && header !== cell
                            // The header is not read if it is not a cell in the table.
                            && dataTable.accessibilityDataTableCellElement(forRow: header.accessibilityRowRange().location, column: header.accessibilityColumnRange().location) === header
                    } as! [NSObject]

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
                    } as! [NSObject]

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

    // MARK: - Private Properties

    /// Used for memoization of accessibility hierarchy parsing when determining element contexts.
    private var viewToElementsMap: [UIView: [NSObject]] = [:]
}

private extension AccessibilityHierarchyParser {
    /// Returns a CGRect that can be used for sorting by position.
    static func accessibilitySortFrame(for node: AccessibilityNode, in root: UIView) -> CGRect {
        switch node {
        case let .element(frameProvider, _),
             let .group(_, _, frameProvider?):
            switch accessibilityShape(for: frameProvider, in: root, preferPath: false) {
            case let .frame(rect):
                return rect
            default:
                return frameProvider.accessibilityFrame
            }

        case let .group(elements, _, _):
            return elements.reduce(CGRect.null) { $0.union(accessibilitySortFrame(for: $1, in: root)) }
        }
    }

    /// Returns the shape of the accessibility element in the root view's coordinate space.
    /// Voiceover prefers an accessibilityPath if available when drawing the bounding box, but the accessibilityFrame is always used for sort order.
    static func accessibilityShape(for element: NSObject, in root: UIView, preferPath: Bool = true) -> AccessibilityMarker.Shape {
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

// MARK: -

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
    case group([AccessibilityNode], explicitlyOrdered: Bool, frameOverrideProvider: NSObject?)
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
            recursiveAccessibilityHierarchy.append(.group(
                accessibilityHierarchyOfElements,
                explicitlyOrdered: true,
                frameOverrideProvider: overridesElementFrame(with: contextProvider) ? self : nil
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

            if shouldGroupAccessibilityChildren {
                recursiveAccessibilityHierarchy.append(
                    .group(accessibilityHierarchyOfSubviews, explicitlyOrdered: false, frameOverrideProvider: nil)
                )

            } else {
                recursiveAccessibilityHierarchy.append(contentsOf: accessibilityHierarchyOfSubviews)
            }
        }

        return recursiveAccessibilityHierarchy
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
    var customContent: [AccessibilityMarker.CustomContent] {
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
        }
        return []
    }

    func customRotors(in root: UIView, context: AccessibilityHierarchyParser.Context?, resultLimit: Int) -> [AccessibilityMarker.CustomRotor] {
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

// MARK: -

private extension CGPoint {
    func approximatelyEquals(_ other: CGPoint, tolerance: CGFloat) -> Bool {
        return abs(x - other.x) < tolerance && abs(y - other.y) < tolerance
    }
}

private extension UITextRange {
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

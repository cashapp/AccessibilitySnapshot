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

    /// The portable context captured for an element.
    public typealias Context = AccessibilityContext

    // MARK: - Life Cycle

    public init() {}

    // MARK: - Public Methods

    /// Parses the accessibility hierarchy starting from the `root` view and returns markers for each element in the
    /// hierarchy, in the order VoiceOver will iterate through them when using flick navigation.
    /// Offscreen elements are omitted for snapshot compatibility. Use `parseAccessibilityHierarchy`
    /// to capture the full hierarchy, including visibility metadata.
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
        ).flattenToElements().filter { $0.visibility == .onscreen }
    }

    /// Parses the accessibility hierarchy starting from the `root` view and returns a tree structure
    /// with containers grouping their child elements.
    ///
    /// This method uses the same element parsing logic as `parseAccessibilityElements` but additionally
    /// tracks containers (semanticGroup, list, landmark, dataTable, tabBar) and nests elements within them.
    ///
    /// Container inclusion rules based on captured facts:
    /// - A container must have at least one accessible descendant to be included.
    /// - Any non-`.none` container role is included when it has descendants.
    /// - A `.none` container is included when it has descendants and an identifier, scrollable
    ///   content, a modal boundary, custom actions, or a tab-bar trait.
    /// - A `.none` container without any captured facts is transparent.
    ///
    /// Each element node includes a `traversalIndex` indicating its position in VoiceOver's navigation order.
    /// `flattenToElements()` includes offscreen elements; filter by `.onscreen` visibility for snapshot delivery.
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
    /// `makeElement` builds leaves in VoiceOver traversal order. `makeContainer` then builds
    /// containers bottom-up from their already-built children. Structural ownership is retained
    /// even when a container's leaves interleave with sibling leaves in navigation order.
    ///
    /// The `source` parameters expose the originating accessibility object so callers can correlate
    /// parsed markers back to their source views — useful for test harnesses, debugging overlays,
    /// and custom renderers. `parseAccessibilityHierarchy(in:)` is the default instantiation,
    /// producing `[AccessibilityHierarchy]` and ignoring the source.
    ///
    /// Both closures are invoked synchronously after capture and description assembly, on the caller's thread.
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

        let capturedNodes = root.recursiveAccessibilityHierarchy(in: root, isRoot: true)
        let navigationNodes = sortedNodes(
            capturedNodes,
            explicitlyOrdered: false,
            in: root,
            userInterfaceLayoutDirection: userInterfaceLayoutDirection,
            userInterfaceIdiom: userInterfaceIdiom
        )
        let capturedElements = navigationNodes.flatMap { $0.capturedElements }
        for (index, element) in capturedElements.enumerated() {
            element.traversalIndex = index
        }
        let preparedNodes = prepareNodes(orderedOutputNodes(capturedNodes))
        let elements = capturedElements.map { element in
            buildElement(
                from: element.object,
                context: element.context,
                in: root,
                rotorResultLimit: rotorResultLimit,
                visibility: element.visibility
            )
        }

        return foldNodes(
            preparedNodes,
            capturedElements: capturedElements,
            elements: elements,
            makeElement: makeElement,
            makeContainer: makeContainer
        )
    }

    // MARK: - Private Methods

    private func buildElement(
        from object: NSObject,
        context: Context?,
        in root: UIView,
        rotorResultLimit: Int,
        visibility: ScreenVisibility
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
            customActions: (object.accessibilityCustomActions ?? []).map { $0.name },
            customContent: object.customContent,
            customRotors: object.customRotors(in: root, context: context, resultLimit: rotorResultLimit),
            accessibilityLanguage: object.accessibilityLanguage,
            respondsToUserInteraction: object.accessibilityRespondsToUserInteraction,
            visibility: visibility,
            context: context
        )
    }

    /// Orders navigation groups, projecting through metadata-only containers.
    private func sortedNodes(
        _ nodes: [AccessibilityNode],
        explicitlyOrdered: Bool,
        in root: UIView,
        userInterfaceLayoutDirection: UIUserInterfaceLayoutDirection,
        userInterfaceIdiom: UIUserInterfaceIdiom,
        provider: ContainerInfo? = nil
    ) -> [AccessibilityNode] {
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
        let minimumVerticalSeparation = userInterfaceIdiom == .phone ? 8.0 : 13.0
        let navigationNodes = nodes.flatMap { $0.navigationNodes }
        let ordered = explicitlyOrdered ? navigationNodes : navigationNodes
            .map { ($0, Self.accessibilitySortFrame(
                for: $0,
                in: root,
                horizontalCompare: horizontalCompare,
                minimumVerticalSeparation: minimumVerticalSeparation,
                provider: provider
            )) }
            .sorted { lhs, rhs in
                if lhs.1.origin.y != rhs.1.origin.y,
                   abs(lhs.1.origin.y - rhs.1.origin.y) >= minimumVerticalSeparation
                {
                    return lhs.1.origin.y < rhs.1.origin.y
                }
                return horizontalCompare(lhs.1.origin.x, rhs.1.origin.x)
            }
            .map { $0.0 }

        return ordered.map { node in
            guard case let .group(children, explicitlyOrdered, frameProvider, info) = node else {
                return node
            }
            return .group(
                sortedNodes(
                    children,
                    explicitlyOrdered: explicitlyOrdered,
                    in: root,
                    userInterfaceLayoutDirection: userInterfaceLayoutDirection,
                    userInterfaceIdiom: userInterfaceIdiom,
                    provider: provider ?? info.flatMap { $0.lendsContext ? $0 : nil }
                ),
                explicitlyOrdered: true,
                frameOverrideProvider: frameProvider,
                container: info
            )
        }
    }

    private func orderedOutputNodes(_ nodes: [AccessibilityNode], explicitlyOrdered: Bool = false) -> [AccessibilityNode] {
        let ordered = nodes.map { node -> AccessibilityNode in
            guard case let .group(children, explicitlyOrdered, frameProvider, info) = node else {
                return node
            }
            return .group(
                orderedOutputNodes(children, explicitlyOrdered: explicitlyOrdered),
                explicitlyOrdered: explicitlyOrdered,
                frameOverrideProvider: frameProvider,
                container: info
            )
        }
        return explicitlyOrdered ? ordered : ordered.sorted { $0.firstTraversalIndex < $1.firstTraversalIndex }
    }

    /// Derives context and resolves container payloads from ordered tree children.
    private func prepareNodes(
        _ nodes: [AccessibilityNode],
        provider: ContainerInfo? = nil,
        context: Context? = nil,
        tabContexts: [ObjectIdentifier: Context]? = nil
    ) -> [AccessibilityNode] {
        nodes.map { node in
            switch node {
            case let .element(element):
                let identity = ObjectIdentifier(element.object)
                if let cells = provider?.dataTableCells {
                    element.context = cells[identity]?.context
                } else if let tabs = provider?.tabBarItemContexts {
                    element.context = tabs[identity]
                } else if provider?.usesFlattenedTabPositions == true {
                    element.context = tabContexts?[ObjectIdentifier(element)]
                } else {
                    element.context = context
                }
                return node

            case let .group(children, explicitlyOrdered, frameProvider, capturedInfo):
                var info = capturedInfo
                let ownsContext = provider == nil && info?.lendsContext == true
                let childProvider = provider ?? info.flatMap { $0.lendsContext ? $0 : nil }
                var childTabContexts = tabContexts
                if ownsContext, info?.usesFlattenedTabPositions == true {
                    let tabs = children.flatMap { $0.capturedElements }.sorted { $0.traversalIndex < $1.traversalIndex }
                    childTabContexts = [:]
                    for (index, tab) in tabs.enumerated() where tab.object is UIView {
                        childTabContexts?[ObjectIdentifier(tab)] = .tab(index: index + 1, count: tabs.count)
                    }
                }
                let preparedChildren = children.enumerated().flatMap { index, child in
                    prepareNodes(
                        [child],
                        provider: childProvider,
                        context: ownsContext ? info?.context(at: index, count: children.count) : context,
                        tabContexts: childTabContexts
                    )
                }
                if let captured = info,
                   case let .dataTable(rowCount, columnCount, _) = captured.role,
                   let container = captured.container
                {
                    let sources = preparedChildren.flatMap { $0.emittedSources }
                    var sourceIndices: [ObjectIdentifier: Int] = [:]
                    for (index, source) in sources.enumerated() {
                        sourceIndices[ObjectIdentifier(source)] = index
                    }
                    let cells = sources.map { source -> AccessibilityContainer.DataTableCellInfo? in
                        guard let cell = captured.dataTableCells?[ObjectIdentifier(source)],
                              case let .dataTableCell(row, column, width, height, isFirstInRow, _, _) = cell.context
                        else {
                            return nil
                        }
                        return .init(
                            row: row,
                            column: column,
                            rowSpan: height,
                            columnSpan: width,
                            isFirstInRow: isFirstInRow,
                            rowHeaderChildIndices: cell.rowHeaderSources.compactMap { sourceIndices[$0] },
                            columnHeaderChildIndices: cell.columnHeaderSources.compactMap { sourceIndices[$0] }
                        )
                    }
                    info?.container = AccessibilityContainer(
                        type: .dataTable(rowCount: rowCount, columnCount: columnCount, cells: cells),
                        identifier: container.identifier,
                        scrollableContentSize: container.scrollableContentSize,
                        frame: container.frame,
                        isModalBoundary: container.isModalBoundary,
                        customActions: container.customActions
                    )
                }
                return .group(preparedChildren, explicitlyOrdered: explicitlyOrdered, frameOverrideProvider: frameProvider, container: info)
            }
        }
    }

    /// Folds the prepared tree without querying its source objects again.
    private func foldNodes<Node>(
        _ nodes: [AccessibilityNode],
        capturedElements: [CapturedElement],
        elements: [AccessibilityElement],
        makeElement: (AccessibilityElement, _ traversalIndex: Int, _ source: NSObject) -> Node,
        makeContainer: (AccessibilityContainer, _ children: [Node], _ source: NSObject) -> Node
    ) -> [Node] {
        let elementNodes = capturedElements.enumerated().map { index, element in
            makeElement(elements[index], index, element.object)
        }
        func mapNode(_ node: AccessibilityNode) -> [Node] {
            switch node {
            case let .element(element):
                return [elementNodes[element.traversalIndex]]
            case let .group(children, _, _, info):
                let mappedChildren = children.flatMap { mapNode($0) }
                if let info, let container = info.container {
                    return [makeContainer(container, mappedChildren, info.source)]
                }
                return mappedChildren
            }
        }
        return nodes.flatMap { mapNode($0) }
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
        minimumVerticalSeparation: CGFloat,
        provider: ContainerInfo? = nil
    ) -> CGRect {
        switch node {
        case let .element(element):
            return sortFrame(for: element.object, in: root)
        case let .group(children, _, frameProvider, info):
            if let frameProvider, provider?.anchorsVendedGroups == true {
                return sortFrame(for: frameProvider, in: root)
            }
            let childProvider = provider ?? info.flatMap { $0.lendsContext ? $0 : nil }
            return children
                .map { accessibilitySortFrame(
                    for: $0,
                    in: root,
                    horizontalCompare: horizontalCompare,
                    minimumVerticalSeparation: minimumVerticalSeparation,
                    provider: childProvider
                ) }
                .min { lhs, rhs in
                    if lhs.origin.y != rhs.origin.y, abs(lhs.origin.y - rhs.origin.y) >= minimumVerticalSeparation {
                        return lhs.origin.y < rhs.origin.y
                    }
                    return horizontalCompare(lhs.origin.x, rhs.origin.x)
                } ?? .null
        }
    }

    static func sortFrame(for object: NSObject, in root: UIView) -> CGRect {
        switch accessibilityShape(for: object, in: root, preferPath: false) {
        case let .frame(rect):
            return rect.cgRect
        default:
            return object.accessibilityFrame
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

/// Captured roles and UIKit-only facts attached to a structural group.
private struct ContainerInfo {
    let source: NSObject
    let role: AccessibilityContainer.ContainerType
    let traits: UIAccessibilityTraits
    let lendsContext: Bool
    let formsNavigationBoundary: Bool
    let usesFlattenedTabPositions: Bool
    let anchorsVendedGroups: Bool
    let tabBarItemContexts: [ObjectIdentifier: AccessibilityContext]?
    let dataTableCells: [ObjectIdentifier: CapturedDataTableCell]?
    var container: AccessibilityContainer?

    func context(at index: Int, count: Int) -> AccessibilityContext? {
        switch role {
        case .series:
            return .series(index: index + 1, count: count)
        case .tabBar:
            return tabBarItemContexts == nil ? .tab(index: index + 1, count: count) : nil
        case .list:
            return index == 0 ? .listStart : (index == count - 1 ? .listEnd : nil)
        case .landmark:
            return index == 0 ? .landmarkStart : (index == count - 1 ? .landmarkEnd : nil)
        case .none, .semanticGroup, .dataTable, .scrollable:
            return nil
        }
    }
}

private struct CapturedDataTableCell {
    let context: AccessibilityContext
    let rowHeaderSources: [ObjectIdentifier]
    let columnHeaderSources: [ObjectIdentifier]
}

private final class CapturedElement {
    let object: NSObject
    let traits: UIAccessibilityTraits
    let visibility: ScreenVisibility
    var context: AccessibilityContext?
    var traversalIndex = 0

    init(object: NSObject, traits: UIAccessibilityTraits, visibility: ScreenVisibility) {
        self.object = object
        self.traits = traits
        self.visibility = visibility
    }
}

private enum AccessibilityNode {
    case element(CapturedElement)

    /// Structural groups retain output ownership even when transparent to navigation.
    case group([AccessibilityNode], explicitlyOrdered: Bool, frameOverrideProvider: NSObject?, container: ContainerInfo?)

    var navigationNodes: [AccessibilityNode] {
        if case let .group(children, _, _, info) = self, info?.formsNavigationBoundary == false {
            return children.flatMap { $0.navigationNodes }
        }
        return [self]
    }

    var capturedElements: [CapturedElement] {
        switch self {
        case let .element(element):
            return [element]
        case let .group(children, _, _, _):
            return children.flatMap { $0.capturedElements }
        }
    }

    var firstTraversalIndex: Int {
        capturedElements.map { $0.traversalIndex }.min() ?? Int.max
    }

    var containsAccessibleElement: Bool {
        switch self {
        case .element:
            return true
        case let .group(children, _, _, _):
            return children.contains { $0.containsAccessibleElement }
        }
    }

    var emittedSources: [NSObject] {
        switch self {
        case let .element(element):
            return [element.object]
        case let .group(children, _, _, info):
            if let info, info.container != nil {
                return [info.source]
            }
            return children.flatMap { $0.emittedSources }
        }
    }

    var capturedSources: [NSObject] {
        switch self {
        case let .element(element):
            return [element.object]
        case let .group(children, _, _, info):
            return (info.map { [$0.source] } ?? []) + children.flatMap { $0.capturedSources }
        }
    }

    var emittedTabBarItem: Bool {
        switch self {
        case let .element(element):
            return element.traits.contains(.tabBarItemTrait)
        case let .group(children, _, _, info):
            if let info, info.container != nil {
                return info.traits.contains(.tabBarItemTrait)
            }
            return children.contains { $0.emittedTabBarItem }
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
        in root: UIView,
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
                .element(CapturedElement(object: self, traits: accessibilityTraits, visibility: isOffscreen ? .offscreen : .onscreen))
            )

        } else if let accessibilityElements = resolvedAccessibilityElements(
            allowContainerFallback: shouldUseAccessibilityContainerElements
        ) {
            var accessibilityHierarchyOfElements: [AccessibilityNode] = []
            let tableView = self as? UITableView
            let headerView = tableView?.tableHeaderView
            let footerView = tableView?.tableFooterView

            let vendedElements = accessibilityElements.filter { element in
                element !== headerView && element !== footerView
            }
            for element in vendedElements {
                let children = element.recursiveAccessibilityHierarchy(in: root, inheritsOffscreen: isOffscreen)
                accessibilityHierarchyOfElements.append(.group(
                    children,
                    explicitlyOrdered: true,
                    frameOverrideProvider: nil,
                    container: nil
                ))
            }
            let vendedContainer = containerInfo(
                children: accessibilityHierarchyOfElements,
                vendsChildren: true,
                in: root
            )
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
                        in: root,
                        isRoot: false,
                        inheritsOffscreen: isOffscreen
                    )
                )
            }
            tableHierarchy.append(vendedGroup)
            if let footerView {
                tableHierarchy.append(
                    contentsOf: footerView.recursiveAccessibilityHierarchy(
                        in: root,
                        isRoot: false,
                        inheritsOffscreen: isOffscreen
                    )
                )
            }

            recursiveAccessibilityHierarchy.append(.group(
                tableHierarchy,
                explicitlyOrdered: true,
                frameOverrideProvider: self,
                container: nil
            ))

        } else if let `self` = self as? UIView {
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
                        in: root,
                        isRoot: false,
                        inheritsOffscreen: isOffscreen
                    )
                )
            }

            let container = containerInfo(
                children: accessibilityHierarchyOfSubviews,
                vendsChildren: false,
                in: root
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

    private func containerInfo(
        children: [AccessibilityNode],
        vendsChildren: Bool,
        in root: UIView
    ) -> ContainerInfo? {
        let type = accessibilityContainerType
        let traits = accessibilityTraits
        // UIKit's container text getters can settle descendant layout.
        let label = accessibilityLabel
        let value = accessibilityValue
        let view = self as? UIView
        let scrollableContentSize = view.flatMap { self.scrollableContentSize(for: $0) }
        let customActions = accessibilityCustomActions?.map { $0.name } ?? []
        let identifier = self.identifier
        let hasDescendants = children.contains { $0.containsAccessibleElement }
        let dataTable = type == .dataTable ? self as? UIAccessibilityContainerDataTable : nil
        let actualTabBar = self as? UITabBar
        let role: AccessibilityContainer.ContainerType
        if traits.contains(.tabBar) || actualTabBar != nil {
            role = .tabBar
        } else if type == .segmentedControlContainerType || self is UISegmentedControl {
            role = .series
        } else {
            switch type {
            case .semanticGroup:
                role = .semanticGroup(label: label, value: value)
            case .list:
                role = .list
            case .landmark:
                role = .landmark
            case .dataTable:
                role = .dataTable(
                    rowCount: dataTable?.accessibilityRowCount() ?? 0,
                    columnCount: dataTable?.accessibilityColumnCount() ?? 0,
                    cells: []
                )
            case .none:
                role = actualTabBar != nil || children.contains(where: { $0.emittedTabBarItem }) ? .tabBar : .none
            @unknown default:
                role = .none
            }
        }
        let lendsContext: Bool
        if actualTabBar != nil || traits.contains(.tabBar) || dataTable != nil {
            lendsContext = true
        } else {
            switch role {
            case .series, .list, .landmark:
                lendsContext = vendsChildren
            case .none, .semanticGroup, .dataTable, .tabBar, .scrollable:
                lendsContext = false
            }
        }
        let hasContainerFacts = identifier?.isEmpty == false
            || scrollableContentSize != nil
            || accessibilityViewIsModal
            || !customActions.isEmpty
            || traits.contains(.tabBar)
        let shouldEmit = view != nil && hasDescendants && (type != .none || hasContainerFacts)
        guard shouldEmit || lendsContext else {
            return nil
        }
        let container = shouldEmit ? AccessibilityContainer(
            type: role,
            identifier: identifier,
            scrollableContentSize: scrollableContentSize.map(AccessibilitySize.init),
            frame: AccessibilityRect(root.convert(view!.bounds, from: view!)),
            isModalBoundary: accessibilityViewIsModal,
            customActions: customActions
        ) : nil
        return ContainerInfo(
            source: self,
            role: role,
            traits: traits,
            lendsContext: lendsContext,
            formsNavigationBoundary: vendsChildren || shouldGroupAccessibilityChildren
                || traits.contains(.tabBar) || type == .list || type == .landmark || type == .dataTable
                || (type == .semanticGroup && (label != nil || value != nil || identifier != nil)),
            usesFlattenedTabPositions: !vendsChildren && actualTabBar == nil && traits.contains(.tabBar),
            anchorsVendedGroups: !vendsChildren && traits.contains(.tabBar),
            tabBarItemContexts: actualTabBar.map { captureTabBarItems(in: $0) },
            dataTableCells: dataTable.map { captureDataTableCells(in: $0, sources: children.flatMap { $0.capturedSources }) },
            container: container
        )
    }

    private func captureTabBarItems(in tabBar: UITabBar) -> [ObjectIdentifier: AccessibilityContext] {
        let buttons = tabBar.allUITabBarButtons()
        let count = tabBar.items?.count ?? 0
        guard count > 0, buttons.count % count == 0 else {
            os_log(
                "UITabBar has an unexpected shape (buttons=%{public}d, items=%{public}d); dropping tab-bar context.",
                log: parserLog,
                type: .error,
                buttons.count,
                count
            )
            return [:]
        }
        var contexts: [ObjectIdentifier: AccessibilityContext] = [:]
        for (index, button) in buttons.enumerated() {
            contexts[ObjectIdentifier(button)] = .tabBarItem(index: index % count + 1, count: count)
        }
        return contexts
    }

    private func captureDataTableCells(
        in table: UIAccessibilityContainerDataTable,
        sources: [NSObject]
    ) -> [ObjectIdentifier: CapturedDataTableCell] {
        var cells: [ObjectIdentifier: CapturedDataTableCell] = [:]
        var headers: [ObjectIdentifier: AccessibilityContext.Header] = [:]
        func captureHeader(_ header: NSObject) -> AccessibilityContext.Header {
            let identity = ObjectIdentifier(header)
            if let captured = headers[identity] {
                return captured
            }
            let captured = AccessibilityContext.Header(label: header.accessibilityLabel, value: header.accessibilityValue)
            headers[identity] = captured
            return captured
        }
        for source in sources {
            let identity = ObjectIdentifier(source)
            guard cells[identity] == nil,
                  let cell = source as? UIAccessibilityContainerDataTableCell
            else {
                continue
            }
            let rowRange = cell.accessibilityRowRange()
            let columnRange = cell.accessibilityColumnRange()
            let row = rowRange.location
            let column = columnRange.location
            let isFirstInRow = column != NSNotFound
                && row != NSNotFound
                && !(0 ..< column).contains {
                    table.accessibilityDataTableCellElement(forRow: row, column: $0) != nil
                }
            let rowHeaders: [NSObject]
            if isFirstInRow, let allHeaders = table.accessibilityHeaderElements?(forRow: row) {
                rowHeaders = allHeaders.filter { header in
                    header !== cell
                        && table.accessibilityDataTableCellElement(
                            forRow: header.accessibilityRowRange().location,
                            column: header.accessibilityColumnRange().location
                        ) === header
                }.compactMap { $0 as? NSObject }
            } else {
                rowHeaders = []
            }
            let columnHeaders = (table.accessibilityHeaderElements?(forColumn: column) ?? []).filter { header in
                let headerRow = header.accessibilityRowRange().location
                let headerColumn = header.accessibilityColumnRange().location
                if header === cell {
                    return false
                }
                return !(row != NSNotFound && headerRow == row - 1 && headerColumn == column && isFirstInRow)
            }.compactMap { $0 as? NSObject }
            cells[identity] = CapturedDataTableCell(
                context: .dataTableCell(
                    row: row,
                    column: column,
                    width: columnRange.length,
                    height: rowRange.length,
                    isFirstInRow: isFirstInRow,
                    rowHeaders: rowHeaders.map { captureHeader($0) },
                    columnHeaders: columnHeaders.map { captureHeader($0) }
                ),
                rowHeaderSources: rowHeaders.map { ObjectIdentifier($0) },
                columnHeaderSources: columnHeaders.map { ObjectIdentifier($0) }
            )
        }
        return cells
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

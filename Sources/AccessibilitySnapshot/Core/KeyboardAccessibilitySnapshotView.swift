import AccessibilitySnapshotParser
import UIKit

/// A container view that renders a snapshot of the contained view alongside a legend
/// of keyboard accessibility information (shortcuts, focus hierarchy, etc.).
public final class KeyboardAccessibilitySnapshotView: UIView {
    // MARK: - Public Types

    /// Specifies how the view should be rendered for the snapshot.
    public enum ViewRenderingMode {
        /// Renders the view's layer hierarchy using CALayer's render(in:) method.
        case renderLayerInContext

        /// Draws the view hierarchy using UIView's drawHierarchy(in:afterScreenUpdates:) method.
        case drawHierarchyInRect
    }

    // MARK: - Private Types

    private enum Metrics {
        static let legendPadding: CGFloat = 16
        static let legendItemSpacing: CGFloat = 12
        static let legendBackgroundColor = UIColor(white: 0.9, alpha: 1.0)
        static let dividerWidth: CGFloat = 1
        static let dividerColor = UIColor(white: 0.8, alpha: 1.0)
    }

    // MARK: - Private Properties

    private let containedView: UIView
    private let viewRenderingMode: ViewRenderingMode
    private let useMonochromeSnapshot: Bool

    private let snapshotImageView: UIImageView = .init()
    private let legendContainerView: UIView = .init()
    private let dividerView: UIView = .init()
    private var legendItemViews: [UIView] = []

    // MARK: - Life Cycle

    /// Creates a new keyboard accessibility snapshot view.
    ///
    /// - parameter containedView: The view to snapshot.
    /// - parameter viewRenderingMode: How to render the view for the snapshot.
    /// - parameter useMonochromeSnapshot: Whether or not the snapshot of the view should be monochrome. Using a
    /// monochrome snapshot makes it more clear where the highlighted elements are, but may make it difficult to
    /// read certain views. Defaults to `true`.
    public init(
        containedView: UIView,
        viewRenderingMode: ViewRenderingMode,
        useMonochromeSnapshot: Bool = true
    ) {
        self.containedView = containedView
        self.viewRenderingMode = viewRenderingMode
        self.useMonochromeSnapshot = useMonochromeSnapshot

        super.init(frame: .zero)

        commonInit()
    }

    private func commonInit() {
        backgroundColor = .white

        addSubview(snapshotImageView)

        dividerView.backgroundColor = Metrics.dividerColor
        addSubview(dividerView)

        legendContainerView.backgroundColor = Metrics.legendBackgroundColor
        addSubview(legendContainerView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Methods

    /// Parses keyboard shortcuts from the contained view's responder chain and updates the legend.
    ///
    /// This method should be called after the view has been laid out to ensure
    /// accurate parsing of the responder chain. Use this for uncategorized shortcuts.
    public func parseKeyboardShortcuts() throws {
        try renderContainedView()
        let shortcuts = KeyboardShortcutParser.parseKeyCommands(from: containedView)
        updateLegendViews(with: shortcuts)
    }

    /// Parses keyboard shortcuts from a UIMenu and updates the legend.
    ///
    /// This method extracts shortcuts from the menu hierarchy, preserving category information
    /// based on submenu titles. Use this for categorized shortcuts.
    ///
    /// - Parameter menu: The UIMenu containing keyboard shortcuts organized by category.
    public func parseKeyboardShortcuts(from menu: UIMenu) throws {
        try renderContainedView()
        let shortcuts = KeyboardShortcutParser.parseKeyCommands(from: menu)
        updateLegendViews(with: shortcuts)
    }

    // MARK: - Private Methods

    private func renderContainedView() throws {
        let renderMode: AccessibilitySnapshotCore.ViewRenderingMode = viewRenderingMode == .drawHierarchyInRect
            ? .drawHierarchyInRect
            : .renderLayerInContext
        let colorMode: ColorRenderingMode = useMonochromeSnapshot ? .monochrome : .fullColor
        let configuration = AccessibilitySnapshotConfiguration.Rendering(renderMode: renderMode, colorMode: colorMode)
        let image = try containedView.renderToImage(configuration: configuration)
        snapshotImageView.image = image
        snapshotImageView.bounds.size = containedView.bounds.size
    }

    private func updateLegendViews(with shortcuts: [KeyboardShortcut]) {
        legendItemViews.forEach { $0.removeFromSuperview() }

        let (categorized, uncategorized) = shortcuts.partitioned { $0.menuTitle != nil }

        // Group categorized shortcuts by menu title, preserving order
        let categorizedGroups = categorized.reduce(into: [(title: String, shortcuts: [KeyboardShortcut])]()) { groups, shortcut in
            guard let title = shortcut.menuTitle else { return }
            if groups.last?.title == title {
                groups[groups.count - 1].shortcuts.append(shortcut)
            } else {
                groups.append((title: title, shortcuts: [shortcut]))
            }
        }

        // Only show "Other" header if there are both categorized AND uncategorized shortcuts
        let showOtherHeader = !categorizedGroups.isEmpty && !uncategorized.isEmpty

        // Build legend views: [header, item, item, ...] for each group
        let categorizedViews: [UIView] = categorizedGroups.flatMap { group -> [UIView] in
            let header = KeyboardShortcutSectionHeaderView(title: group.title)
            let items = group.shortcuts.map { KeyboardShortcutLegendView(shortcut: $0) }
            return [header] + items
        }

        let uncategorizedViews: [UIView] = {
            guard !uncategorized.isEmpty else { return [] }
            let header: [UIView] = showOtherHeader ? [KeyboardShortcutSectionHeaderView(title: "Other")] : []
            let items = uncategorized.map { KeyboardShortcutLegendView(shortcut: $0) }
            return header + items
        }()

        legendItemViews = categorizedViews + uncategorizedViews
        legendItemViews.forEach { legendContainerView.addSubview($0) }

        setNeedsLayout()
    }

    // MARK: - UIView

    override public func layoutSubviews() {
        super.layoutSubviews()

        guard snapshotImageView.image != nil else { return }

        // Layout horizontally: snapshot | divider | legend
        var layoutRect = bounds
        snapshotImageView.frame = layoutRect.slice(snapshotImageView.bounds.width, from: .minXEdge)
        dividerView.frame = layoutRect.slice(Metrics.dividerWidth, from: .minXEdge)
        legendContainerView.frame = layoutRect

        // Layout legend items vertically with padding
        var contentRect = legendContainerView.bounds.insetBy(
            dx: Metrics.legendPadding,
            dy: Metrics.legendPadding
        )

        for itemView in legendItemViews {
            let itemHeight = itemView.sizeThatFits(
                CGSize(width: contentRect.width, height: .greatestFiniteMagnitude)
            ).height
            itemView.frame = contentRect.slice(itemHeight, from: .minYEdge)

            let spacing = (itemView is KeyboardShortcutSectionHeaderView) ? 0 : Metrics.legendItemSpacing
            contentRect.trim(spacing, from: .minYEdge)
        }
    }

    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        guard snapshotImageView.image != nil else {
            return .zero
        }

        let snapshotSize = snapshotImageView.bounds.size
        let legendWidth = calculateLegendWidth()
        let totalWidth = snapshotSize.width + Metrics.dividerWidth + legendWidth
        let availableWidth = legendWidth - (Metrics.legendPadding * 2)
        let fitSize = CGSize(width: availableWidth, height: .greatestFiniteMagnitude)

        let legendItemsHeight = legendItemViews.enumerated().reduce(CGFloat(0)) { total, pair in
            let (index, itemView) = pair
            let itemHeight = itemView.sizeThatFits(fitSize).height
            let spacing = (index < legendItemViews.count - 1 && !(itemView is KeyboardShortcutSectionHeaderView))
                ? Metrics.legendItemSpacing
                : 0
            return total + itemHeight + spacing
        }

        let legendHeight = Metrics.legendPadding * 2 + legendItemsHeight
        let totalHeight = max(snapshotSize.height, legendHeight)

        return CGSize(width: totalWidth, height: totalHeight)
    }

    private func calculateLegendWidth() -> CGFloat {
        return 250
    }
}

// MARK: - Sequence Extension

private extension Sequence {
    /// Partitions the sequence into two arrays based on a predicate.
    /// - Returns: A tuple where the first array contains elements matching the predicate,
    ///   and the second contains elements that don't match.
    func partitioned(by predicate: (Element) -> Bool) -> (matching: [Element], notMatching: [Element]) {
        reduce(into: (matching: [Element](), notMatching: [Element]())) { result, element in
            if predicate(element) {
                result.matching.append(element)
            } else {
                result.notMatching.append(element)
            }
        }
    }
}

// MARK: - CGRect Extension

private extension CGRect {
    /// Slices off and returns a portion of the rect, updating self to the remainder.
    /// Source: https://gist.github.com/khanlou/34899c5a8750a496ae7936d843b0f898
    @discardableResult
    mutating func slice(_ amount: CGFloat, from edge: CGRectEdge) -> CGRect {
        let (slice, remainder) = divided(atDistance: amount, from: edge)
        self = remainder
        return slice
    }

    /// Removes an amount from an edge without returning the removed portion.
    mutating func trim(_ amount: CGFloat, from edge: CGRectEdge) {
        self = divided(atDistance: amount, from: edge).remainder
    }
}

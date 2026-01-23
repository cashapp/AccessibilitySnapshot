//
//  Copyright 2024 Block Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

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
        let renderingMode: AccessibilitySnapshotCore.ViewRenderingMode = viewRenderingMode == .drawHierarchyInRect
            ? .drawHierarchyInRect
            : .renderLayerInContext
        let image = try containedView.renderToImage(monochrome: useMonochromeSnapshot, viewRenderingMode: renderingMode)
        snapshotImageView.image = image
        snapshotImageView.bounds.size = containedView.bounds.size
    }

    private func updateLegendViews(with shortcuts: [KeyboardShortcut]) {
        legendItemViews.forEach { $0.removeFromSuperview() }
        legendItemViews = []

        let categorizedShortcuts = shortcuts.filter { $0.menuTitle != nil }
        let uncategorizedShortcuts = shortcuts.filter { $0.menuTitle == nil }

        // Group categorized shortcuts by menu title, preserving order
        var categorizedGroups: [(title: String, shortcuts: [KeyboardShortcut])] = []
        for shortcut in categorizedShortcuts {
            if let title = shortcut.menuTitle {
                if let lastIndex = categorizedGroups.indices.last, categorizedGroups[lastIndex].title == title {
                    categorizedGroups[lastIndex].shortcuts.append(shortcut)
                } else {
                    categorizedGroups.append((title: title, shortcuts: [shortcut]))
                }
            }
        }

        // Only show "Other" header if there are both categorized AND uncategorized shortcuts
        let hasCategorizedShortcuts = !categorizedGroups.isEmpty
        let hasUncategorizedShortcuts = !uncategorizedShortcuts.isEmpty
        let showOtherHeader = hasCategorizedShortcuts && hasUncategorizedShortcuts

        for group in categorizedGroups {
            let headerView = KeyboardShortcutSectionHeaderView(title: group.title)
            legendContainerView.addSubview(headerView)
            legendItemViews.append(headerView)

            for shortcut in group.shortcuts {
                let legendView = KeyboardShortcutLegendView(shortcut: shortcut)
                legendContainerView.addSubview(legendView)
                legendItemViews.append(legendView)
            }
        }

        if hasUncategorizedShortcuts {
            if showOtherHeader {
                let headerView = KeyboardShortcutSectionHeaderView(title: "Other")
                legendContainerView.addSubview(headerView)
                legendItemViews.append(headerView)
            }

            for shortcut in uncategorizedShortcuts {
                let legendView = KeyboardShortcutLegendView(shortcut: shortcut)
                legendContainerView.addSubview(legendView)
                legendItemViews.append(legendView)
            }
        }

        setNeedsLayout()
    }

    // MARK: - UIView

    override public func layoutSubviews() {
        super.layoutSubviews()

        guard snapshotImageView.image != nil else { return }

        let legendWidth = calculateLegendWidth()
        let snapshotSize = snapshotImageView.bounds.size

        snapshotImageView.frame = CGRect(origin: .zero, size: snapshotSize)

        dividerView.frame = CGRect(
            x: snapshotSize.width,
            y: 0,
            width: Metrics.dividerWidth,
            height: bounds.height
        )

        legendContainerView.frame = CGRect(
            x: snapshotSize.width + Metrics.dividerWidth,
            y: 0,
            width: legendWidth,
            height: bounds.height
        )

        var currentY: CGFloat = Metrics.legendPadding
        let availableWidth = legendWidth - (Metrics.legendPadding * 2)

        for itemView in legendItemViews {
            let itemSize = itemView.sizeThatFits(
                CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude)
            )
            itemView.frame = CGRect(
                x: Metrics.legendPadding,
                y: currentY,
                width: availableWidth,
                height: itemSize.height
            )

            let spacing = (itemView is KeyboardShortcutSectionHeaderView) ? 0 : Metrics.legendItemSpacing
            currentY += itemSize.height + spacing
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

        var legendItemsHeight: CGFloat = 0
        for (index, itemView) in legendItemViews.enumerated() {
            let itemHeight = itemView.sizeThatFits(CGSize(width: availableWidth, height: .greatestFiniteMagnitude)).height
            legendItemsHeight += itemHeight

            if index < legendItemViews.count - 1 {
                let spacing = (itemView is KeyboardShortcutSectionHeaderView) ? 0 : Metrics.legendItemSpacing
                legendItemsHeight += spacing
            }
        }

        let legendHeight = Metrics.legendPadding * 2 + legendItemsHeight
        let totalHeight = max(snapshotSize.height, legendHeight)

        return CGSize(width: totalWidth, height: totalHeight)
    }

    private func calculateLegendWidth() -> CGFloat {
        return 250
    }
}

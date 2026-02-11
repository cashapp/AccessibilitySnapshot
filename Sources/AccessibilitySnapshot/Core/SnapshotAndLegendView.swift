import UIKit

open class SnapshotAndLegendView: UIView {
    // MARK: - Life Cycle

    override public init(frame: CGRect) {
        super.init(frame: frame)

        snapshotView.clipsToBounds = true
        addSubview(snapshotView)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Internal Properties

    public let snapshotView: UIImageView = .init()

    open var legendViews: [UIView] {
        // This is intended to be overridden and implemented by subclasses.
        return []
    }

    open var minimumLegendWidth: CGFloat {
        // This is intended to be overridden and implemented by subclasses.
        return 0
    }

    // MARK: - Private Properties

    private var minimumWidth: CGFloat {
        return minimumLegendWidth + LegendLayoutMetrics.legendInset * 2
    }

    // MARK: - UIView

    override open func layoutSubviews() {
        switch legendLocation(viewSize: snapshotView.bounds.size) {
        case let .bottom(width: availableLegendWidth):
            snapshotView.frame.origin.y = bounds.minY
            snapshotView.frame.origin.x = ((bounds.width - snapshotView.frame.width) / 2).floorToPixel(in: window)

            var nextLegendY = snapshotView.frame.maxY + LegendLayoutMetrics.legendInset
            for legendView in legendViews {
                legendView.bounds.size = legendView.sizeThatFits(
                    .init(width: availableLegendWidth, height: .greatestFiniteMagnitude)
                )
                legendView.frame.origin = .init(x: LegendLayoutMetrics.legendInset, y: nextLegendY)
                nextLegendY += legendView.frame.height + LegendLayoutMetrics.legendVerticalSpacing
            }

        case let .right(height: availableLegendHeight):
            snapshotView.frame.origin = .zero

            var nextLegendOrigin: CGPoint = .init(
                x: snapshotView.frame.maxX + LegendLayoutMetrics.legendInset,
                y: LegendLayoutMetrics.legendInset
            )

            let maxYBoundary = bounds.minY + LegendLayoutMetrics.legendInset + availableLegendHeight

            for legendView in legendViews {
                legendView.bounds.size = legendView.sizeThatFits(
                    .init(width: minimumLegendWidth, height: availableLegendHeight)
                )

                if nextLegendOrigin.y + legendView.bounds.height <= maxYBoundary {
                    legendView.frame.origin = nextLegendOrigin
                    nextLegendOrigin.y += legendView.bounds.height + LegendLayoutMetrics.legendVerticalSpacing

                } else {
                    legendView.frame.origin = .init(
                        x: nextLegendOrigin.x + minimumLegendWidth + LegendLayoutMetrics.legendHorizontalSpacing,
                        y: LegendLayoutMetrics.legendInset
                    )
                    nextLegendOrigin = .init(
                        x: legendView.frame.minX,
                        y: legendView.frame.maxY + LegendLayoutMetrics.legendVerticalSpacing
                    )
                }
            }
        }
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        guard !legendViews.isEmpty else {
            return snapshotView.bounds.size
        }

        switch legendLocation(viewSize: snapshotView.bounds.size) {
        case let .bottom(width: availableWidth):
            let legendViewSizes = legendViews.map {
                $0.sizeThatFits(.init(width: availableWidth, height: .greatestFiniteMagnitude))
            }

            let widestLegendView = legendViewSizes
                .map { $0.width }
                .reduce(0, max)

            let legendHeight = legendViewSizes
                .map { $0.height }
                .reduce(-LegendLayoutMetrics.legendVerticalSpacing) { $0 + $1 + LegendLayoutMetrics.legendVerticalSpacing }

            let width = max(
                snapshotView.frame.width,
                widestLegendView + LegendLayoutMetrics.legendInset + LegendLayoutMetrics.legendInset,
                minimumWidth
            )

            let heightComponents = [
                snapshotView.frame.height,
                LegendLayoutMetrics.legendInset,
                legendHeight,
                LegendLayoutMetrics.legendInset,
            ]

            return CGSize(
                width: width.ceilToPixel(in: window),
                height: heightComponents.reduce(0, +).ceilToPixel(in: window)
            )

        case let .right(height: availableHeight):
            let legendViewSizes = legendViews.map {
                $0.sizeThatFits(.init(width: minimumLegendWidth, height: availableHeight))
            }

            var columnHeights = [-LegendLayoutMetrics.legendVerticalSpacing]
            var lastColumnIndex = 0

            for legendViewSize in legendViewSizes {
                let lastColumnHeight = columnHeights[lastColumnIndex]
                let heightByAddingLegendView = lastColumnHeight + LegendLayoutMetrics.legendVerticalSpacing + legendViewSize.height

                if heightByAddingLegendView <= availableHeight {
                    columnHeights[lastColumnIndex] = heightByAddingLegendView

                } else {
                    columnHeights.append(legendViewSize.height)
                    lastColumnIndex += 1
                }
            }

            let widthComponents = [
                snapshotView.bounds.width,
                LegendLayoutMetrics.legendInset,
                CGFloat(columnHeights.count) * minimumLegendWidth,
                CGFloat(columnHeights.count - 1) * LegendLayoutMetrics.legendHorizontalSpacing,
                LegendLayoutMetrics.legendInset,
            ]

            let maxLegendViewHeight = legendViewSizes.reduce(0) { max($0, $1.height) }
            let height = max(
                snapshotView.bounds.height,
                maxLegendViewHeight + LegendLayoutMetrics.legendInset + LegendLayoutMetrics.legendInset
            )

            return CGSize(
                width: widthComponents.reduce(0, +),
                height: height
            )
        }
    }

    // MARK: - Private Methods

    private func legendLocation(viewSize: CGSize) -> LegendLocation {
        let aspectRatio = viewSize.width / viewSize.height

        if aspectRatio > 1 || viewSize.width < minimumWidth {
            // Wide views should display the legend underneath the snapshotted view. Small views are an exception, as
            // all views smaller than the minimum width should display the legend underneath.
            let contentWidth = max(viewSize.width, minimumWidth)
            let availableWidth = contentWidth - LegendLayoutMetrics.legendInset - LegendLayoutMetrics.legendInset
            return .bottom(width: availableWidth)

        } else {
            // Tall views that meet the minimum height requirement should display the legend to the right of the
            // snapshotted view.
            return .right(height: viewSize.height - LegendLayoutMetrics.legendInset - LegendLayoutMetrics.legendInset)
        }
    }

    // MARK: - Private Types

    private enum LegendLocation {
        case bottom(width: CGFloat)

        case right(height: CGFloat)
    }
}

// MARK: -

private extension CGFloat {
    func floorToPixel(in source: UIWindow?) -> CGFloat {
        let scale = source?.screen.scale ?? 1
        return floor(self * scale) / scale
    }

    func ceilToPixel(in source: UIWindow?) -> CGFloat {
        let scale = source?.screen.scale ?? 1
        return ceil(self * scale) / scale
    }
}

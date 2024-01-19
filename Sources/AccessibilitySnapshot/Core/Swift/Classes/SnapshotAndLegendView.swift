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

public class SnapshotAndLegendView: UIView {

    // MARK: - Life Cycle

    internal override init(frame: CGRect) {
        super.init(frame: frame)

        snapshotView.clipsToBounds = true
        addSubview(snapshotView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Internal Properties

    internal let snapshotView: UIImageView = .init()

    internal var legendViews: [UIView] {
        // This is intended to be overridden and implemented by subclasses.
        return []
    }

    internal var minimumLegendWidth: CGFloat {
        // This is intended to be overridden and implemented by subclasses.
        return 0
    }

    // MARK: - Private Properties

    private var minimumWidth: CGFloat {
        return minimumLegendWidth + Metrics.legendInsets.left + Metrics.legendInsets.right
    }

    // MARK: - UIView

    public override func layoutSubviews() {
        switch legendLocation(viewSize: snapshotView.bounds.size) {
        case let .bottom(width: availableLegendWidth):
            snapshotView.frame.origin.y = bounds.minY
            snapshotView.frame.origin.x = ((bounds.width - snapshotView.frame.width) / 2).floorToPixel(in: window)

            var nextLegendY = snapshotView.frame.maxY + Metrics.legendInsets.top
            for legendView in legendViews {
                legendView.bounds.size = legendView.sizeThatFits(
                    .init(width: availableLegendWidth, height: .greatestFiniteMagnitude)
                )
                legendView.frame.origin = .init(x: Metrics.legendInsets.left, y: nextLegendY)
                nextLegendY += legendView.frame.height + Metrics.legendVerticalSpacing
            }

        case let .right(height: availableLegendHeight):
            snapshotView.frame.origin = .zero

            var nextLegendOrigin: CGPoint = .init(
                x: snapshotView.frame.maxX + Metrics.legendInsets.left,
                y: Metrics.legendInsets.top
            )

            let maxYBoundary = bounds.minY + Metrics.legendInsets.top + availableLegendHeight

            for legendView in legendViews {
                legendView.bounds.size = legendView.sizeThatFits(
                    .init(width: minimumLegendWidth, height: availableLegendHeight)
                )

                if nextLegendOrigin.y + legendView.bounds.height <= maxYBoundary {
                    legendView.frame.origin = nextLegendOrigin
                    nextLegendOrigin.y += legendView.bounds.height + Metrics.legendVerticalSpacing

                } else {
                    legendView.frame.origin = .init(
                        x: nextLegendOrigin.x + minimumLegendWidth + Metrics.legendHorizontalSpacing,
                        y: Metrics.legendInsets.top
                    )
                    nextLegendOrigin = .init(
                        x: legendView.frame.minX,
                        y: legendView.frame.maxY + Metrics.legendVerticalSpacing
                    )
                }
            }
        }
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
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
                .reduce(-Metrics.legendVerticalSpacing, { $0 + $1 + Metrics.legendVerticalSpacing })

            let width = max(
                snapshotView.frame.width,
                widestLegendView + Metrics.legendInsets.left + Metrics.legendInsets.right,
                minimumWidth
            )

            let heightComponents = [
                snapshotView.frame.height,
                Metrics.legendInsets.top,
                legendHeight,
                Metrics.legendInsets.bottom,
            ]

            return CGSize(
                width: width.ceilToPixel(in: window),
                height: heightComponents.reduce(0, +).ceilToPixel(in: window)
            )

        case let .right(height: availableHeight):
            let legendViewSizes = legendViews.map {
                $0.sizeThatFits(.init(width: minimumLegendWidth, height: availableHeight))
            }

            var columnHeights = [-Metrics.legendVerticalSpacing]
            var lastColumnIndex = 0

            for legendViewSize in legendViewSizes {
                let lastColumnHeight = columnHeights[lastColumnIndex]
                let heightByAddingLegendView = lastColumnHeight + Metrics.legendVerticalSpacing + legendViewSize.height

                if heightByAddingLegendView <= availableHeight {
                    columnHeights[lastColumnIndex] = heightByAddingLegendView

                } else {
                    columnHeights.append(legendViewSize.height)
                    lastColumnIndex += 1
                }
            }

            let widthComponents = [
                snapshotView.bounds.width,
                Metrics.legendInsets.left,
                CGFloat(columnHeights.count) * minimumLegendWidth,
                CGFloat(columnHeights.count - 1) * Metrics.legendHorizontalSpacing,
                Metrics.legendInsets.right,
            ]

            let maxLegendViewHeight = legendViewSizes.reduce(0, { max($0, $1.height) })
            let height = max(
                snapshotView.bounds.height,
                maxLegendViewHeight + Metrics.legendInsets.top + Metrics.legendInsets.bottom
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
            let availableWidth = contentWidth - Metrics.legendInsets.left - Metrics.legendInsets.right
            return .bottom(width: availableWidth)

        } else {
            // Tall views that meet the minimum height requirement should display the legend to the right of the
            // snapshotted view.
            return .right(height: viewSize.height - Metrics.legendInsets.top - Metrics.legendInsets.bottom)
        }
    }

    // MARK: - Private Types

    private enum LegendLocation {

        case bottom(width: CGFloat)

        case right(height: CGFloat)

    }

    private enum Metrics {

        static let legendInsets: UIEdgeInsets = .init(top: 16, left: 16, bottom: 16, right: 16)

        static let legendHorizontalSpacing: CGFloat = 16

        static let legendVerticalSpacing: CGFloat = 16

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

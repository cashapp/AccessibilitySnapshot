//
//  Copyright 2019 Square Inc.
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

public enum ActivationPointDisplayMode {

    /// Always show the accessibility activation point indicators.
    case always

    /// Only show the accessibility activation point indicator for an element when the activation point is different
    /// than the default activation point for that element.
    case whenOverridden

    /// Never show the accessibility activation point indicators.
    case never

}

// MARK: -

/// A container view that displays a snapshot of a view and overlays it with accessibility markers, as well as shows a
/// legend of accessibility descriptions underneath.
///
/// The overlays and legend will be added when `parseAccessibility()` is called. In order for the coordinates to be
/// calculated properly, the view must already be in the view hierarchy.
final class AccessibilitySnapshotView: UIView {

    // MARK: - Life Cycle

    init(
        containedView: UIView,
        viewRenderingMode: ViewRenderingMode,
        markerColors: [UIColor] = defaultMarkerColors,
        activationPointDisplayMode: ActivationPointDisplayMode
    ) {
        self.containedView = containedView
        self.viewRenderingMode = viewRenderingMode
        self.markerColors = markerColors.isEmpty ? AccessibilitySnapshotView.defaultMarkerColors : markerColors
        self.activationPointDisplayMode = activationPointDisplayMode

        super.init(frame: containedView.bounds)

        snapshotView.clipsToBounds = true
        addSubview(snapshotView)

        backgroundColor = .init(white: 0.9, alpha: 1.0)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Properties

    private let containedView: UIView

    private let viewRenderingMode: ViewRenderingMode

    private let snapshotView: UIImageView = .init()

    private let markerColors: [UIColor]

    private let activationPointDisplayMode: ActivationPointDisplayMode

    private var displayMarkers: [DisplayMarker] = []

    // MARK: - Public Methods

    /// Parse the `containedView`'s accessibility and add appropriate visual elements to represent it.
    ///
    /// This must be called _after_ the view is in the view hierarchy.
    func parseAccessibility(useMonochromeSnapshot: Bool) {
        // Clean up any previous markers.
        self.displayMarkers.forEach {
            $0.legendView.removeFromSuperview()
            $0.overlayView.removeFromSuperview()
            $0.activationPointView?.removeFromSuperview()
        }

        addSubview(containedView)

        defer {
            containedView.removeFromSuperview()
        }

        // Force a layout pass after the view is in the hierarchy so that the conversion to screen coordinates works
        // correctly.
        containedView.setNeedsLayout()
        containedView.layoutIfNeeded()

        snapshotView.image = containedView.renderToImage(
            monochrome: useMonochromeSnapshot,
            viewRenderingMode: viewRenderingMode
        )
        snapshotView.bounds.size = containedView.bounds.size

        let parser = AccessibilityHierarchyParser()
        let markers = parser.parseAccessibilityElements(in: containedView)

        var displayMarkers: [DisplayMarker] = []
        for (index, marker) in markers.enumerated() {
            let color = markerColors[index % markerColors.count]

            let legendView = LegendView(marker: marker, color: color)
            addSubview(legendView)

            let overlayView = UIView()
            snapshotView.addSubview(overlayView)

            switch marker.shape {
            case let .frame(rect):
                // The `overlayView` itself is used to highlight the region.
                overlayView.backgroundColor = color.withAlphaComponent(0.3)
                overlayView.frame = rect

            case let .path(path):
                // The `overlayView` acts as a container for the highlight path. Since the `path` is already relative to
                // the `snaphotView`, the `overlayView` takes up the entire size of its parent.
                overlayView.frame = snapshotView.bounds
                let overlayLayer = CAShapeLayer()
                overlayLayer.lineWidth = 4
                overlayLayer.strokeColor = color.withAlphaComponent(0.3).cgColor
                overlayLayer.fillColor = nil
                overlayLayer.path = path.cgPath
                overlayView.layer.addSublayer(overlayLayer)
            }

            var displayMarker = DisplayMarker(
                marker: marker,
                legendView: legendView,
                overlayView: overlayView,
                activationPointView: nil
            )

            switch activationPointDisplayMode {
            case .whenOverridden:
                if !marker.usesDefaultActivationPoint {
                    fallthrough
                }

            case .always:
                let activationPointView = UIImageView(
                    image: UIImage(named: "Crosshairs", in: Bundle.accessibilitySnapshotResources, compatibleWith: nil)
                )
                activationPointView.bounds.size = .init(width: 16, height: 16)
                activationPointView.center = marker.activationPoint
                activationPointView.tintColor = color
                snapshotView.addSubview(activationPointView)
                displayMarker.activationPointView = activationPointView

            case .never:
                break // No-op.
            }

            displayMarkers.append(displayMarker)
        }
        self.displayMarkers = displayMarkers
    }

    // MARK: - UIView

    override func layoutSubviews() {
        let legendViews = displayMarkers.map { $0.legendView }

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

            let maxYBoundary = bounds.minY + availableLegendHeight

            for legendView in legendViews {
                legendView.bounds.size = legendView.sizeThatFits(
                    .init(width: LegendView.Metrics.minimumWidth, height: availableLegendHeight)
                )

                if nextLegendOrigin.y + legendView.bounds.height <= maxYBoundary {
                    legendView.frame.origin = nextLegendOrigin
                    nextLegendOrigin.y += legendView.bounds.height + Metrics.legendVerticalSpacing

                } else {
                    legendView.frame.origin = .init(
                        x: nextLegendOrigin.x + LegendView.Metrics.minimumWidth + Metrics.legendHorizontalSpacing,
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

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard !displayMarkers.isEmpty else {
            return snapshotView.bounds.size
        }

        switch legendLocation(viewSize: snapshotView.bounds.size) {
        case let .bottom(width: availableWidth):
            let legendViewSizes = displayMarkers.map {
                $0.legendView.sizeThatFits(.init(width: availableWidth, height: .greatestFiniteMagnitude))
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
                Metrics.minimumWidth
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
            let legendViewSizes = displayMarkers.map {
                $0.legendView.sizeThatFits(.init(width: LegendView.Metrics.minimumWidth, height: availableHeight))
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
                CGFloat(columnHeights.count) * LegendView.Metrics.minimumWidth,
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

        if aspectRatio > 1 || viewSize.width < Metrics.minimumWidth {
            // Wide views should display the legend underneath the snapshotted view. Small views are an exception, as
            // all views smaller than the minimum width should display the legend underneath.
            let contentWidth = max(viewSize.width, Metrics.minimumWidth)
            let availableWidth = contentWidth - Metrics.legendInsets.left - Metrics.legendInsets.right
            return .bottom(width: availableWidth)

        } else {
            // Tall views that meet the minimum height requirement should display the legend to the right of the
            // snapshotted view.
            return .right(height: viewSize.height - Metrics.legendInsets.top - Metrics.legendInsets.bottom)
        }
    }

    // MARK: - Private Static Properties

    private static let defaultMarkerColors: [UIColor] = [ .cyan, .magenta, .green, .blue, .yellow, .purple, .orange ]

    // MARK: - Private Types

    private struct DisplayMarker {

        var marker: AccessibilityMarker

        var legendView: LegendView

        var overlayView: UIView

        var activationPointView: UIView?

    }

    private enum LegendLocation {

        case bottom(width: CGFloat)

        case right(height: CGFloat)

    }

    private enum Metrics {

        static var minimumWidth: CGFloat {
            return LegendView.Metrics.minimumWidth + legendInsets.left + legendInsets.right
        }

        static let legendInsets: UIEdgeInsets = .init(top: 16, left: 16, bottom: 16, right: 16)

        static let legendHorizontalSpacing: CGFloat = 16

        static let legendVerticalSpacing: CGFloat = 16

    }

}

// MARK: -

extension AccessibilitySnapshotView {

    enum ViewRenderingMode {

        case renderLayerInContext

        case drawHierarchyInRect

    }

}

// MARK: -

private extension AccessibilitySnapshotView {

    final class LegendView: UIView {

        // MARK: - Life Cycle

        init(marker: AccessibilityMarker, color: UIColor) {
            self.hintLabel = marker.hint.map {
                let label = UILabel()
                label.text = $0
                label.font = Metrics.hintLabelFont
                label.textColor = .init(white: 0.3, alpha: 1.0)
                label.numberOfLines = 0
                return label
            }

            super.init(frame: .zero)

            markerView.backgroundColor = color.withAlphaComponent(0.3)
            addSubview(markerView)

            descriptionLabel.text = marker.description
            descriptionLabel.font = Metrics.descriptionLabelFont
            descriptionLabel.numberOfLines = 0
            addSubview(descriptionLabel)

            hintLabel.map(addSubview)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let markerView: UIView = .init()

        private let descriptionLabel: UILabel = .init()

        private let hintLabel: UILabel?

        // MARK: - UIView

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            let labelSizeToFit = CGSize(
                width: size.width - Metrics.markerSize - Metrics.markerToLabelSpacing,
                height: .greatestFiniteMagnitude
            )

            descriptionLabel.numberOfLines = 1
            let descriptionLabelSingleLineHeight = descriptionLabel.sizeThatFits(labelSizeToFit).height
            let markerSizeAboveDescriptionLabel = (Metrics.markerSize - descriptionLabelSingleLineHeight) / 2

            descriptionLabel.numberOfLines = 0
            let descriptionLabelSize = descriptionLabel.sizeThatFits(labelSizeToFit)

            let hintLabelSize = hintLabel?.sizeThatFits(labelSizeToFit) ?? .zero

            let widthComponents = [
                Metrics.markerSize,
                Metrics.markerToLabelSpacing,
                max(
                    descriptionLabelSize.width,
                    hintLabelSize.width
                ),
            ]

            let heightComponents = [
                markerSizeAboveDescriptionLabel,
                descriptionLabelSize.height,
                (hintLabelSize.height == 0 ? 0 : hintLabelSize.height + Metrics.descriptionLabelToHintLabelSpacing),
            ]

            return CGSize(
                width: widthComponents.reduce(0, +),
                height: max(
                    Metrics.markerSize,
                    heightComponents.reduce(0, +)
                )
            )
        }

        override func layoutSubviews() {
            markerView.frame = CGRect(x: 0, y: 0, width: Metrics.markerSize, height: Metrics.markerSize)

            let labelSizeToFit = CGSize(
                width: bounds.size.width - Metrics.markerSize - Metrics.markerToLabelSpacing,
                height: .greatestFiniteMagnitude
            )

            descriptionLabel.numberOfLines = 1
            let descriptionLabelSingleLineHeight = descriptionLabel.sizeThatFits(labelSizeToFit).height

            descriptionLabel.numberOfLines = 0
            let descriptionLabelSizeThatFits = descriptionLabel.sizeThatFits(labelSizeToFit)

            descriptionLabel.frame = .init(
                x: markerView.frame.maxX + Metrics.markerToLabelSpacing,
                y: markerView.frame.minY + (markerView.frame.height - descriptionLabelSingleLineHeight) / 2,
                width: descriptionLabelSizeThatFits.width,
                height: descriptionLabelSizeThatFits.height
            )

            if let hintLabel = hintLabel {
                hintLabel.bounds.size = hintLabel.sizeThatFits(labelSizeToFit)
                hintLabel.frame.origin = .init(
                    x: descriptionLabel.frame.minX,
                    y: descriptionLabel.frame.maxY + Metrics.descriptionLabelToHintLabelSpacing
                )
            }
        }

        // MARK: - Private

        fileprivate enum Metrics {

            static let minimumWidth: CGFloat = 284

            static let markerSize: CGFloat = 14
            static let markerToLabelSpacing: CGFloat = 16
            static let descriptionLabelToHintLabelSpacing: CGFloat = 4

            static let descriptionLabelFont = UIFont.systemFont(ofSize: 12)
            static let hintLabelFont = UIFont.italicSystemFont(ofSize: 12)

        }

    }

}

// MARK: -

private extension UIView {

    func renderToImage(monochrome: Bool, viewRenderingMode: AccessibilitySnapshotView.ViewRenderingMode) -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        let snapshot = renderer.image { context in
            switch viewRenderingMode {
            case .drawHierarchyInRect:
                drawHierarchy(in: bounds, afterScreenUpdates: true)

            case .renderLayerInContext:
                layer.render(in: context.cgContext)
            }
        }

        if monochrome, let cgImage = snapshot.cgImage {
            let monochromeSnapshot = CIImage(cgImage: cgImage).applyingFilter(
                "CIColorControls",
                parameters: [kCIInputSaturationKey: 0]
            )

            return UIImage(ciImage: monochromeSnapshot, scale: snapshot.scale, orientation: .up)

        } else {
            return snapshot
        }
    }

}

// MARK: -

private extension Bundle {

    private final class Sentinel {}

    static var accessibilitySnapshotResources: Bundle = {
        let container = Bundle(for: Sentinel.self)
        let resources = container.url(forResource: "AccessibilitySnapshot", withExtension: "bundle")!
        return Bundle(url: resources)!
    }()

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

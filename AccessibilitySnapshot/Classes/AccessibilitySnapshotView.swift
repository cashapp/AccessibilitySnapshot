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
        self.markerColors = markerColors
        self.activationPointDisplayMode = activationPointDisplayMode

        super.init(frame: containedView.bounds)

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
            addSubview(overlayView)

            switch marker.shape {
            case .frame:
                overlayView.backgroundColor = color.withAlphaComponent(0.3)

            case let .path(path):
                overlayView.frame = path.bounds
                let overlayLayer = CAShapeLayer()
                overlayLayer.lineWidth = 4
                overlayLayer.strokeColor = color.withAlphaComponent(0.3).cgColor
                overlayLayer.fillColor = nil
                overlayLayer.path = overlayView.convert(path, from: containedView).cgPath
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
                let activationPointView = UIImageView(image: UIImage(named: "Crosshairs", in: Bundle.accessibilitySnapshotResources, compatibleWith: nil))
                activationPointView.frame.size = .init(width: 16, height: 16)
                activationPointView.tintColor = color
                addSubview(activationPointView)
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
        snapshotView.frame.origin.y = bounds.minY
        snapshotView.frame.origin.x = ((bounds.width - snapshotView.frame.width) / 2).floorToPixel(in: window)

        let legendViews = displayMarkers.map { $0.legendView }

        var nextLegendY = snapshotView.frame.maxY + Metrics.verticalSpacing
        for legendView in legendViews {
            legendView.sizeToFit()
            legendView.frame.origin = .init(x: 0, y: nextLegendY)
            nextLegendY += legendView.frame.height + Metrics.verticalSpacing
        }

        displayMarkers.forEach {
            let marker = $0.marker

            let overlayView = $0.overlayView
            switch marker.shape {
            case let .frame(rect):
                overlayView.frame = convert(rect, from: snapshotView)

            case let .path(path):
                overlayView.frame = convert(path.bounds, from: snapshotView)
            }

            $0.activationPointView?.center = convert(marker.activationPoint, from: snapshotView)
        }
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let legendViewSizes = displayMarkers.map { $0.legendView.sizeThatFits(size) }

        let widestLegendView = legendViewSizes.map { $0.width }.reduce(0, max)
        let legendHeight = legendViewSizes.map { $0.height }.reduce(0, { $0 + $1 + Metrics.verticalSpacing })

        let width = max(snapshotView.frame.width, widestLegendView, Metrics.minimumWidth)

        let height = snapshotView.frame.height +
                     legendHeight +
                     (displayMarkers.isEmpty ? 0 : Metrics.bottomMargin)

        return CGSize(
            width: width.ceilToPixel(in: window),
            height: height.ceilToPixel(in: window)
        )
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

    private enum Metrics {
        static let minimumWidth: CGFloat = 300

        static let verticalSpacing: CGFloat = 16
        static let bottomMargin: CGFloat = 8
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
            hintLabel = marker.hint.map {
                let label = UILabel()
                label.text = $0
                label.font = Metrics.hintLabelFont
                label.textColor = .init(white: 0.3, alpha: 1.0)
                return label
            }

            super.init(frame: .zero)

            markerView.backgroundColor = color.withAlphaComponent(0.3)
            addSubview(markerView)

            descriptionLabel.text = marker.description
            descriptionLabel.font = Metrics.descriptionLabelFont
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
            let descriptionLabelSize = descriptionLabel.sizeThatFits(size)
            let hintLabelSize = hintLabel?.sizeThatFits(size) ?? .zero

            let width = 2 * Metrics.horizontalInset +
                        Metrics.markerSize +
                        Metrics.markerToLabelSpacing +
                        max(descriptionLabelSize.width, hintLabelSize.width)

            let height = Metrics.markerSize +
                         (hintLabelSize.height == 0 ? 0 : hintLabelSize.height + Metrics.descriptionLabelToHintLabelSpacing)

            return CGSize(width: width, height: height)
        }

        override func layoutSubviews() {
            markerView.frame = CGRect(x: Metrics.horizontalInset, y: 0, width: Metrics.markerSize, height: Metrics.markerSize)

            descriptionLabel.sizeToFit()
            descriptionLabel.frame.origin = .init(
                x: markerView.frame.maxX + Metrics.markerToLabelSpacing,
                y: markerView.frame.minY + (markerView.frame.height - descriptionLabel.frame.height) / 2
            )

            if let hintLabel = hintLabel {
                hintLabel.sizeToFit()
                hintLabel.frame.origin = .init(
                    x: descriptionLabel.frame.minX,
                    y: descriptionLabel.frame.maxY + Metrics.descriptionLabelToHintLabelSpacing
                )
            }
        }

        // MARK: - Private

        private enum Metrics {
            static let horizontalInset: CGFloat = 16
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

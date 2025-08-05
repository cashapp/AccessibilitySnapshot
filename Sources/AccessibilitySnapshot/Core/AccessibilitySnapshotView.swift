//
//  Copyright 2023 Block Inc.
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
#if SWIFT_PACKAGE
import AccessibilitySnapshotParser
#endif

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
public final class AccessibilitySnapshotView: SnapshotAndLegendView {

    // MARK: - Life Cycle

    /// Initializes a new snapshot container view.
    ///
    /// - parameter containedView: The view that should be snapshotted, and for which the accessibility markers should
    /// be generated.
    /// - parameter viewRenderingMode: The method to use when snapshotting the `containedView`.
    /// - parameter markerColors: An array of colors to use for the highlighted regions. These colors will be used in
    /// order, repeating through the array as necessary.
    /// - parameter activationPointDisplayMode: Controls when to show indicators for elements' accessibility activation
    /// points.
    /// - parameter showUserInputLabels: Controls when to show elements' accessibility user input labels (used by Voice Control).
    public init(
        containedView: UIView,
        viewRenderingMode: ViewRenderingMode,
        markerColors: [UIColor] = MarkerColors.defaultColors,
        activationPointDisplayMode: ActivationPointDisplayMode,
        showUserInputLabels: Bool
    ) {
        self.containedView = containedView
        self.viewRenderingMode = viewRenderingMode
        self.markerColors = markerColors.isEmpty ? MarkerColors.defaultColors : markerColors
        self.activationPointDisplayMode = activationPointDisplayMode
        self.showUserInputLabels = showUserInputLabels

        super.init(frame: containedView.bounds)

        backgroundColor = .init(white: 0.9, alpha: 1.0)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - SnapshotAndLegendView

    override var legendViews: [UIView] {
        return displayMarkers.map { $0.legendView }
    }

    override var minimumLegendWidth: CGFloat {
        return LegendView.Metrics.minimumWidth
    }

    // MARK: - Private Properties

    private let containedView: UIView

    private let viewRenderingMode: ViewRenderingMode

    private let markerColors: [UIColor]

    private let activationPointDisplayMode: ActivationPointDisplayMode

    private let showUserInputLabels: Bool

    private var displayMarkers: [DisplayMarker] = []

    // MARK: - Public Methods

    /// Parse the `containedView`'s accessibility and add appropriate visual elements to represent it.
    ///
    /// This must be called _after_ the view is in the view hierarchy.
    ///
    /// - Throws: Throws a `RenderError` when the view fails to render a snapshot of the `containedView`.
    public func parseAccessibility(useMonochromeSnapshot: Bool) throws {
        // Clean up any previous markers.
        self.displayMarkers.forEach {
            $0.legendView.removeFromSuperview()
            $0.overlayView.removeFromSuperview()
            $0.activationPointView?.removeFromSuperview()
        }

        let viewController = containedView.next as? UIViewController
        let originalParent = viewController?.parent
        let originalSuperviewAndIndex = containedView.superviewWithSubviewIndex()

        viewController?.removeFromParent()
        addSubview(containedView)

        defer {
            containedView.removeFromSuperview()

            if let (originalSuperview, originalSubviewIndex) = originalSuperviewAndIndex {
                originalSuperview.insertSubview(containedView, at: originalSubviewIndex)
            }

            if let viewController = viewController, let originalParent = originalParent {
                originalParent.addChild(viewController)
            }
        }

        // Force a layout pass after the view is in the hierarchy so that the conversion to screen coordinates works
        // correctly.
        containedView.setNeedsLayout()
        containedView.layoutIfNeeded()

        snapshotView.image = try containedView.renderToImage(
            monochrome: useMonochromeSnapshot,
            viewRenderingMode: viewRenderingMode
        )
        snapshotView.bounds.size = containedView.bounds.size

        // Complete the layout pass after the view is restored to this container, in case it was modified during the
        // rendering process (i.e. when the rendering is tiled and stitched).
        containedView.layoutIfNeeded()

        let parser = AccessibilityHierarchyParser()
        let markers = parser.parseAccessibilityElements(in: containedView)

        var displayMarkers: [DisplayMarker] = []
        for (index, marker) in markers.enumerated() {
            let color = markerColors[index % markerColors.count]

            let legendView = LegendView(marker: marker, color: color, showUserInputLabels: showUserInputLabels)
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
                guard containedView.bounds.contains(marker.activationPoint) else {
                    break
                }

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

    // MARK: - Private Types

    private struct DisplayMarker {

        var marker: AccessibilityMarker

        var legendView: LegendView

        var overlayView: UIView

        var activationPointView: UIView?

    }

}

private extension UIView {

    func superviewWithSubviewIndex() -> (UIView, Int)? {
        guard let superview = superview else {
            return nil
        }

        guard let index = superview.subviews.firstIndex(of: self) else {
            fatalError("Internal inconsistency error: view has a superview, but is not a subview of the superview")
        }

        return (superview, index)
    }

}
